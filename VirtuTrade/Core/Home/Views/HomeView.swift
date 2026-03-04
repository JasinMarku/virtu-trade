//
//  HomeView.swift
//  VirtuTrade
//
//  Created by Jasin ‎ on 10/17/24.
//

import SwiftUI

struct HomeView: View {
    enum ScreenMode {
        case live
        case portfolio
    }
    
    private enum LiveFilterMode: String, CaseIterable, Identifiable {
        case topGainers = "Top Gainers"
        case topVolume = "Top Volume"
        case topLosers = "Top Losers"
        
        var id: String { rawValue }
    }
    
    @AppStorage("vt_sim_cash_balance") private var simulatedCashBalance: Double = 100_000
    @AppStorage("vt_reduce_motion") private var reduceMotion: Bool = false
    @EnvironmentObject private var vm: HomeViewModel
    @EnvironmentObject private var newsService: NewsService
    @EnvironmentObject private var watchlistStore: WatchlistStore
    @EnvironmentObject private var tradeHistoryStore: TradeHistoryStore
    @State private var showPortfolioEditor: Bool = false // new sheet for adding
    @State private var showSettingsView: Bool = false
    @State private var selectedCoin: CoinModel? = nil
    @State private var showWatchlistView: Bool = false
    @State private var showTradeHistoryView: Bool = false
    @State private var selectedLiveFilterMode: LiveFilterMode? = nil
    private let screenMode: ScreenMode
    private let onViewAllNews: (() -> Void)?
    
    init(screenMode: ScreenMode = .live, onViewAllNews: (() -> Void)? = nil) {
        self.screenMode = screenMode
        self.onViewAllNews = onViewAllNews
    }
    
    private var showPortfolio: Bool {
        screenMode == .portfolio
    }
    
    var body: some View {
        ZStack {
            // Background Layer
            Color.theme.background
                .ignoresSafeArea()
            
            // Content Layer
            VStack {
                
                homeHeader
                
                SearchBarView(searchText: $vm.searchText)
                    .padding(.vertical, -10)
                
                if !showPortfolio {
                    liveCategoryButtons
                        .transition(categoryButtonsTransition)
                }

                if !showPortfolio {
                    allCoinsList
                        .transition(liveCoinsTransition)
                }
                
                if showPortfolio {
                    portfolioCoinsList
                        .transition(portfolioCoinsTransition)
                }
            }
            .animation(motionAwareAnimation, value: showPortfolio)
            .fullScreenCover(isPresented: $showPortfolioEditor) {
                PortfolioView(preselectedCoin: nil)
                    .environmentObject(vm)
                    .environmentObject(tradeHistoryStore)
                    .background(Color.theme.background.ignoresSafeArea())
            }
            .sheet(isPresented: $showSettingsView) {
                SettingsView()
                    .environmentObject(vm)
                    .environmentObject(tradeHistoryStore)
                    .presentationDetents([.fraction(0.8)])
                
            }
            
            if showPortfolio {
                addPortfolioFAB
            }
        }
        .fullScreenCover(item: $selectedCoin) { coin in
            NavigationStack {
                DetailView(coin: coin)
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            XMarkButton()
                        }
                    }
            }
        }
        .navigationDestination(isPresented: $showWatchlistView) {
            WatchlistView()
        }
        .navigationDestination(isPresented: $showTradeHistoryView) {
            TradeHistoryView()
        }
        .task {
            await newsService.loadIfNeeded()
        }
    }
}

#Preview {
    NavigationStack {
        HomeView()
    }
    .environmentObject(DeveloperPreview.instance.homeVM)
    .environmentObject(NewsService())
    .environmentObject(WatchlistStore())
    .environmentObject(TradeHistoryStore())
}

extension HomeView {
    private var motionAwareAnimation: Animation? {
        reduceMotion ? nil : .easeInOut
    }
    
    private var categoryButtonsTransition: AnyTransition {
        reduceMotion ? .identity : .move(edge: .top).combined(with: .opacity)
    }
    
    private var liveCoinsTransition: AnyTransition {
        reduceMotion ? .identity : .move(edge: .leading)
    }
    
