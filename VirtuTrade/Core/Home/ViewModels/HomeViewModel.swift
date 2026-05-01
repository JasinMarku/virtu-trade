//
//  HomeViewModel.swift
//  VirtuTrade
//
//  Created by Jasin ‎ on 10/17/24.
//

import Foundation
import Combine

struct AccountSnapshot: Identifiable, Codable, Equatable {
    let timestamp: Date
    // Keeps the persisted key stable while storing the full simulated account value: holdings + cash.
    let totalPortfolioValue: Double
    // Legacy snapshots from older builds may not include this flag.
    // New snapshots are only recorded once holdings and prices are hydrated.
    let isHydrated: Bool?
    // Version 2 snapshots are gated by mapped portfolio holdings, not just raw market data.
    let schemaVersion: Int?

    var id: String {
        "\(timestamp.timeIntervalSince1970)-\(totalPortfolioValue)"
    }
}

private enum AccountSnapshotStore {
    private static let snapshotsKey = "vt_account_snapshots"
    private static let maxSnapshotCount = 2_000

    static func load(defaults: UserDefaults = .standard) -> [AccountSnapshot] {
        guard let data = defaults.data(forKey: snapshotsKey) else {
            return []
        }

        guard let decoded = try? JSONDecoder().decode([AccountSnapshot].self, from: data) else {
            return []
        }

        return decoded.sorted { $0.timestamp < $1.timestamp }
    }

    static func save(_ snapshots: [AccountSnapshot], defaults: UserDefaults = .standard) {
        let trimmedSnapshots = Array(snapshots.suffix(maxSnapshotCount))
        guard let data = try? JSONEncoder().encode(trimmedSnapshots) else { return }
        defaults.set(data, forKey: snapshotsKey)
    }
}

@MainActor
final class HomeViewModel: ObservableObject {
    struct AccountValueSummary {
        let cashBalance: Double
        let holdingsValue: Double
        let totalValue: Double
        let isTrusted: Bool
    }

    struct TradeExecutionResult {
        let updatedCashBalance: Double
        let updatedHoldings: Double
        let totalValue: Double
        let executionPrice: Double
    }

    enum TradeExecutionError: LocalizedError {
        case invalidQuantity
        case invalidPrice
        case insufficientCash
        case noHoldings
        case insufficientHoldings

        var userMessage: String {
            switch self {
            case .invalidQuantity:
                return "Enter a valid quantity."
            case .invalidPrice:
                return "Price is unavailable right now."
            case .insufficientCash:
                return "Insufficient cash for this buy."
            case .noHoldings:
                return "No holdings available to sell."
            case .insufficientHoldings:
                return "Insufficient holdings for this sell."
            }
        }

        var errorDescription: String? {
            userMessage
        }
    }

    private enum SimulationDefaults {
        static let cashBalanceKey = "vt_sim_cash_balance"
        static let startingCashBalance: Double = 100_000
    }

    private enum AccountSnapshotSchema {
        static let trustedVersion = 2
    }

    private let minimumValidPerformanceBaseline: Double = 0.01
    private let holdingEpsilon: Double = 0.00000001
    private let tradeComparisonEpsilon: Double = 0.000000001

    @Published var statistics: [StatisticModel] = []      // Stores key statistics (like market cap, volume) for display
    @Published var allCoins: [CoinModel] = []             // List of all available coins from the API
    @Published var allCoinsUnfiltered: [CoinModel] = []   // Source coin list before search filtering
    @Published var portfolioCoins: [CoinModel] = []       // List of coins in the user's portfolio
    @Published var isLoading: Bool = false                // Flag for loading state during data fetch
    @Published var searchText: String = ""                // Holds text entered by the user for coin search
    @Published var sortOption: SortOption = .holdings
    @Published private(set) var accountSnapshots: [AccountSnapshot]

    private let coinDataService = CoinDataService()       // Service to fetch all coin data
    private let marketDataService = MarketDataService()   // Service to fetch market data
    private let portfolioDataService = PortfolioDataService() // Service for managing the portfolio's data storage
    private var cancellables = Set<AnyCancellable>()      // Holds cancellable objects for Combine subscriptions

