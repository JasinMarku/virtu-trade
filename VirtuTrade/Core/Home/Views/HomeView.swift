//
//  HomeView.swift
//  VirtuTrade
//
//  Created by Jasin ‎ on 10/17/24.
//

import SwiftUI

struct HomeView: View {
    private enum LiveFilterMode: String, CaseIterable, Identifiable {
        case topGainers = "Top Gainers"
        case topVolume = "Top Volume"
        case topLosers = "Top Losers"
        
        var id: String { rawValue }
    }
    
    @AppStorage("vt_sim_cash_balance") private var simulatedCashBalance: Double = 100_000
    @EnvironmentObject private var vm: HomeViewModel
    @EnvironmentObject private var watchlistStore: WatchlistStore
    @State private var showPortfolio: Bool = false     // animate right
    @State private var showPortfolioEditor: Bool = false // new sheet for adding
    @State private var showSettingsView: Bool = false
    @State private var selectedCoin: CoinModel? = nil
    @State private var showDetailView: Bool = false
    @State private var showWatchlistView: Bool = false
    @State private var portfolioEditorCoin: CoinModel? = nil
    @State private var selectedLiveFilterMode: LiveFilterMode? = nil
    
    var body: some View {
        ZStack {
            // Background Layer
            Color.theme.background
                .ignoresSafeArea()
            
            // Content Layer
            VStack {
                
                homeHeader
                
                SearchBarView(searchText: $vm.searchText)
                    .padding(.top, -15)
                
                if !showPortfolio {
                    liveCategoryButtons
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                if !showPortfolio {
                    allCoinsList
                        .transition(.move(edge: .leading))
                }
                
                if showPortfolio {
                    portfolioCoinsList
                        .transition(.move(edge: .trailing))
                }
            }
            .animation(.easeInOut, value: showPortfolio)
            .sheet(item: $portfolioEditorCoin, onDismiss: {
                portfolioEditorCoin = nil
            }) { coin in
                PortfolioView(preselectedCoin: coin)
                    .environmentObject(vm)
                    .background(Color.theme.background.ignoresSafeArea())
            }
            .sheet(isPresented: $showPortfolioEditor) {
                PortfolioView(preselectedCoin: nil)
                    .environmentObject(vm)
                    .background(Color.theme.background.ignoresSafeArea())
            }
            .sheet(isPresented: $showSettingsView) {
                SettingsView()
                    .environmentObject(vm)
                    .presentationDetents([.fraction(0.8)])
                
            }
        }
        .navigationDestination(isPresented: $showDetailView) {
            if let _ = selectedCoin {
                DetailLoadingView(coin: $selectedCoin)
            }
        }
        .navigationDestination(isPresented: $showWatchlistView) {
            WatchlistView()
        }
    }
}

#Preview {
    NavigationStack {
        HomeView()
    }
    .environmentObject(DeveloperPreview.instance.homeVM)
    .environmentObject(WatchlistStore())
}

extension HomeView {
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
        let impact = UIImpactFeedbackGenerator(style: .soft)
        impact.prepare()
        impact.impactOccurred()
        