    private var portfolioCoinsTransition: AnyTransition {
        reduceMotion ? .identity : .move(edge: .trailing)
    }
    
    private func performMotionAwareAnimation(_ animation: Animation = .default, _ action: () -> Void) {
        if reduceMotion {
            action()
        } else {
            withAnimation(animation, action)
        }
    }
    
    private var displayedLiveCoins: [CoinModel] {
        switch selectedLiveFilterMode {
        case .topGainers:
            return vm.allCoins.sorted { (priceChangePercent(for: $0), $0.rank) > (priceChangePercent(for: $1), $1.rank) }
        case .topVolume:
            return vm.allCoins.sorted { (volumeValue(for: $0), $0.rank) > (volumeValue(for: $1), $1.rank) }
        case .topLosers:
            return vm.allCoins.sorted { (priceChangePercent(for: $0), $0.rank) < (priceChangePercent(for: $1), $1.rank) }
        case nil:
            return vm.allCoins
        }
    }
    
    private func priceChangePercent(for coin: CoinModel) -> Double {
        let change = coin.priceChangePercentage24H ?? 0
        return change.isFinite ? change : 0
    }
    
    private func volumeValue(for coin: CoinModel) -> Double {
        let volume = coin.totalVolume ?? 0
        return volume.isFinite ? volume : 0
    }
    
    private func selectLiveFilterMode(_ mode: LiveFilterMode) {
        AppHaptics.impact(.soft)
        performMotionAwareAnimation(.easeInOut(duration: 0.22)) {
            selectedLiveFilterMode = selectedLiveFilterMode == mode ? nil : mode
        }
    }
    
    private var portfolioHoldingsValue: Double {
        vm.portfolioCoins.reduce(0) { partialResult, coin in
            let holdings = coin.currentHoldings ?? 0
            let price = coin.currentPrice
            guard holdings.isFinite, price.isFinite, holdings >= 0, price >= 0 else {
                return partialResult
            }
            return partialResult + (holdings * price)
        }
    }

    private var portfolio24hChangeValue: Double {
        vm.portfolioCoins.reduce(0) { partialResult, coin in
            let holdings = coin.currentHoldings ?? 0
            let currentPrice = coin.currentPrice

            guard holdings.isFinite,
                  currentPrice.isFinite,
                  holdings >= 0,
                  currentPrice >= 0,
                  let pctChange = coin.priceChangePercentage24H,
                  pctChange.isFinite else {
                return partialResult
            }

            let currentValue = holdings * currentPrice
            let ratio = 1 + (pctChange / 100)
            guard currentValue.isFinite, ratio.isFinite, ratio > 0 else {
                return partialResult
            }

            let previousValue = currentValue / ratio
            guard previousValue.isFinite else {
                return partialResult
            }

            return partialResult + (currentValue - previousValue)
        }
    }

    private var portfolio24hChangePercentage: Double {
        guard portfolioHoldingsValue > 0 else { return 0 }
        return (portfolio24hChangeValue / portfolioHoldingsValue) * 100
    }

    private var watchlistCoins: [CoinModel] {
        let sourceCoins = vm.allCoinsUnfiltered.isEmpty ? vm.allCoins : vm.allCoinsUnfiltered
        return watchlistStore.ids.compactMap { id in
            sourceCoins.first(where: { $0.id == id })
        }
    }
    
    private var watchlistPreviewCoins: [CoinModel] {
        Array(watchlistCoins.prefix(3))
    }

    private var balanceHeader: some View {
        PortfolioValueHeaderView(
            portfolioValue: portfolioHoldingsValue,
            availableCash: simulatedCashBalance,
            dayChangeValue: portfolio24hChangeValue,
            dayChangePercentage: portfolio24hChangePercentage
        )
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
    
    private var liveCategoryButtons: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(LiveFilterMode.allCases) { mode in
                    Button {
                        selectLiveFilterMode(mode)
                    } label: {
                        Text(mode.rawValue)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .lineLimit(1)
                            .minimumScaleFactor(0.9)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 14)
                            .frame(minWidth: 150)
                            .background(
                                Capsule()
                                    .fill(selectedLiveFilterMode == mode ? Color.theme.accent : Color.theme.accentBackground)
                            )
                            .foregroundStyle(selectedLiveFilterMode == mode ? Color.white : Color.primary)
                    }
                    .buttonStyle(.plain)
                }
                