    enum SortOption {
        case rank, rankReversed, holdings, holdingsReversed, price, priceReversed
    }

    init() {
        accountSnapshots = AccountSnapshotStore.load()
        addSubscribers()
        appendAccountSnapshotIfNeeded(force: true)
    }

    private func addSubscribers() {
        coinDataService.$allCoins
            .sink { [weak self] coins in
                self?.allCoinsUnfiltered = coins
            }
            .store(in: &cancellables)

        // Updates allCoins based on search text and API data
        $searchText
            .combineLatest(coinDataService.$allCoins, $sortOption)     // Combines searchText with allCoins from the API
            .debounce(for: .seconds(0.5), scheduler: DispatchQueue.main) // Adds delay to avoid frequent updates
            .map(filterAndSortCoins)
            .sink { [weak self] (returnedCoins) in
                self?.allCoins = returnedCoins            // Updates allCoins with filtered result
            }
            .store(in: &cancellables)

        // Updates portfolio coins list with relevant coin data from allCoins and portfolio entities
        $allCoins
            .combineLatest(portfolioDataService.$savedEntities) // Combines allCoins with saved portfolio entities
            .map(mapAllCoinsToPortfolioCoins)            // Maps allCoins to portfolio coins
            .sink { [weak self] returnedCoins in
                guard let self = self else { return }
                self.portfolioCoins = self.sortPortfolioCoinsIfNeeded(coins: returnedCoins) // Updates portfolioCoins with filtered coins in the portfolio
            }
            .store(in: &cancellables)

        // Seed account snapshots only after the persisted portfolio has loaded and,
        // when needed, saved holdings have been mapped into priced portfolio coins.
        portfolioDataService.$savedEntities
            .combineLatest($portfolioCoins, portfolioDataService.$hasLoadedInitialPortfolio)
            .sink { [weak self] savedEntities, portfolioCoins, hasLoadedInitialPortfolio in
                guard let self else { return }
                let accountValue = self.trustedAccountValueSummary(
                    savedEntities: savedEntities,
                    portfolioCoins: portfolioCoins,
                    hasLoadedInitialPortfolio: hasLoadedInitialPortfolio
                )
                self.appendAccountSnapshotIfNeeded(accountValue: accountValue)
            }
            .store(in: &cancellables)

        // Updates global market data and portfolio statistics
        marketDataService.$marketData
            .combineLatest($portfolioCoins)              // Combines market data with portfolio coins
            .map(mapGlobalMarketData)                    // Maps to a list of global statistics
            .sink { [weak self] (returnedStats) in
                self?.statistics = returnedStats         // Updates statistics with global market data
                self?.isLoading = false                  // Ends loading once data is received
                self?.appendAccountSnapshotIfNeeded()
            }
            .store(in: &cancellables)
    }

    func updatePortfolio(coin: CoinModel, amount: Double) {
        // Updates portfolio with the new coin amount, then saves the data
        portfolioDataService.updatePortfolio(coin: coin, amount: amount)
    }

    func tradeValidationMessage(coin: CoinModel, type: TradeType, quantity: Double) -> String? {
        validationError(coin: coin, type: type, quantity: quantity)?.userMessage
    }

    func availableHoldings(for coinID: String) -> Double {
        currentHoldings(for: coinID)
    }

