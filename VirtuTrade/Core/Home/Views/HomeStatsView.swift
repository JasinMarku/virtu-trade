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
    let dayChangeValue: Double?
    let dayChangePercentage: Double?

    init(
        portfolioValue: Double,
        availableCash: Double,
        dayChangeValue: Double? = nil,
        dayChangePercentage: Double? = nil
    ) {
        self.portfolioValue = portfolioValue
        self.availableCash = availableCash
        self.dayChangeValue = dayChangeValue
        self.dayChangePercentage = dayChangePercentage
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Portfolio value")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(Color.theme.secondaryText)
            
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(portfolioValue.asCurrencyWith2Decimals())
                    .font(.system(size: 29, weight: .bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .foregroundStyle(Color.primary)

                if let dayChangeValue,
                   let dayChangePercentage {
                    HStack(spacing: 4) {
                        Image(systemName: dayChangeValue >= 0 ? "chevron.up" : "chevron.down")
                            .font(.caption2.weight(.semibold))

                        Text(formattedDayChange(value: dayChangeValue, percentage: dayChangePercentage))
                            .font(.caption.weight(.semibold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .foregroundStyle(dayChangeValue >= 0 ? Color.theme.green : Color.theme.red)
                    .padding(.bottom, 2)
                }
            }
            
            Text("Cash available: \(availableCash.asCurrencyWith2Decimals())")
                .font(.footnote)
                .foregroundStyle(Color.theme.secondaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func formattedDayChange(value: Double, percentage: Double) -> String {
        let sign = value >= 0 ? "+" : "-"
        let dollars = abs(value).asCurrencyWith2Decimals()
        let percent = abs(percentage).asNumberString()
        return "\(sign)\(dollars) (\(sign)\(percent)%)"
    }
}

struct HomeStatsView: View {
    
    @EnvironmentObject private var vm: HomeViewModel
    let portfolioValue: Double
    let availableCash: Double
    let showAccountSummary: Bool
    let showMarketStats: Bool
    
    init(
        portfolioValue: Double,
        availableCash: Double,
        showAccountSummary: Bool = true,
        showMarketStats: Bool = true
    ) {
        self.portfolioValue = portfolioValue
        self.availableCash = availableCash
        self.showAccountSummary = showAccountSummary
        self.showMarketStats = showMarketStats
    }
    
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
        VStack(spacing: 6) {
            if showAccountSummary {
                accountSummary
            }
            
            if showMarketStats {
                marketStatsStrip
            }
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
            LazyHStack(spacing: 14) {
                ForEach(marketStats) { stat in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(stat.title)
                            .font(.caption)
                            .foregroundStyle(Color.theme.secondaryText)
                            .lineLimit(1)
                        
                        Text(stat.value)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundStyle(valueColor(for: stat))
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                    }
                    .frame(minWidth: 138, alignment: .leading)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.theme.accentBackground)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.theme.secondaryText.opacity(0.12), lineWidth: 1)
                    )
                }
            }
            .scrollTargetLayout()
        }
        .frame(minHeight: 102)
        .scrollTargetBehavior(.viewAligned)
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