                if selectedLiveFilterMode != nil {
                    Button {
                        performMotionAwareAnimation(.easeInOut(duration: 0.2)) {
                            selectedLiveFilterMode = nil
                        }
                    } label: {
                        Text("All")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                Capsule()
                                    .stroke(Color.theme.secondaryText.opacity(0.45), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(Color.theme.secondaryText)
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 4)
    }
    
    private var liveListHeader: some View {
        VStack(spacing: 0) {
            balanceHeader
            HomeStatsView(
                portfolioValue: portfolioHoldingsValue,
                availableCash: simulatedCashBalance,
                showAccountSummary: false,
                showMarketStats: true
            )
            .padding(.bottom, 8)
            watchlistCard
            columnTitles
        }
    }
    
    private var portfolioListHeader: some View {
        VStack(spacing: 0) {
            balanceHeader
            
            HStack {
                Text("Activity")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.theme.secondaryText)
                
                Spacer()
                
                Button(action: openTradeHistoryView) {
                    HStack(spacing: 6) {
                        Image(systemName: "clock")
                        Text("Trade History")
                            .fontWeight(.semibold)
                    }
                    .font(.subheadline)
                    .foregroundStyle(Color.theme.accent)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Open Trade History")
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
            
            columnTitles
        }
    }

    private var homeHeader: some View {
        HStack {
            Button(action: {
                AppHaptics.impact(.light)
                showSettingsView.toggle()
            }, label: {
                CircleButtonView(iconName: "info")
            })
            .accessibilityLabel("Open Settings")
            
            Spacer()
            
            Text(showPortfolio ? "Portfolio" : "Live Prices")
                .font(.headline)
                .fontWeight(.heavy)
                .foregroundStyle(Color.primary)
            
            Spacer()
            
            CircleButtonView(iconName: "info")
                .hidden()
                .accessibilityHidden(true)
        }
        .padding(.horizontal)
    }
    
    private var addPortfolioFAB: some View {
        VStack {
            Spacer()
            
            HStack {
                Spacer()
                
                Button(action: {
                    AppHaptics.impact(.light)
                    showPortfolioEditor.toggle()
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(Color.white)
                        .frame(width: 65, height: 65)
                        .background(
                            Circle()
                                .fill(Color.theme.accent)
                        )
                        .shadow(color: Color.black.opacity(0.18), radius: 10, x: 0, y: 5)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Add Portfolio Asset")
                .padding(.trailing, 20)
                .padding(.bottom, 28)
            }
        }
    }
    
    // For Coin Navigation
    private func segue(coin: CoinModel) {
        selectedCoin = coin
    }
    
    private func openWatchlistView() {
        AppHaptics.impact(.light)
        
        showWatchlistView = true
    }
    
    private func openTradeHistoryView() {
        AppHaptics.impact(.light)
        showTradeHistoryView = true
    }
    
    private var watchlistCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Watchlist")
                    .font(.title3)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(action: openWatchlistView) {
                    Image(systemName: "arrow.right")
                        .font(.headline)
                        .foregroundStyle(Color.primary)
                        .frame(width: 40, height: 40)
                        .background(
                            Circle()
                                .fill(Color.theme.background.opacity(0.8))
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Open Watchlist")
            }
            
            if watchlistStore.ids.isEmpty {
                Text("Star coins to add them here.")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.theme.secondaryText)
                
                Button(action: openWatchlistView) {
                    Text("Manage")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(Color.theme.background.opacity(0.8))
                        )
                }
                .buttonStyle(.plain)
                .foregroundStyle(Color.primary)
            } else if watchlistPreviewCoins.isEmpty {
                Text("Loading watchlist...")
                    .font(.subheadline)
                    .foregroundStyle(Color.theme.secondaryText)
            } else {
                ForEach(watchlistPreviewCoins) { coin in
                    Button {
                        segue(coin: coin)
                    } label: {
                        watchlistRow(coin: coin)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.theme.accentBackground)
        )
        .padding(.horizontal)
        .padding(.vertical, 4)
    }
    
    private var latestNewsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Latest News")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: openNewsView) {
                    Text("View All")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.theme.accent)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("View all news")
            }
            
            if let article = newsService.latestArticle {
                Text(article.title)
                    .font(.subheadline)
                    .foregroundStyle(Color.primary)
                    .lineLimit(2)
            } else if newsService.isLoading {
                Text("Loading latest headline...")
                    .font(.subheadline)
                    .foregroundStyle(Color.theme.secondaryText)
            } else {
                Text("No news available right now.")
                    .font(.subheadline)
                    .foregroundStyle(Color.theme.secondaryText)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.theme.accentBackground)
        )
        .padding(.horizontal)
        .padding(.vertical, 4)
    }
    
    private func openNewsView() {
        AppHaptics.impact(.light)
        onViewAllNews?()
    }
    
    private func watchlistRow(coin: CoinModel) -> some View {
        let percentChange = coin.priceChangePercentage24H ?? 0
        let isPositive = percentChange >= 0
        
        return HStack(spacing: 12) {
            CoinImageView(coin: coin)
                .frame(width: 32, height: 32)
            
            VStack(alignment: .leading, spacing: 3) {
                Text(coin.name)
                    .font(.headline)
                    .lineLimit(1)
                
                Text(coin.symbol.uppercased())
                    .font(.caption)
                    .foregroundStyle(Color.theme.secondaryText)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(coin.currentPrice.asCurrencyWithAdaptiveDecimals())
                    .font(.headline)
                    .lineLimit(1)
                
                Text("\(isPositive ? "+" : "")\(percentChange.asNumberString())%")
                    .font(.caption)
                    .foregroundStyle(isPositive ? Color.theme.green : Color.theme.red)
            }
        }
    }
    
    private var allCoinsList: some View {
        List {
            liveListHeader
                .listRowInsets(.init())
                .listRowBackground(Color.theme.background)
                .listRowSeparator(.hidden)
            
            ForEach(displayedLiveCoins) { coin in
                CoinRowView(coin: coin, showHoldingsColumn: false)
                .listRowInsets(.init(top: 14, leading: 0, bottom: 14, trailing: 10))
                .listRowBackground(Color.theme.background)
                .listRowSeparator(.hidden)
                .onTapGesture {
                    AppHaptics.impact(.soft)
                    segue(coin: coin)
                }
            }
        }
        .refreshable {
            vm.reloadData()
        }
        .scrollIndicators(.hidden)
        .listStyle(.plain)
    }
    
    
    private var portfolioCoinsList: some View {
        List {
            portfolioListHeader
                .listRowInsets(.init())
                .listRowBackground(Color.theme.background)
                .listRowSeparator(.hidden)
            
            if vm.portfolioCoins.isEmpty && vm.searchText.isEmpty {
                EmptyStatePortfolio()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .frame(height: 300)
                    .listRowInsets(.init(top: 30, leading: 0, bottom: 0, trailing: 0))
                    .listRowBackground(Color.theme.background)
                    .listRowSeparator(.hidden)
            } else {
                ForEach(vm.portfolioCoins) { coin in
                    CoinRowView(coin: coin, showHoldingsColumn: true)
                        .listRowInsets(.init(top: 14, leading: 0, bottom: 14, trailing: 10))
                        .listRowBackground(Color.theme.background)
                        .listRowSeparator(.hidden)
                        .onTapGesture {
                            AppHaptics.impact(.soft)
                            segue(coin: coin)
                        }
                }
            }
        }
        .scrollIndicators(.hidden)
        .listStyle(.plain)
    }
    
    private var columnTitles: some View {
        HStack {
            HStack(spacing: 4) {
                Text("Coin")
                Image(systemName: "chevron.down")
                    .opacity((vm.sortOption == .rank || vm.sortOption == .rankReversed) ? 1.0 : 0.0)
                    .rotationEffect(Angle(degrees: vm.sortOption == .rank ? 0 : 180))
            }
            .onTapGesture {
                AppHaptics.impact(.soft)
                performMotionAwareAnimation(.default) {
                    vm.sortOption = vm.sortOption == .rank ? .rankReversed : .rank
                }
            }
            
            Spacer()
            
            if showPortfolio {
                HStack(spacing: 4) {
                    Text("Holdings")
                    Image(systemName: "chevron.down")
                        .opacity((vm.sortOption == .holdings || vm.sortOption == .holdingsReversed) ? 1.0 : 0.0)
                        .rotationEffect(Angle(degrees: vm.sortOption == .holdings ? 0 : 180))
                }
                .onTapGesture {
                    performMotionAwareAnimation(.default) {
                        vm.sortOption = vm.sortOption == .holdings ? .holdingsReversed : .holdings
                    }
                }
            }
            
            HStack(spacing: 4) {
                Text("Price")
                Image(systemName: "chevron.down")
                    .opacity((vm.sortOption == .price || vm.sortOption == .priceReversed) ? 1.0 : 0.0)
                    .rotationEffect(Angle(degrees: vm.sortOption == .price ? 0 : 180))
            }
            .frame(width: UIScreen.main.bounds.width / 3.5, alignment: .trailing)
            .onTapGesture {
                performMotionAwareAnimation(.default) {
                    vm.sortOption = vm.sortOption == .price ? .priceReversed : .price
                }
            }
        }
        .font(.subheadline)
        .fontWeight(.medium)
        .foregroundStyle(Color.theme.secondaryText)
        .padding(.horizontal)
        .padding(.top, 10)

    }
}