    @discardableResult
    func executeTrade(
        coin: CoinModel,
        type: TradeType,
        quantity: Double,
        tradeHistoryStore: TradeHistoryStore
    ) -> Result<TradeExecutionResult, TradeExecutionError> {
        if let validationError = validationError(coin: coin, type: type, quantity: quantity) {
            return .failure(validationError)
        }

        let executionPrice = coin.currentPrice
        let totalValue = quantity * executionPrice

        let updatedHoldings: Double
        let updatedCashBalance: Double

        switch type {
        case .buy:
            updatedHoldings = availableHoldings(for: coin.id) + quantity
            updatedCashBalance = max(cashBalance - totalValue, 0)
        case .sell:
            updatedHoldings = max(availableHoldings(for: coin.id) - quantity, 0)
            updatedCashBalance = cashBalance + totalValue
        }

        let normalizedHoldings = abs(updatedHoldings) < holdingEpsilon ? 0 : updatedHoldings
        cashBalance = updatedCashBalance
        updatePortfolio(coin: coin, amount: normalizedHoldings)

        let trade = TradeModel(
            id: UUID(),
            coinID: coin.id,
            symbol: coin.symbol.uppercased(),
            name: coin.name,
            type: type,
            quantity: quantity,
            priceAtExecution: executionPrice,
            totalValue: totalValue,
            timestamp: Date()
        )
        tradeHistoryStore.addTrade(trade: trade)
        appendAccountSnapshotIfNeeded()

        return .success(
            TradeExecutionResult(
                updatedCashBalance: updatedCashBalance,
                updatedHoldings: normalizedHoldings,
                totalValue: totalValue,
                executionPrice: executionPrice
            )
        )
    }

    var accountValueSummary: AccountValueSummary {
        trustedAccountValueSummary()
    }

    var lastTrustedAccountValueForDisplay: Double? {
        accountSnapshots.last(where: isTrustedSnapshot)?.totalPortfolioValue
    }

    func allTimeAccountChangeSummary(startingBalance: Double) -> (value: Double, percentage: Double) {
        let accountValue = accountValueSummary
        guard accountValue.isTrusted,
              accountValue.totalValue.isFinite,
              accountValue.totalValue >= 0,
              startingBalance > minimumValidPerformanceBaseline else {
            return (0, 0)
        }

        let changeValue = accountValue.totalValue - startingBalance
        let rawPercentage = (changeValue / startingBalance) * 100
        let changePercentage = rawPercentage.isFinite ? rawPercentage : 0

        return (changeValue, changePercentage)
    }

    func resetPortfolio() {
        portfolioDataService.removeAllPortfolio()
    }

    func clearPortfolioStateImmediately(resetAccountSnapshots: Bool = false) {
        portfolioCoins = []
        searchText = ""

        if resetAccountSnapshots {
            accountSnapshots = []
            AccountSnapshotStore.save(accountSnapshots)
        }

        appendAccountSnapshotIfNeeded(force: true)
    }

    func todayAccountChangeSummary(
        asOf date: Date = Date(),
        calendar: Calendar = .autoupdatingCurrent
    ) -> (value: Double, percentage: Double) {
        let accountValue = accountValueSummary
        guard accountValue.isTrusted,
              accountValue.totalValue.isFinite,
              accountValue.totalValue >= 0 else {
            return (0, 0)
        }

        guard let baselineValue = todayBaselineAccountValue(asOf: date, calendar: calendar) else {
            return (0, 0)
        }

        let changeValue = accountValue.totalValue - baselineValue
        let changePercentage: Double
        if baselineValue > minimumValidPerformanceBaseline {
            let rawPercentage = (changeValue / baselineValue) * 100
            changePercentage = rawPercentage.isFinite ? rawPercentage : 0
        } else {
            changePercentage = 0
        }

        return (changeValue, changePercentage)
    }

    func reloadData() {
        // Triggers data reload from API services
        isLoading = true                                 // Sets loading state to true during fetch
        coinDataService.getCoins()                       // Fetches updated coin data
        marketDataService.getData()                      // Fetches updated market data
    }

    private func filterAndSortCoins(text: String, coins: [CoinModel], sort: SortOption) -> [CoinModel] {
        var updatedCoins = filterCoins(text: text, coins: coins)
        sortCoins(sort: sort, coins: &updatedCoins)
        return updatedCoins
    }