        withAnimation(.easeInOut(duration: 0.22)) {
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

    private var totalAccountValue: Double {
        simulatedCashBalance + portfolioHoldingsValue
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
        VStack(alignment: .leading, spacing: 4) {
            Text("My balance")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(Color.theme.secondaryText)
            
            Text(totalAccountValue.asCurrencyWith2Decimals())
                .font(.system(size: 29, weight: .bold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .foregroundStyle(Color.primary)

            VStack(alignment: .leading, spacing: 2) {
                Text("Portfolio value: \(portfolioHoldingsValue.asCurrencyWith2Decimals())")
            }
            .font(.footnote)
            .fontWeight(.semibold)
            .foregroundStyle(Color.theme.secondaryText)
        }
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
                        withAnimation(.easeInOut(duration: 0.2)) {
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
        .padding(.vertical, 8)
    }
    
    private var liveListHeader: some View {
        VStack(spacing: 0) {
            balanceHeader
            watchlistCard
            columnTitles
        }
    }
    
    private var portfolioListHeader: some View {
        VStack(spacing: 0) {
            HomeStatsView(
                totalAccountValue: totalAccountValue,
                availableCash: simulatedCashBalance,
                portfolioValue: portfolioHoldingsValue
            )
                .padding(.bottom, 12)
            columnTitles
        }
    }

    private var homeHeader: some View {
        HStack {
            Button(action: {
                let impact = UIImpactFeedbackGenerator(style: .light)
                impact.prepare()
                impact.impactOccurred()
                
                if showPortfolio {
                    showPortfolioEditor.toggle()
                } else {
                    showSettingsView.toggle()
                }
            }, label: {
                CircleButtonView(iconName: showPortfolio ? "plus" : "info")
                    .animation(.none, value: showPortfolio)
            })
            .accessibilityLabel(showPortfolio ? "Add Portfolio Asset" : "Open Settings")
            
            Spacer()
            
            Text(showPortfolio ? "Portfolio" : "Live Prices")
                .font(.headline)
                .fontWeight(.heavy)
                .foregroundStyle(Color.accentColor)
            
            Spacer()
            
            Button(action: {
                let impact = UIImpactFeedbackGenerator(style: .light)
                impact.prepare()
                impact.impactOccurred()
                
                showPortfolio.toggle()
            }, label: {
                CircleButtonView(iconName: "chevron.right")
                    .rotationEffect(Angle(degrees: showPortfolio ? 180 : 0))
                    .animation(.easeInOut, value: showPortfolio)
            })
            .accessibilityLabel(showPortfolio ? "Show Live Prices" : "Show Portfolio")
        }
        .padding(.horizontal)
    }
    
    // For Coin Navigation
    private func segue(coin: CoinModel) {
        selectedCoin = coin
        showDetailView.toggle()
    }
    
    private func openWatchlistView() {
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.prepare()
        impact.impactOccurred()
        
        showWatchlistView = true
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
                    let impact = UIImpactFeedbackGenerator(style: .soft)
                    impact.prepare()
                    impact.impactOccurred()
                    
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
                            let impact = UIImpactFeedbackGenerator(style: .soft)
                            impact.prepare()
                            impact.impactOccurred()
                            
                            segue(coin: coin)
                        }
                        .contextMenu {
                            Button {
                                editPortfolioHolding(coin)
                            } label: {
                                HStack {
                                    Image(systemName: "pencil")
                                    Text("Edit")
                                }
                            }

                            Button(role: .destructive) {
                                deletePortfolioHolding(coin)
                            } label: {
                                HStack {
                                    Image(systemName: "trash")
                                    Text("Delete")
                                }
                            }
                        }
                        .swipeActions(edge: .leading, allowsFullSwipe: false) {
                            Button {
                                editPortfolioHolding(coin)
                            } label: {
                                HStack {
                                    Image(systemName: "pencil")
                                    Text("Edit")
                                }
                            }
                            .tint(Color.theme.accent)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                deletePortfolioHolding(coin)
                            } label: {
                                HStack {
                                    Image(systemName: "trash")
                                    Text("Delete")
                                }
                            }
                        }
                }
            }
        }
        .scrollIndicators(.hidden)
        .listStyle(.plain)
    }

    private func editPortfolioHolding(_ coin: CoinModel) {
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.prepare()
        impact.impactOccurred()

        portfolioEditorCoin = coin
    }

    private func deletePortfolioHolding(_ coin: CoinModel) {
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.prepare()
        impact.impactOccurred()

        vm.updatePortfolio(coin: coin, amount: 0)
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
                let impact = UIImpactFeedbackGenerator(style: .soft)
                 impact.prepare()
                 impact.impactOccurred()
                
                withAnimation(.default) {
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
                    withAnimation(.default) {
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
                withAnimation(.default) {
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
