//
//  HomeStatsView.swift
//  VirtuTrade
//
//  Created by Jasin ‎ on 10/23/24.
//

import SwiftUI

struct PortfolioValueHeaderView: View {
    let portfolioValue: Double
    let availableCash: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Portfolio value")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(Color.theme.secondaryText)
            
            Text(portfolioValue.asCurrencyWith2Decimals())
                .font(.system(size: 29, weight: .bold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .foregroundStyle(Color.primary)
            
            Text("Cash available: \(availableCash.asCurrencyWith2Decimals())")
                .font(.footnote)
                .foregroundStyle(Color.theme.secondaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct HomeStatsView: View {
    
    @EnvironmentObject private var vm: HomeViewModel
    let portfolioValue: Double
    let availableCash: Double
    
    private struct MarketTickerItem: Identifiable {
        let id: String
        let title: String
        let value: String
        let percentageChange: Double?
    }
    
    private var marketStats: [MarketTickerItem] {
        let orderedTitles = [
            "Market Cap",
            "24h Volume",
            "BTC Dominance",
            "Market Cap 24h",
            "Markets"
        ]
        
        return orderedTitles.compactMap { title in
            guard let stat = vm.statistics.first(where: { $0.title == title }) else { return nil }
            return MarketTickerItem(
                id: title,
                title: stat.title,
                value: stat.value,
                percentageChange: stat.percentageChange
            )
        }
    }
    
    var body: some View {
        VStack(spacing: 10) {
            accountSummary
            marketStatsStrip
        }
        .padding(.horizontal, 14)
    }
    
    private var accountSummary: some View {
        PortfolioValueHeaderView(
            portfolioValue: portfolioValue,
            availableCash: availableCash
        )
    }
    
    private var marketStatsStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(Array(marketStats.enumerated()), id: \.element.id) { index, stat in
                    HStack(spacing: 6) {
                        Text(stat.title)
                            .font(.caption)
                            .foregroundStyle(Color.theme.secondaryText)
                            .lineLimit(1)
                        
                        Text(stat.value)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(valueColor(for: stat))
                            .lineLimit(1)
                    }
                    .fixedSize(horizontal: true, vertical: false)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    
                    if index < (marketStats.count - 1) {
                        Rectangle()
                            .fill(Color.theme.secondaryText.opacity(0.2))
                            .frame(width: 1, height: 16)
                            .padding(.vertical, 8)
                    }
                }
            }
            .padding(.horizontal, 2)
        }
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.theme.accentBackground)
        )
        .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
    }
    
    private func valueColor(for stat: MarketTickerItem) -> Color {
        if stat.title == "Market Cap 24h",
           let percentageChange = stat.percentageChange {
            return percentageChange >= 0 ? Color.theme.green : Color.theme.red
        }
        return Color.primary
    }
}

#Preview {
    HomeStatsView(
        portfolioValue: 14_691.35,
        availableCash: 87_654.32
    )
    .environmentObject(DeveloperPreview.instance.homeVM)
}