    // Filters the list of all coins based on search text
    private func filterCoins(text: String, coins: [CoinModel]) -> [CoinModel] {
        guard !text.isEmpty else {
            return coins                                 // Returns all coins if search text is empty
        }
        let lowercaseText = text.lowercased()            // Converts search text to lowercase
        return coins.filter { (coin) -> Bool in          // Filters coins by name, symbol, or ID
            return coin.name.lowercased().contains(lowercaseText) ||
            coin.symbol.lowercased().contains(lowercaseText) ||
            coin.id.lowercased().contains(lowercaseText)
        }
    }

    private func sortCoins(sort: SortOption, coins: inout [CoinModel]) {
        switch sort {
        case .rank, .holdings:
            coins.sort(by: { $0.rank < $1.rank })
        case .rankReversed, .holdingsReversed:
            coins.sort(by: { $0.rank > $1.rank })
        case .price:
            coins.sort(by: { $0.currentPrice < $1.currentPrice })
        case .priceReversed:
            coins.sort(by: { $0.currentPrice > $1.currentPrice })
        }
    }

    private func sortPortfolioCoinsIfNeeded(coins: [CoinModel]) -> [CoinModel] {
        // will only sort by holdings or reversedHoldings if needed
        switch sortOption {
        case .holdings:
            return coins.sorted(by: { $0.currentHoldingsValue > $1.currentHoldingsValue })
        case .holdingsReversed:
            return coins.sorted(by: { $0.currentHoldingsValue < $1.currentHoldingsValue })
        default:
            return coins
        }
    }

    // Maps all coins to those held in the portfolio, updating their holdings
    private func mapAllCoinsToPortfolioCoins(allCoins: [CoinModel], portfolioEntities: [PortfolioEntity]) -> [CoinModel] {
        allCoins
            .compactMap { (coin) -> CoinModel? in
                guard let entity = portfolioEntities.first(where: { $0.coinID == coin.id }) else {
                    return nil                            // Returns nil if coin isn't in portfolio
                }
                return coin.updateHoldings(amount: entity.amount) // Updates coin with its portfolio holdings
            }
    }

    // Maps global market data and portfolio statistics into a list of StatisticModels
    private func mapGlobalMarketData(marketDataModel: MarketDataModel?, portfolioCoins: [CoinModel]) -> [StatisticModel] {
        var stats: [StatisticModel] = []

        guard let data = marketDataModel else {
            return stats                                 // Returns empty stats if market data is unavailable
        }

        // Creates key market statistics for display
        let marketCap = StatisticModel(title: "Market Cap", value: data.marketCap, percentageChange: data.marketCapChangePercentage24HUsd)
        let volume = StatisticModel(title: "24h Volume", value: data.volume)
        let btcDominance = StatisticModel(title: "BTC Dominance", value: data.btcDominance)
        let marketCap24H = StatisticModel(
            title: "Market Cap 24h",
            value: data.marketCapChangePercentage24HUsd.asPercentString(),
            percentageChange: data.marketCapChangePercentage24HUsd
        )
        let markets = StatisticModel(title: "Markets", value: data.marketsString)

        // Calculates the portfolio's total current value
        let portfolioValue =
            portfolioCoins
            .map({ $0.currentHoldingsValue })            // Sums the value of each coin in the portfolio
            .reduce(0, +)

        // Calculates the portfolio's total value 24 hours ago
        let previousValue =
            portfolioCoins
            .map { (coin) -> Double in
                let currentValue = coin.currentHoldingsValue
                let percentChange = (coin.priceChangePercentage24H ?? 0) / 100
                guard (1 + percentChange) != 0 else {
                    return currentValue
                }
                let previousValue = currentValue / (1 + percentChange)

                return previousValue                     // Approximate value of each coin 24 hours ago
            }
            .reduce(0, +)

        // Calculates 24-hour percentage change in portfolio value
        let percentageChange: Double
        if previousValue > 0 {
            percentageChange = ((portfolioValue - previousValue) / previousValue) * 100
        } else {
            percentageChange = 0
        }

        // Creates portfolio statistic
        let portfolio = StatisticModel(
            title: "Portfolio Value",
            value: portfolioValue.asCurrencyWith2Decimals(),
            percentageChange: percentageChange)

        // Adds market and portfolio statistics to the stats array
        stats.append(contentsOf: [marketCap, volume, btcDominance, marketCap24H])
        if !data.marketsString.isEmpty {
            stats.append(markets)
        }
        stats.append(portfolio)
        return stats
    }

