# VirtuTrade
![VirtuTrade-1](https://github.com/user-attachments/assets/fd5d8367-c5c1-4196-8a67-551a664e7863)

Cryptocurrency Tracking and Virtual Trading App that allows users to monitor crypto coins and simulate share holding using any real money. It's an ideal platform for those who want to learn and practice with crypto trading in a risk-free environment.

## Features
- Real-time cryptocurrency price tracking
- Virtual portfolio management
- Detailed coin statistics and market data
- Interactive price charts
- Coin search functionality
- Portfolio performance tracking
- Dark/Light mode support

## Core Technologies
- Swift 5
- SwiftUI
- Core Data (for local data persistence)

## Architectures & Patterns
- MVVM (Model-View-ViewModel)
- Observable Pattern
- Repository Pattern
- Dependency Injection

## APIs & Services
- CoinGecko API (for cryptocurrency data)
- URLSession for networking
- Combine Framework for reactive programming


## Most Proud Of: Advanced Swift Charts Implementation
One of the most exciting features of VirtuTrade is the interactive price chart powered by Swift Charts. This implementation goes beyond a simple line graph by incorporating:

- Dynamic color coding based on price trends (green for positive, red for negative, Based on 24hr Coin Performace)
- Interactive drag gesture to explore price points
- Customized axis and grid styling
- Smooth cardinal interpolation for a more natural price curve
```swift
Chart {
    ForEach(Array(zip(coin.sparklineIn7D?.price ?? [], 0...168)), id: \.1) { price, index in
        LineMark(
            x: .value("Time", index),
            y: .value("Price", price)
        )
        .interpolationMethod(.cardinal)
        if let selectedIndex, selectedIndex == index {
            RuleMark (
                x: .value("Time", index)
            )
            .foregroundStyle(Color.theme.secondaryText)
            .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
        }
    }
}
.chartXAxis(.hidden)
.chartYScale(domain: .automatic(includesZero: false))
.chartYAxis {
    AxisMarks(position: .trailing) { _ in
        AxisGridLine(centered: true, stroke: StrokeStyle(lineWidth: 0))
        AxisValueLabel()
    }
}
.frame(height: 200)
.foregroundStyle(coin.priceChangePercentage24H ?? 0 >= 0 ? Color.theme.green : Color.theme.red)
.shadow(color: coin.priceChangePercentage24H ?? 0 >= 0 ? Color.theme.green : Color.theme.red, radius: 10, x: 0, y: 11)
.overlay(
    GeometryReader { proxy in
        Rectangle()
        .fill(.clear)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    let index = Int((value.location.x / proxy.size.width) * CGFloat(priceData.count))
                    if index >= 0 && index < priceData.count {
                        if index != previousIndex {
                            impactGenerator.impactOccurred()
                            previousIndex = index
                        }
                        
                        selectedIndex = index
                        selectedPrice = priceData[index]
                    }
                }
                .onEnded { _ in
                    selectedIndex = nil
                    selectedPrice = nil
                }
        )
    }
)
```
