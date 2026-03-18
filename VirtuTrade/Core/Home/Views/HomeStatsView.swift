//
//  HomeStatsView.swift
//  VirtuTrade
//
//  Created by Jasin ‎ on 10/23/24.
//

import SwiftUI

struct PortfolioValueHeaderView: View {
    private enum PerformanceTrend {
        case positive
        case negative
        case neutral
    }
    
    let portfolioValue: Double
    let accountBalance: Double?
    let availableCash: Double
    let dayChangeValue: Double?
    let dayChangePercentage: Double?
    let allTimeChangeValue: Double?
    let allTimeChangePercentage: Double?
    let valueFontSize: CGFloat

    init(
        portfolioValue: Double,
        accountBalance: Double? = nil,
        availableCash: Double,
        dayChangeValue: Double? = nil,
        dayChangePercentage: Double? = nil,
        allTimeChangeValue: Double? = nil,
        allTimeChangePercentage: Double? = nil,
        valueFontSize: CGFloat = 30
    ) {
        self.portfolioValue = portfolioValue
        self.accountBalance = accountBalance
        self.availableCash = availableCash
        self.dayChangeValue = dayChangeValue
        self.dayChangePercentage = dayChangePercentage
        self.allTimeChangeValue = allTimeChangeValue
        self.allTimeChangePercentage = allTimeChangePercentage
        self.valueFontSize = valueFontSize
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("PORTFOLIO PERFORMANCE")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(Color.theme.secondaryText)
                .padding(.top, 8)

            
            Text(portfolioValue.asCurrencyWith2Decimals())
                .font(.system(size: valueFontSize, weight: .bold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .foregroundStyle(Color.primary)
            
            
            if let dayChangeValue, let dayChangePercentage {
                performanceLine(
                    value: dayChangeValue,
                    percentage: dayChangePercentage,
                    label: "Today"
                )
            }
            
            if let allTimeChangeValue, let allTimeChangePercentage {
                performanceLine(
                    value: allTimeChangeValue,
                    percentage: allTimeChangePercentage,
                    label: "All time"
                )
            }
            
            Text("Available balance: \(availableCash.asCurrencyWith2Decimals())")
                .font(.caption)
                .foregroundStyle(Color.theme.secondaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func performanceLine(value: Double, percentage: Double, label: String) -> some View {
        let trend = performanceTrend(value: value, percentage: percentage)
        
        return HStack(spacing: 5) {
            Image(systemName: iconName(for: trend))
                .font(.caption2.weight(.semibold))
            
            Text(formattedPerformanceText(value: value, percentage: percentage, trend: trend))
                .font(.footnote.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            Text(label)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Color.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .foregroundStyle(color(for: trend))
    }
    
    private func performanceTrend(value: Double, percentage: Double) -> PerformanceTrend {
        let safePercentage = sanitizedPercentage(percentage)
        
        if abs(value) < 0.005, abs(safePercentage) < 0.005 {
            return .neutral
        }
        
        return value >= 0 ? .positive : .negative
    }
    
    private func iconName(for trend: PerformanceTrend) -> String {
        switch trend {
        case .positive:
            return "chevron.up"
        case .negative:
            return "chevron.down"
        case .neutral:
            return "chevron.right"
        }
    }
    
    private func color(for trend: PerformanceTrend) -> Color {
        switch trend {
        case .positive:
            return Color.theme.green
        case .negative:
            return Color.theme.red
        case .neutral:
            return Color.theme.secondaryText
        }
    }
    
    private func formattedPerformanceText(value: Double, percentage: Double, trend: PerformanceTrend) -> String {
        let safePercentage = sanitizedPercentage(percentage)
        let sign: String
        switch trend {
        case .positive:
            sign = "+"
        case .negative:
            sign = "-"
        case .neutral:
            sign = ""
        }
        
        let dollars = abs(value).asCurrencyWith2Decimals()
        let percent = abs(safePercentage).asNumberString()
        return "\(sign)\(dollars) (\(sign)\(percent)%)"
    }
    
    private func sanitizedPercentage(_ percentage: Double) -> Double {
        guard percentage.isFinite, abs(percentage) <= 999_999.99 else {
            return 0
        }
        
        return percentage
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
