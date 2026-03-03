//
//  HomeStatsView.swift
//  VirtuTrade
//
//  Created by Jasin ‎ on 10/23/24.
//

import SwiftUI

struct HomeStatsView: View {
    
    @EnvironmentObject private var vm: HomeViewModel
    let totalAccountValue: Double
    let availableCash: Double
    let portfolioValue: Double
    
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
        VStack(alignment: .leading, spacing: 8) {
            Text("Total account value \(totalAccountValue.asCurrencyWith2Decimals())")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(Color.theme.secondaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            HStack(spacing: 10) {
                accountSummaryItem(
                    title: "Available Cash",
                    value: availableCash.asCurrencyWith2Decimals()
                )
                
                accountSummaryItem(
                    title: "Portfolio Value",
                    value: portfolioValue.asCurrencyWith2Decimals()
                )
            }
        }
    }
    
    private func accountSummaryItem(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(Color.theme.secondaryText)
                .lineLimit(1)
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .foregroundStyle(Color.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.theme.accentBackground)
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
        totalAccountValue: 102_345.67,
        availableCash: 87_654.32,
        portfolioValue: 14_691.35
    )
    .environmentObject(DeveloperPreview.instance.homeVM)
}
