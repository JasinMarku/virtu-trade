//
//  HomeView.swift
//  VirtuTrade
//
//  Created by Jasin ‎ on 10/17/24.
//

import SwiftUI

struct HomeView: View {
    
    @AppStorage("vt_sim_cash_balance") private var simulatedCashBalance: Double = 100_000
    @EnvironmentObject private var vm: HomeViewModel
    @State private var showPortfolio: Bool = false     // animate right
    @State private var showPortfolioEditor: Bool = false // new sheet for adding
    @State private var showSettingsView: Bool = false
    @State private var selectedCoin: CoinModel? = nil
    @State private var showDetailView: Bool = false
    @State private var portfolioEditorCoin: CoinModel? = nil
    
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
    }
}

#Preview {
    NavigationStack {
        HomeView()
    }
    .environmentObject(DeveloperPreview.instance.homeVM)
}

extension HomeView {
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

    private var balanceHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("My balance")
                .font(.subheadline)
                .foregroundStyle(Color.theme.secondaryText)
            
            Text(totalAccountValue.asCurrencyWith2Decimals())
                .font(.system(size: 32, weight: .bold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .foregroundStyle(Color.primary)

            VStack(alignment: .leading, spacing: 2) {
                Text("Available cash: \(simulatedCashBalance.asCurrencyWith2Decimals())")
                Text("Portfolio value: \(portfolioHoldingsValue.asCurrencyWith2Decimals())")
            }
            .font(.footnote)
            .foregroundStyle(Color.theme.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
    
    private var scrollableListHeader: some View {
        VStack(spacing: 0) {
            HomeStatsView(showPortfolio: $showPortfolio)
                .padding(.bottom, 12)
            
            balanceHeader
                .opacity(showPortfolio ? 0 : 1)
                .frame(height: showPortfolio ? 0 : nil)
                .clipped()
                .accessibilityHidden(showPortfolio)
                .animation(.easeInOut(duration: 0.22), value: showPortfolio)
            
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
                .foregroundStyle(Color.primary)
            
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
    
    private var allCoinsList: some View {
        List {
            scrollableListHeader
                .listRowInsets(.init())
                .listRowBackground(Color.theme.background)
                .listRowSeparator(.hidden)
            
            ForEach(vm.allCoins) { coin in
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
            scrollableListHeader
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
