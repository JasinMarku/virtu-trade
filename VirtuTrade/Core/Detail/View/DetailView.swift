//
//  DetailView.swift
//  VirtuTrade
//
//  Created by Jasin ‎ on 11/10/24.
//

import SwiftUI
import Charts

struct DetailLoadingView: View {
    
    @Binding var coin: CoinModel?

    var body: some View {
        ZStack {
            if let coin = coin {
                DetailView(coin: coin)
            }
        }
    }
}

struct DetailView: View {
    @EnvironmentObject private var homeVM: HomeViewModel
    @EnvironmentObject private var watchlistStore: WatchlistStore
    @EnvironmentObject private var tradeHistoryStore: TradeHistoryStore
    @State private var showDescriptionSheet: Bool = false
    @State private var tradeSide: TradeType = .buy
    @State private var tradeInputMode: TradeInputMode = .usd
    @State private var showTradeSheet: Bool = false
    @State private var tradeInputText: String = ""
    @State private var sellAllAmountRaw: Double?
    @State private var tradeErrorMessage: String?
    @StateObject private var vm: DetailViewModel
    private let columns: [GridItem] = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    private let spacing: CGFloat = 30
    private let holdingEpsilon: Double = 0.00000001
    
    init(coin: CoinModel, mockDetailData: CoinDetailModel? = nil) {
        _vm = StateObject(wrappedValue: DetailViewModel(coin: coin))
    }
    
    var body: some View {
        ZStack {
            Color.theme.background
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    ChartView(coin: vm.coin)
                        .padding(.vertical)
                    
                    tradeActionSection
                    
                    detailStateContent
                }
                .padding()
                .padding(.top, -15)
            }
            
            tradeOverlay
        }
        .scrollIndicators(.hidden)
        .task(id: vm.coin.id) {
            vm.loadCoinDetails()
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                navigationBarTrailingItems
            }
        }
    }
}

#Preview {
    NavigationStack {
        DetailView(coin: DeveloperPreview.instance.coin)
    }
    .environmentObject(DeveloperPreview.instance.homeVM)
    .environmentObject(WatchlistStore())
    .environmentObject(TradeHistoryStore())
}

struct ChartView: View {
    let coin: CoinModel
    
    @State private var selectedPrice: Double?
    @State private var selectedIndex: Int?
    @State private var previousIndex: Int?
    
    private var priceData: [Double] {
        coin.sparklineIn7D?.price ?? []
    }
    
    private var displayPrice: Double {
        selectedPrice ?? coin.currentPrice
    }
    
