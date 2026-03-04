//
//  WatchlistView.swift
//  VirtuTrade
//
//  Created by Codex on 3/3/26.
//

import SwiftUI

struct WatchlistView: View {
    @EnvironmentObject private var vm: HomeViewModel
    @EnvironmentObject private var watchlistStore: WatchlistStore
    
    @State private var selectedCoin: CoinModel? = nil
    
    private var watchlistCoins: [CoinModel] {
        let sourceCoins = vm.allCoinsUnfiltered.isEmpty ? vm.allCoins : vm.allCoinsUnfiltered
        return watchlistStore.ids.compactMap { id in
            sourceCoins.first(where: { $0.id == id })
        }
    }
    
    var body: some View {
        List {
            if watchlistStore.ids.isEmpty {
                Text("Star coins to add them here.")
                    .font(.subheadline)
                    .foregroundStyle(Color.theme.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .listRowBackground(Color.theme.background)
                    .listRowSeparator(.hidden)
                    .padding(.vertical, 28)
            } else if watchlistCoins.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .listRowBackground(Color.theme.background)
                    .listRowSeparator(.hidden)
                    .padding(.vertical, 28)
            } else {
                ForEach(watchlistCoins) { coin in
                    CoinRowView(coin: coin, showHoldingsColumn: false)
                        .listRowInsets(.init(top: 14, leading: 0, bottom: 14, trailing: 10))
                        .listRowBackground(Color.theme.background)
                        .listRowSeparator(.hidden)
                        .onTapGesture {
                            AppHaptics.impact(.soft)
                            selectedCoin = coin
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                AppHaptics.impact(.light)
                                watchlistStore.remove(coin.id)
                            } label: {
                                Label("Remove", systemImage: "star.slash")
                            }
                        }
                }
            }
        }
        .listStyle(.plain)
        .scrollIndicators(.hidden)
        .background(Color.theme.background)
        .navigationTitle("Watchlist")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            vm.reloadData()
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
    }
}

#Preview {
    NavigationStack {
        WatchlistView()
    }
    .environmentObject(DeveloperPreview.instance.homeVM)
    .environmentObject(WatchlistStore())
    .environmentObject(TradeHistoryStore())
}
