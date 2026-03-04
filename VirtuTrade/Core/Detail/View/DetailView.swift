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
    private enum TradeSide: String, CaseIterable, Identifiable {
        case buy = "Buy"
        case sell = "Sell"
        
        var id: String { rawValue }
    }
    
    @EnvironmentObject private var homeVM: HomeViewModel
    @EnvironmentObject private var watchlistStore: WatchlistStore
    @EnvironmentObject private var tradeHistoryStore: TradeHistoryStore
    @State private var showDescriptionSheet: Bool = false
    @State private var tradeSide: TradeSide = .buy
    @State private var showTradeSheet: Bool = false
    @State private var tradeQuantityText: String = ""
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
    
    private var parsedTradeQuantity: Double? {
        let trimmed = tradeQuantityText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return Double(trimmed)
    }
    
    private var effectiveTradeQuantity: Double? {
        if tradeSide == .sell, sellAllAmountRaw != nil {
            let holdings = homeVM.availableHoldings(for: vm.coin.id)
            guard holdings > 0 else { return nil }
            return holdings
        }
        return parsedTradeQuantity
    }
    
    private var estimatedTradeValue: Double {
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
    
    private var tradeType: TradeType {
        tradeSide == .buy ? .buy : .sell
    }
    
    private var tradeValidationMessage: String? {
        guard let quantity = effectiveTradeQuantity else {
            return "Enter a valid quantity."
        }
        return homeVM.tradeValidationMessage(coin: tradeCoin, type: tradeType, quantity: quantity)
    }
    
    private var tradeErrorText: String? {
        if let tradeErrorMessage {
            return tradeErrorMessage
        }
        
        guard !tradeQuantityText.isEmpty else { return nil }
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
    
    private var tradeEstimateLabel: String {
        tradeSide == .buy ? "Estimated cost" : "Estimated proceeds"
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
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("\(tradeSide.rawValue) \(tradeCoin.symbol.uppercased())")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(Color.primary)
                    Text(tradeCoin.name)
                        .font(.subheadline)
                        .foregroundStyle(Color.theme.secondaryText)
                }
                .padding(.vertical, 10)
                
                Spacer()
                
                Button(action: closeTradeSheet) {
                    Image(systemName: "xmark")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(Color.theme.secondaryText)
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)
            }
            
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Quantity")
                        .font(.caption)
                        .foregroundStyle(Color.theme.secondaryText)
                    
                    Spacer()
                    
                    if tradeSide == .sell {
                        Button {
                            fillSellAllQuantity()
                        } label: {
                            Text("Sell All")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color.theme.red)
                        }
                        .buttonStyle(.plain)
                        .disabled(currentHoldings <= holdingEpsilon)
                        .opacity(currentHoldings > holdingEpsilon ? 1 : 0.45)
                    }
                }
                
                if tradeSide == .sell {
                    Text("Available: \(availableHoldingsText) \(tradeCoin.symbol.uppercased())")
                        .font(.caption)
                        .foregroundStyle(Color.theme.secondaryText)
                        .accessibilityLabel("Available \(availableHoldingsText) \(tradeCoin.symbol.uppercased())")
                }
                
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    TextField("0.00", text: $tradeQuantityText)
                        .keyboardType(.decimalPad)
                        .font(.system(size: 34, weight: .bold))
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                    
                    Text(tradeCoin.symbol.uppercased())
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(Color.theme.secondaryText)
                }
                
                Rectangle()
                    .fill(Color.theme.secondaryText.opacity(0.35))
                    .frame(height: 1)
            }
            
            VStack(spacing: 8) {
                HStack {
                    Text(tradeEstimateLabel)
                        .font(.subheadline)
                        .foregroundStyle(Color.theme.secondaryText)
                        .fontWeight(.semibold)
                    Spacer()
                    Text(estimatedTradeValue.asCurrencyWithAdaptiveDecimals())
                        .font(.headline.weight(.bold))
                        .foregroundStyle(Color.primary)
                }
                
                HStack {
                    Text("Price")
                        .font(.caption)
                        .foregroundStyle(Color.theme.secondaryText)
                        .fontWeight(.semibold)
                    Spacer()
                    Text(currentPrice.asCurrencyWithAdaptiveDecimals())
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.theme.secondaryText)
                }
            }
            
            if let tradeErrorText {
                Text(tradeErrorText)
                    .font(.footnote)
                    .foregroundStyle(Color.theme.red)
            }
            
            Button(action: executeTrade) {
                Text(tradeSide == .buy ? "Buy" : "Sell")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(
                        tradeSide == .buy ? Color.theme.green : Color.theme.red,
                        in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                    )
                    .foregroundStyle(.white)
            }
            .buttonStyle(.plain)
            .disabled(!isTradeValid)
            .opacity(isTradeValid ? 1 : 0.45)
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 28)
        .frame(maxWidth: .infinity, minHeight: tradePanelHeight, alignment: .topLeading)
        .background(
            Color.theme.background.opacity(0.96)
                .ignoresSafeArea(edges: .bottom)
        )
        .onChange(of: tradeQuantityText) { _, _ in
            tradeErrorMessage = nil
            guard tradeSide == .sell, let sellAllAmountRaw else { return }
            let expectedText = exactHoldingsInputString(sellAllAmountRaw)
            if tradeQuantityText != expectedText {
                self.sellAllAmountRaw = nil
            }
        }
        .onChange(of: tradeSide) { _, _ in
            tradeErrorMessage = nil
            sellAllAmountRaw = nil
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
    
    private func presentTradeSheet(for side: TradeSide) {
        AppHaptics.impact(.light)
        tradeSide = side
        tradeQuantityText = ""
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
        tradeQuantityText = exactHoldingsInputString(currentHoldings)
        tradeErrorMessage = nil
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
    
    private func closeTradeSheet() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.9)) {
            showTradeSheet = false
        }
        tradeQuantityText = ""
        sellAllAmountRaw = nil
        tradeErrorMessage = nil
    }
    
    private func executeTrade() {
        guard let quantity = effectiveTradeQuantity else {
            tradeErrorMessage = HomeViewModel.TradeExecutionError.invalidQuantity.userMessage
            AppHaptics.notification(.error)
            return
        }
        
        switch homeVM.executeTrade(coin: tradeCoin, type: tradeType, quantity: quantity, tradeHistoryStore: tradeHistoryStore) {
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
