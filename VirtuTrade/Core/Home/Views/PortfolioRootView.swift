//
//  PortfolioRootView.swift
//  VirtuTrade
//
//  Created by Codex on 3/3/26.
//

import SwiftUI

struct PortfolioRootView: View {
    var body: some View {
        HomeView(screenMode: .portfolio)
    }
}

#Preview {
    NavigationStack {
        PortfolioRootView()
    }
    .environmentObject(DeveloperPreview.instance.homeVM)
    .environmentObject(NewsService())
    .environmentObject(WatchlistStore())
    .environmentObject(TradeHistoryStore())
}
