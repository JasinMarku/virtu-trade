//
//  HomeViewModel.swift
//  VirtuTrade
//
//  Created by Jasin ‎ on 10/17/24.
//

import Foundation
import Combine

class HomeViewModel: ObservableObject {
    
    @Published var statistics: [StatisticModel] = []      // Stores key statistics (like market cap, volume) for display
    @Published var allCoins: [CoinModel] = []             // List of all available coins from the API
    @Published var portfolioCoins: [CoinModel] = []       // List of coins in the user's portfolio
    @Published var isLoading: Bool = false                // Flag for loading state during data fetch
    @Published var searchText: String = ""                // Holds text entered by the user for coin search
    
    private let coinDataService = CoinDataService()       // Service to fetch all coin data
    private let marketDataService = MarketDataService()   // Service to fetch market data
    private let portfolioDataService = PortfolioDataService() // Service for managing the portfolio's data storage
    private var cancellables = Set<AnyCancellable>()      // Holds cancellable objects for Combine subscriptions
    
    init() {
        addSubcribers()
    }
    
    func addSubcribers() {
        // Updates allCoins based on search text and API data
        $searchText
            .combineLatest(coinDataService.$allCoins)     // Combines searchText with allCoins from the API
            .debounce(for: .seconds(0.5), scheduler: DispatchQueue.main) // Adds delay to avoid frequent updates
            .map(filterCoins)                             // Filters coins based on search text
            .sink { [weak self] (returnedCoins) in
                self?.allCoins = returnedCoins            // Updates allCoins with filtered result
            }
            .store(in: &cancellables)
        
        // Updates portfolio coins list with relevant coin data from allCoins and portfolio entities
        $allCoins
            .combineLatest(portfolioDataService.$savedEntities) // Combines allCoins with saved portfolio entities
            .map(mapAllCoinsToPortfolioCoins)            // Maps allCoins to portfolio coins
            .sink { [weak self] returnedCoins in
                self?.portfolioCoins = returnedCoins     // Updates portfolioCoins with filtered coins in the portfolio
            }
            .store(in: &cancellables)
        
        // Updates global market data and portfolio statistics
        marketDataService.$marketData
            .combineLatest($portfolioCoins)              // Combines market data with portfolio coins
            .map(mapGlobalMarketData)                    // Maps to a list of global statistics
            .sink { [weak self] (returnedStats) in
                self?.statistics = returnedStats         // Updates statistics with global market data
                self?.isLoading = false                  // Ends loading once data is received
            }
            .store(in: &cancellables)
    }
    
    func updatePortfolio(coin: CoinModel, amount: Double) {
        // Updates portfolio with the new coin amount, then saves the data
        portfolioDataService.updatePortfolio(coin: coin, amount: amount)
    }
    
    func reloadData() {
        // Triggers data reload from API services
        isLoading = true                                 // Sets loading state to true during fetch
        coinDataService.getCoins()                       // Fetches updated coin data
        marketDataService.getData()                      // Fetches updated market data
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
    
    // Maps all coins to those held in the portfolio, updating their holdings
    private func mapAllCoinsToPortfolioCoins(allCoins: [CoinModel], portfolioEntities: [PortfolioEntity]) -> [CoinModel] {
        allCoins
            .compactMap { (coin) -> CoinModel? in
                guard let entity = portfolioEntities.first(where: {$0.coinID == coin.id}) else {
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
                let percentChange = coin.priceChangePercentage24H ?? 0 / 100
                let previousValue = currentValue / (1 + percentChange)
                
                return previousValue                     // Approximate value of each coin 24 hours ago
            }
            .reduce(0, +)
        
        // Calculates 24-hour percentage change in portfolio value
        let percentageChange = ((portfolioValue - previousValue) / previousValue) * 100
        
        // Creates portfolio statistic
        let portfolio = StatisticModel(
            title: "Portfolio Value",
            value: portfolioValue.asCurrencyWith2Decimals(),
            percentageChange: percentageChange)
        
        // Adds market and portfolio statistics to the stats array
        stats.append(contentsOf: [marketCap, volume, btcDominance, portfolio])
        return stats
    }
}