    private var cashBalance: Double {
        get {
            let defaults = UserDefaults.standard
            if defaults.object(forKey: SimulationDefaults.cashBalanceKey) == nil {
                return SimulationDefaults.startingCashBalance
            }
            return defaults.double(forKey: SimulationDefaults.cashBalanceKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: SimulationDefaults.cashBalanceKey)
        }
    }

    private func currentHoldings(for coinID: String) -> Double {
        let holdings = portfolioCoins.first(where: { $0.id == coinID })?.currentHoldings ?? 0
        guard holdings.isFinite, holdings >= 0 else { return 0 }
        return holdings
    }

    private func validationError(coin: CoinModel, type: TradeType, quantity: Double) -> TradeExecutionError? {
        guard quantity.isFinite, quantity > 0 else {
            return .invalidQuantity
        }

        let executionPrice = coin.currentPrice
        guard executionPrice.isFinite, executionPrice > 0 else {
            return .invalidPrice
        }

        let totalValue = quantity * executionPrice
        guard totalValue.isFinite, totalValue > 0 else {
            return .invalidQuantity
        }

        switch type {
        case .buy:
            guard cashBalance + tradeComparisonEpsilon >= totalValue else {
                return .insufficientCash
            }
        case .sell:
            let holdings = availableHoldings(for: coin.id)
            guard holdings > tradeComparisonEpsilon else {
                return .noHoldings
            }
            guard (quantity - holdings) <= tradeComparisonEpsilon else {
                return .insufficientHoldings
            }
        }

        return nil
    }

    private var savedPortfolioHoldings: [(coinID: String, amount: Double)] {
        savedPortfolioHoldings(from: portfolioDataService.savedEntities)
    }

    private func savedPortfolioHoldings(from savedEntities: [PortfolioEntity]) -> [(coinID: String, amount: Double)] {
        savedEntities.compactMap { entity in
            guard let coinID = entity.coinID?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !coinID.isEmpty else {
                return nil
            }

            let amount = entity.amount
            guard amount.isFinite, amount > holdingEpsilon else {
                return nil
            }

            return (coinID, amount)
        }
    }

    private func trustedAccountValueSummary() -> AccountValueSummary {
        trustedAccountValueSummary(
            savedEntities: portfolioDataService.savedEntities,
            portfolioCoins: portfolioCoins,
            hasLoadedInitialPortfolio: portfolioDataService.hasLoadedInitialPortfolio
        )
    }

    private func trustedAccountValueSummary(
        savedEntities: [PortfolioEntity],
        portfolioCoins: [CoinModel],
        hasLoadedInitialPortfolio: Bool
    ) -> AccountValueSummary {
        let cash = cashBalance
        guard cash.isFinite, cash >= 0 else {
            return AccountValueSummary(cashBalance: 0, holdingsValue: 0, totalValue: 0, isTrusted: false)
        }

        guard hasLoadedInitialPortfolio else {
            return AccountValueSummary(cashBalance: cash, holdingsValue: 0, totalValue: cash, isTrusted: false)
        }

        let savedHoldings = savedPortfolioHoldings(from: savedEntities)
        guard !savedHoldings.isEmpty else {
            return AccountValueSummary(cashBalance: cash, holdingsValue: 0, totalValue: cash, isTrusted: true)
        }

        var holdingsValue: Double = 0
        for holding in savedHoldings {
            guard let coin = portfolioCoins.first(where: { $0.id == holding.coinID }),
                  let mappedHoldings = coin.currentHoldings,
                  mappedHoldings.isFinite,
                  abs(mappedHoldings - holding.amount) <= max(holdingEpsilon, holding.amount * 0.000000001),
                  coin.currentPrice.isFinite,
                  coin.currentPrice > 0 else {
                return AccountValueSummary(cashBalance: cash, holdingsValue: 0, totalValue: cash, isTrusted: false)
            }

            let value = holding.amount * coin.currentPrice
            guard value.isFinite, value >= 0 else {
                return AccountValueSummary(cashBalance: cash, holdingsValue: 0, totalValue: cash, isTrusted: false)
            }

            holdingsValue += value
        }

        return AccountValueSummary(cashBalance: cash, holdingsValue: holdingsValue, totalValue: cash + holdingsValue, isTrusted: true)
    }