    private var dateText: String {
        let calendar = Calendar.current
        let selectedDate: Date
        
        if let index = selectedIndex, !priceData.isEmpty {
            // Calculate date for dragging
            let endDate = Date()
            let hoursPerDataPoint = 168.0 / Double(priceData.count)
            guard let startDate = calendar.date(byAdding: .day, value: -7, to: endDate),
                  let date = calendar.date(byAdding: .hour,
                                         value: Int(Double(index) * hoursPerDataPoint),
                                         to: startDate) else { return "" }
            selectedDate = date
        } else {
            // Use current date when not dragging
            selectedDate = Date()
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "E, MMM d"
        return formatter.string(from: selectedDate)
    }
    
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8){
            VStack(alignment: .leading, spacing: 10) {
                Text(coin.name)
                    .font(.title)
                    .fontWeight(.bold)
                
                    Text(displayPrice.asCurrencyWithAdaptiveDecimals())
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(coin.priceChangePercentage24H ?? 0 >= 0 ? Color.theme.green : Color.theme.red)
                        .shadow(color: coin.priceChangePercentage24H ?? 0 >= 0 ? Color.theme.green.opacity(0.5) : Color.theme.red.opacity(0.5), radius: 8)
                
                
                    Text(dateText)
                        .font(.headline)
                        .foregroundStyle(Color.theme.secondaryText)
            }
            
            Chart {
                ForEach(Array(priceData.enumerated()), id: \.offset) { index, price in
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
                                    guard !priceData.isEmpty, proxy.size.width > 0 else { return }

                                    let clampedX = min(max(value.location.x, 0), proxy.size.width)
                                    let normalizedX = clampedX / proxy.size.width
                                    let scaledIndex = normalizedX * CGFloat(max(priceData.count - 1, 0))
                                    let index = Int(scaledIndex.rounded(.towardZero))

                                    if index >= 0 && index < priceData.count {
                                        if index != previousIndex {
                                            AppHaptics.impact(.light)
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
        }
    }
}

extension DetailView {
    private var tradeCoin: CoinModel {
        homeVM.allCoinsUnfiltered.first(where: { $0.id == vm.coin.id })
        ?? homeVM.allCoins.first(where: { $0.id == vm.coin.id })
        ?? homeVM.portfolioCoins.first(where: { $0.id == vm.coin.id })
        ?? vm.coin
    }
    
    private var currentPrice: Double {
        let price = tradeCoin.currentPrice
        guard price.isFinite, price >= 0 else { return 0 }
        return price
    }
    
    private var currentHoldings: Double {
        let holdings = homeVM.availableHoldings(for: vm.coin.id)
        guard holdings.isFinite, holdings >= 0 else { return 0 }
        return holdings
    }
    
    private var availableHoldingsText: String {
        exactHoldingsInputString(currentHoldings)
    }
    
    private var parsedTradeInput: Double? {
        let trimmed = tradeInputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return Double(trimmed)
    }
    
    private var inputCoinQuantity: Double {
        guard let input = parsedTradeInput, input > 0 else { return 0 }
        
        if tradeSide == .buy, tradeInputMode == .usd {
            guard currentPrice > 0 else { return 0 }
            return input / currentPrice
        }
        
        return input
    }
    
    private var effectiveTradeQuantity: Double? {
        if tradeSide == .sell, sellAllAmountRaw != nil {
            let holdings = homeVM.availableHoldings(for: vm.coin.id)
            guard holdings > 0 else { return nil }
            return holdings
        }
        
        let quantity = inputCoinQuantity
        guard quantity > 0 else { return nil }
        return quantity
    }
    
    private var estimatedTradeUSDValue: Double {
        if tradeSide == .buy, tradeInputMode == .usd {
            return max(parsedTradeInput ?? 0, 0)
        }
        
        guard let quantity = effectiveTradeQuantity, quantity > 0 else { return 0 }
        return quantity * currentPrice
    }
    
    private var positionSnapshot: TradePositionSnapshot {
        tradeHistoryStore.position(for: vm.coin.id)
    }
    
    private var unrealizedPnL: Double {
        guard currentHoldings > holdingEpsilon, positionSnapshot.averageCost > 0 else { return 0 }
        return (currentPrice - positionSnapshot.averageCost) * currentHoldings
    }
    
    private var unrealizedPnLPercent: Double? {
        let costBasisValue = positionSnapshot.averageCost * currentHoldings
        guard costBasisValue > 0 else { return nil }
        return (unrealizedPnL / costBasisValue) * 100
    }
    
    private var tradeValidationMessage: String? {
        guard let quantity = effectiveTradeQuantity else {
            return "Enter a valid quantity."
        }
        return homeVM.tradeValidationMessage(coin: tradeCoin, type: tradeSide, quantity: quantity)
    }
    
    private var tradeErrorText: String? {
        if let tradeErrorMessage {
            return tradeErrorMessage
        }
        
        guard !tradeInputText.isEmpty else { return nil }
        return tradeValidationMessage
    }
    
    private var isTradeValid: Bool {
        tradeValidationMessage == nil
    }
    
    private var currentValueText: String {
        (currentHoldings * currentPrice).asCurrencyWithAdaptiveDecimals()
    }
    
    private var tradeActionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                quickTradeButton(title: "Buy", color: Color.theme.green) {
                    presentTradeSheet(for: .buy)
                }
                
                quickTradeButton(title: "Sell", color: Color.theme.red) {
                    presentTradeSheet(for: .sell)
                }
            }
            
            positionSection
        }
    }
    
