//
//  HomeView.swift
//  VirtuTrade
//
//  Created by Jasin ‎ on 10/17/24.
//

import SwiftUI

struct HomeView: View {
    
    @EnvironmentObject private var vm: HomeViewModel
    @State private var showPortfolio: Bool = false     // animate right
    @State private var showPortfolioView: Bool = false // new sheet
    @State private var showSettingsView: Bool = false
    @State private var selectedCoin: CoinModel? = nil
    @State private var showDetailView: Bool = false
    
    var body: some View {
        ZStack {
            // Background Layer
            Color.theme.background
                .ignoresSafeArea()
                .sheet(isPresented: $showPortfolioView, content: {
                    PortfolioView()
                        .environmentObject(vm)
                        .presentationBackground(Color.theme.background)
                })
            
            // Content Layer
            VStack {
                homeHeader
                
                HomeStatsView(showPortfolio: $showPortfolio)
                    .padding(.bottom, -5)

                SearchBarView(searchText: $vm.searchText)
                    .padding(.top, -5)
                                
                columnTitles
                
                if !showPortfolio {
                    allCoinsList
                    .transition(.move(edge: .leading))
                }
                
                if showPortfolio {
                    ZStack(alignment: .top) {
                        if vm.portfolioCoins.isEmpty && vm.searchText.isEmpty {
                            EmptyStatePortfolio()
                                .frame(height: 300)
                        } else {
                            portfolioCoinsList
                                .transition(.move(edge: .trailing))
                        }
                    }
                }

                Spacer(minLength: 0)
            }
            .animation(.easeInOut, value: showPortfolio)
            .sheet(isPresented: $showSettingsView) {
                SettingsView()
                    .presentationDetents([.fraction(4/5)])
                
            }
        }
        .navigationDestination(isPresented: $showDetailView) {
            if selectedCoin != nil {
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
    private var homeHeader: some View {
        HStack {
            Button(action: {
                let impact = UIImpactFeedbackGenerator(style: .light)
                impact.prepare()
                impact.impactOccurred()
                
                if showPortfolio {
                    showPortfolioView.toggle()
                } else {
                    showSettingsView.toggle()
                }
            }, label: {
                CircleButtonView(iconName: showPortfolio ? "plus" : "info")
                    .animation(.none, value: showPortfolio)
            })
            
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