    private func todayBaselineAccountValue(
        asOf date: Date,
        calendar: Calendar
    ) -> Double? {
        let startOfDay = calendar.startOfDay(for: date)

        if let midnightBaseline = lastTrustedAccountSnapshot(where: { $0.timestamp <= startOfDay })
            ?? lastClearlyValidLegacyAccountSnapshot(where: { $0.timestamp <= startOfDay }) {
            return midnightBaseline.totalPortfolioValue
        }

        // Same-day fallback only uses snapshots captured by the stricter account-value gate.
        if let firstSnapshotToday = firstTrustedAccountSnapshot(where: { $0.timestamp >= startOfDay && $0.timestamp <= date }) {
            return firstSnapshotToday.totalPortfolioValue
        }

        return nil
    }

    private func isValidPerformanceBaseline(_ value: Double) -> Bool {
        value.isFinite && value > minimumValidPerformanceBaseline
    }

    private func isTrustedSnapshot(_ snapshot: AccountSnapshot) -> Bool {
        snapshot.isHydrated == true
        && snapshot.schemaVersion == AccountSnapshotSchema.trustedVersion
        && isValidPerformanceBaseline(snapshot.totalPortfolioValue)
    }

    private func isClearlyValidLegacySnapshot(_ snapshot: AccountSnapshot) -> Bool {
        let accountValue = accountValueSummary
        return savedPortfolioHoldings.isEmpty
        && snapshot.schemaVersion != AccountSnapshotSchema.trustedVersion
        && accountValue.isTrusted
        && abs(snapshot.totalPortfolioValue - accountValue.totalValue) <= 0.0001
        && isValidPerformanceBaseline(snapshot.totalPortfolioValue)
    }

    private func firstTrustedAccountSnapshot(where predicate: (AccountSnapshot) -> Bool) -> AccountSnapshot? {
        accountSnapshots.first { snapshot in
            predicate(snapshot)
            && isTrustedSnapshot(snapshot)
        }
    }

    private func lastTrustedAccountSnapshot(where predicate: (AccountSnapshot) -> Bool) -> AccountSnapshot? {
        accountSnapshots.last { snapshot in
            predicate(snapshot)
            && isTrustedSnapshot(snapshot)
        }
    }

    private func lastClearlyValidLegacyAccountSnapshot(where predicate: (AccountSnapshot) -> Bool) -> AccountSnapshot? {
        accountSnapshots.last { snapshot in
            predicate(snapshot)
            && isClearlyValidLegacySnapshot(snapshot)
        }
    }

    private func appendAccountSnapshotIfNeeded(force: Bool = false, accountValue: AccountValueSummary? = nil) {
        let accountValue = accountValue ?? accountValueSummary
        guard accountValue.isTrusted,
              accountValue.totalValue.isFinite,
              accountValue.totalValue >= 0 else {
            return
        }

        if !force, let lastSnapshot = accountSnapshots.last {
            let difference = abs(lastSnapshot.totalPortfolioValue - accountValue.totalValue)
            guard difference > 0.0001 || !isTrustedSnapshot(lastSnapshot) else { return }
        }

        accountSnapshots.append(
            AccountSnapshot(
                timestamp: Date(),
                totalPortfolioValue: accountValue.totalValue,
                isHydrated: true,
                schemaVersion: AccountSnapshotSchema.trustedVersion
            )
        )

        AccountSnapshotStore.save(accountSnapshots)
    }
}