    private var positionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Your Position")
                .font(.headline)
            
            positionRow(
                title: "Holdings",
                value: "\(formattedQuantity(currentHoldings)) \(tradeCoin.symbol.uppercased())"
            )
            positionRow(
                title: "Avg cost",
                value: positionSnapshot.quantity > holdingEpsilon
                ? positionSnapshot.averageCost.asCurrencyWithAdaptiveDecimals()
                : "n/a"
            )
            positionRow(title: "Current value", value: currentValueText)
            positionRow(title: "Unrealized PnL", value: unrealizedPnLValueText, valueColor: unrealizedPnLColor)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.theme.accentBackground)
        )
    }
    
    private var tradePanelHeight: CGFloat { 430 }
    
    private var tradeOverlay: some View {
        ZStack(alignment: .bottom) {
            if showTradeSheet {
                Color.black.opacity(0.35)
                    .ignoresSafeArea()
                    .contentShape(Rectangle())
                    .onTapGesture {
                        closeTradeSheet()
                    }
                    .transition(.opacity)
                
                tradeOverlayPanel
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.9), value: showTradeSheet)
    }
    
    private var tradeOverlayPanel: some View {
        TradeOverlayPanelContent(
            tradeSide: tradeSide,
            coinName: tradeCoin.name,
            coinSymbol: tradeCoin.symbol,
            inputText: $tradeInputText,
            inputMode: tradeInputMode,
            availableHoldingsText: tradeSide == .sell ? availableHoldingsText : nil,
            canSellAll: tradeSide == .sell && currentHoldings > holdingEpsilon,
            estimatedValueText: estimatedTradeUSDValue.asCurrencyWithAdaptiveDecimals(),
            currentPriceText: currentPrice.asCurrencyWithAdaptiveDecimals(),
            errorText: tradeErrorText,
            isConfirmEnabled: isTradeValid,
            onClose: closeTradeSheet,
            onConfirm: executeTrade,
            onSellAll: fillSellAllQuantity,
            onToggleInputMode: toggleTradeInputMode
        )
        .frame(maxWidth: .infinity, minHeight: tradePanelHeight, alignment: .topLeading)
        .background(
            Color.theme.background.opacity(0.985)
                .ignoresSafeArea(edges: .bottom)
        )
        .onChange(of: tradeInputText) { _, _ in
            tradeErrorMessage = nil
            guard tradeSide == .sell, let sellAllAmountRaw else { return }
            let expectedText = exactHoldingsInputString(sellAllAmountRaw)
            if tradeInputText != expectedText {
                self.sellAllAmountRaw = nil
            }
        }
        .onChange(of: tradeSide) { _, _ in
            tradeErrorMessage = nil
            sellAllAmountRaw = nil
            if tradeSide == .sell {
                tradeInputMode = .coin
            }
        }
    }
    
    private func quickTradeButton(title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .foregroundStyle(color)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(color.opacity(0.14))
                )
        }
        .buttonStyle(.plain)
    }
    
    private func positionRow(title: String, value: String, valueColor: Color = Color.primary) -> some View {
        HStack {
            Text(title)
                .font(.caption)
                .foregroundStyle(Color.theme.secondaryText)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(valueColor)
                .multilineTextAlignment(.trailing)
        }
    }
    
    private var unrealizedPnLColor: Color {
        guard currentHoldings > holdingEpsilon, positionSnapshot.averageCost > 0 else {
            return Color.theme.secondaryText
        }
        
        if unrealizedPnL > 0 {
            return Color.theme.green
        }
        if unrealizedPnL < 0 {
            return Color.theme.red
        }
        return Color.theme.secondaryText
    }
    
    private var unrealizedPnLValueText: String {
        guard currentHoldings > holdingEpsilon, positionSnapshot.averageCost > 0 else {
            return "n/a"
        }
        
        let valueText = unrealizedPnL.asCurrencyWithAdaptiveDecimals()
        guard let percent = unrealizedPnLPercent else { return valueText }
        return "\(valueText) (\(percent.asPercentString()))"
    }
    
    private func formattedQuantity(_ value: Double) -> String {
        let fixed = String(format: "%.6f", value)
        return fixed
            .replacingOccurrences(of: #"([0-9])0+$"#, with: "$1", options: .regularExpression)
            .replacingOccurrences(of: #"\.$"#, with: "", options: .regularExpression)
    }
    
    private func presentTradeSheet(for side: TradeType) {
        AppHaptics.impact(.light)
        tradeSide = side
        tradeInputMode = side == .buy ? .usd : .coin
        tradeInputText = ""
        sellAllAmountRaw = nil
        tradeErrorMessage = nil
        withAnimation(.spring(response: 0.3, dampingFraction: 0.9)) {
            showTradeSheet = true
        }
    }
    
    private func fillSellAllQuantity() {
        guard currentHoldings > holdingEpsilon else { return }
        AppHaptics.impact(.light)
        sellAllAmountRaw = currentHoldings
        tradeInputText = exactHoldingsInputString(currentHoldings)
        tradeErrorMessage = nil
    }
    
    private func toggleTradeInputMode() {
        guard tradeSide == .buy else { return }
        
        let nextMode: TradeInputMode = tradeInputMode == .usd ? .coin : .usd
        if let value = parsedTradeInput, value > 0, currentPrice > 0 {
            let convertedValue: Double = tradeInputMode == .usd ? (value / currentPrice) : (value * currentPrice)
            tradeInputText = formattedInputValue(convertedValue, mode: nextMode)
        } else {
            tradeInputText = ""
        }
        
        sellAllAmountRaw = nil
        tradeInputMode = nextMode
    }
    
    private func exactHoldingsInputString(_ value: Double) -> String {
        guard value.isFinite, value > 0 else { return "0" }
        
        let scale: Double = 10_000_000
        let truncated = (value * scale).rounded(.down) / scale
        
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = false
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 7
        
        return formatter.string(from: NSNumber(value: truncated)) ?? "0"
    }
    
    private func formattedInputValue(_ value: Double, mode: TradeInputMode) -> String {
        guard value.isFinite, value > 0 else { return "" }
        
        switch mode {
        case .usd:
            return String(format: "%.2f", value)
        case .coin:
            return exactHoldingsInputString(value)
        }
    }
    
    private func closeTradeSheet() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.9)) {
            showTradeSheet = false
        }
        tradeInputText = ""
        sellAllAmountRaw = nil
        tradeErrorMessage = nil
    }
    
    private func executeTrade() {
        guard let quantity = effectiveTradeQuantity else {
            tradeErrorMessage = HomeViewModel.TradeExecutionError.invalidQuantity.userMessage
            AppHaptics.notification(.error)
            return
        }
        
        switch homeVM.executeTrade(coin: tradeCoin, type: tradeSide, quantity: quantity, tradeHistoryStore: tradeHistoryStore) {
        case .success:
            dismissKeyboard()
            AppHaptics.notification(.success)
            closeTradeSheet()
        case .failure(let error):
            tradeErrorMessage = error.userMessage
            AppHaptics.notification(.error)
        }
    }
    
    @ViewBuilder
    private var detailStateContent: some View {
        switch vm.viewState {
        case .loading:
            loadingStateSection
        case .failed(let message):
            failureStateSection(message: message)
        case .empty:
            emptyStateSection
        case .loaded:
            loadedContentSection
        }
    }
    
    private var loadedContentSection: some View {
        VStack(spacing: 20) {
            overviewTitle
            
            Divider()
            
            descriptionSection
            
            overviewGrid
            
            additionalTitle
            
            Divider()
            
            additionalGrid
        }
    }
    
    private var loadingStateSection: some View {
        VStack(spacing: 12) {
            ProgressView()
                .progressViewStyle(.circular)
            
            Text("Loading coin details...")
                .font(.subheadline)
                .foregroundStyle(Color.theme.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 30)
    }
    
    private var emptyStateSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("No detail data available right now.")
                .font(.headline)
                .foregroundStyle(Color.primary)
            
            Text("Please try again in a moment.")
                .font(.subheadline)
                .foregroundStyle(Color.theme.secondaryText)
            
            Button(action: vm.loadCoinDetails) {
                Text("Retry")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color.primary)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.theme.accentBackground)
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 8)
    }
    
    private func failureStateSection(message: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Couldn't load coin details.")
                .font(.headline)
                .foregroundStyle(Color.primary)
            
            Text(message)
                .font(.subheadline)
                .foregroundStyle(Color.theme.secondaryText)
            
            Button(action: vm.loadCoinDetails) {
                Text("Retry")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color.primary)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.theme.accentBackground)
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 8)
    }
    
    
    private var descriptionSection: some View {
          Group {
              if let coinDescription = vm.coinDescription,
                 !coinDescription.isEmpty {
                  VStack(alignment: .leading, spacing: 10) {
                      HStack {
                          Text("About \(vm.coin.name)")
                              .font(.headline)
                              .foregroundStyle(Color.theme.accent)
                          
                          Spacer()
                          
                          Button {
                              showDescriptionSheet = true
                          } label: {
                              HStack(spacing: 4) {
                                  Text("View More")
                                  Image(systemName: "chevron.right")
                              }
                              .font(.callout)
                              .foregroundStyle(Color.theme.secondaryText)
                          }
                      }
                      
                      Text(coinDescription)
                          .lineLimit(3)
                          .font(.callout)
                          .foregroundStyle(Color.theme.secondaryText)
                  }
                  .frame(maxWidth: .infinity, alignment: .leading)
                  .sheet(isPresented: $showDescriptionSheet) {
                      DescriptionView(coin: vm.coin, description: vm.coinDescription ?? "", redditURL: vm.redditURL, websiteURL: vm.websiteURL)
                  }
              }
          }
      }
    
    private var overviewTitle: some View {
        Text("Overview")
            .font(.title.bold())
            .foregroundStyle(Color.theme.accent)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var additionalTitle: some View {
        Text("Additional Details")
            .font(.title.bold())
            .foregroundStyle(Color.theme.accent)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var overviewGrid: some View {
        LazyVGrid(columns: columns,
                  alignment: .leading,
                  spacing: spacing,
                  pinnedViews: []
                  ,content: {
            ForEach(vm.overviewStatistics) { stat in
                StatisticView(stat: stat)
            }
        })
    }
    
    private var additionalGrid: some View {
        LazyVGrid(columns: columns,
                  alignment: .leading,
                  spacing: spacing,
                  pinnedViews: []
                  ,content: {
            ForEach(vm.additionalStatistics) { stat in
                StatisticView(stat: stat)
            }
        })
    }
    
    private var isWatchlisted: Bool {
        watchlistStore.isWatchlisted(vm.coin.id)
    }
    
    private func toggleWatchlist() {
        AppHaptics.impact(.light)
        watchlistStore.toggle(vm.coin.id)
    }
    
    private var navigationBarTrailingItems: some View {
        HStack {
            Button(action: toggleWatchlist) {
                Image(systemName: isWatchlisted ? "star.fill" : "star")
                    .font(.headline)
                    .foregroundStyle(isWatchlisted ? Color.theme.accent : Color.theme.secondaryText)
            }
            .accessibilityLabel(isWatchlisted ? "Remove from Watchlist" : "Add to Watchlist")
            
            Text(vm.coin.symbol.uppercased())
                .font(.headline)
                .foregroundStyle(Color.theme.secondaryText)
            
            CoinImageView(coin: vm.coin)
                .frame(width: 25, height: 25)
        }
    }
}