struct TradeHistoryView: View {
    @EnvironmentObject private var tradeHistoryStore: TradeHistoryStore
    
    private var trades: [TradeModel] {
        tradeHistoryStore.getTrades()
    }
    
    var body: some View {
        List {
            if trades.isEmpty {
                Text("No trades yet. Buy or sell a coin from the detail screen to see activity.")
                    .font(.subheadline)
                    .foregroundStyle(Color.theme.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .listRowBackground(Color.theme.background)
                    .listRowSeparator(.hidden)
                    .padding(.vertical, 30)
            } else {
                ForEach(trades) { trade in
                    TradeHistoryRow(trade: trade)
                        .listRowInsets(.init(top: 12, leading: 0, bottom: 12, trailing: 10))
                        .listRowBackground(Color.theme.background)
                        .listRowSeparator(.hidden)
                }
            }
        }
        .padding()
        .listStyle(.plain)
        .scrollIndicators(.hidden)
        .background(Color.theme.background)
        .navigationTitle("Trade History")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct TradeHistoryRow: View {
    let trade: TradeModel
    
    private var tradeTypeText: String {
        trade.type.rawValue.uppercased()
    }
    
    private var tradeTypeColor: Color {
        trade.type == .buy ? Color.theme.green : Color.theme.red
    }
    
    private var timestampText: String {
        trade.timestamp.formatted(date: .abbreviated, time: .shortened)
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 8) {
                    Text(tradeTypeText)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(tradeTypeColor)
                    
                    Text(trade.symbol.uppercased())
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.primary)
                }
                
                Text(trade.name)
                    .font(.caption)
                    .foregroundStyle(Color.theme.secondaryText)
                
                Text(timestampText)
                    .font(.caption2)
                    .foregroundStyle(Color.theme.secondaryText)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 5) {
                Text("\(formattedQuantity(trade.quantity)) \(trade.symbol.uppercased())")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.primary)
                
                Text("@ \(trade.priceAtExecution.asCurrencyWithAdaptiveDecimals())")
                    .font(.caption)
                    .foregroundStyle(Color.theme.secondaryText)
                
                Text(trade.totalValue.asCurrencyWithAdaptiveDecimals())
                    .font(.caption)
                    .foregroundStyle(Color.theme.secondaryText)
            }
        }
    }
    
    private func formattedQuantity(_ value: Double) -> String {
        let fixed = String(format: "%.6f", value)
        return fixed
            .replacingOccurrences(of: #"([0-9])0+$"#, with: "$1", options: .regularExpression)
            .replacingOccurrences(of: #"\.$"#, with: "", options: .regularExpression)
    }
}
