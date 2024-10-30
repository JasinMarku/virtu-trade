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
                    portfolioCoinsList
                        .transition(.move(edge: .trailing))
                }

                Spacer(minLength: 0)
            }
            .animation(.easeInOut, value: showPortfolio)
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
                if showPortfolio {
                    showPortfolioView.toggle()
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
                showPortfolio.toggle()
            }, label: {
                CircleButtonView(iconName: "chevron.right")
                    .rotationEffect(Angle(degrees: showPortfolio ? 180 : 0))
                    .animation(.easeInOut, value: showPortfolio)
            })
        }
        .padding(.horizontal)
    }
    
    private var allCoinsList: some View {
        List {
            ForEach(vm.allCoins) { coin in
                CoinRowView(coin: coin, showHoldingsColumn: false)
                .listRowInsets(.init(top: 14, leading: 0, bottom: 14, trailing: 10))
                .listRowBackground(Color.theme.background)
                .listRowSeparator(.hidden)
            }
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
            }
        }
        .scrollIndicators(.hidden)
        .listStyle(.plain)
    }
    
    private var columnTitles: some View {
        HStack {
            Text("Coin")
                Spacer()
            if showPortfolio {
                Text("Holdings")
            }
            Text("Price")
                .frame(width: UIScreen.main.bounds.width / 3.5, alignment: .trailing)
        }
        .font(.subheadline)
        .fontWeight(.medium)
        .foregroundStyle(Color.theme.secondaryText)
        .padding(.horizontal)
        .padding(.top, 10)

    }
}
