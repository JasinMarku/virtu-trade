//
//  PortfolioView.swift
//  VirtuTrade
//
//  Created by Jasin ‎ on 10/28/24.
//

import UIKit
import SwiftUI

enum TradeInputMode: String, CaseIterable, Identifiable {
    case usd = "USD"
    case coin = "COIN"
    
    var id: String { rawValue }
}

struct TradeOverlayPanelContent: View {
    let tradeSide: TradeType
    let coinName: String
    let coinSymbol: String
    @Binding var inputText: String
    let inputMode: TradeInputMode
    let availableHoldingsText: String?
    let canSellAll: Bool
    let estimatedValueText: String
    let currentPriceText: String
    let errorText: String?
    let isConfirmEnabled: Bool
    let onClose: () -> Void
    let onConfirm: () -> Void
    let onSellAll: () -> Void
    let onToggleInputMode: () -> Void
    
    private var tradeColor: Color {
        tradeSide == .buy ? Color.theme.green : Color.theme.red
    }
    
    private var titleText: String {
        "\(tradeSide == .buy ? "Buy" : "Sell") \(coinSymbol.uppercased())"
    }
    
    private var inputLabelText: String {
        tradeSide == .buy && inputMode == .usd ? "Amount" : "Quantity"
    }
    
    private var inputUnitText: String {
        tradeSide == .buy && inputMode == .usd ? "USD" : coinSymbol.uppercased()
    }
    
    private var inputPlaceholderText: String {
        tradeSide == .buy && inputMode == .usd ? "0.00" : "0.0000000"
    }
    
    private var inputModeButtonTitle: String {
        inputMode == .usd ? "Use COIN" : "Use USD"
    }
    
    private var estimateLabelText: String {
        tradeSide == .buy ? "Estimated cost" : "Estimated proceeds"
    }
    
    private var confirmButtonTitle: String {
        tradeSide == .buy ? "Buy" : "Sell"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(titleText)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(Color.primary)
                    Text(coinName)
                        .font(.subheadline)
                        .foregroundStyle(Color.theme.secondaryText)
                    Text("Real market prices. Simulated trades.")
                        .font(.caption)
                        .foregroundStyle(Color.theme.secondaryText)
                    Text("Simulated trade only. No real transaction occurs.")
                        .font(.caption2)
                        .foregroundStyle(Color.theme.secondaryText.opacity(0.88))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 10)
                
                Spacer()
                
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(Color.theme.secondaryText)
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)
            }
            
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(inputLabelText)
                        .font(.caption)
                        .foregroundStyle(Color.theme.secondaryText)
                    
                    Spacer()
                    
                    if tradeSide == .sell {
                        Button(action: onSellAll) {
                            Text("Sell All")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color.theme.red)
                        }
                        .buttonStyle(.plain)
                        .disabled(!canSellAll)
                        .opacity(canSellAll ? 1 : 0.45)
                    } else {
                        Button(action: onToggleInputMode) {
                            Text(inputModeButtonTitle)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color.theme.accent)
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                if let availableHoldingsText, tradeSide == .sell {
                    Text("Available: \(availableHoldingsText) \(coinSymbol.uppercased())")
                        .font(.caption)
                        .foregroundStyle(Color.theme.secondaryText)
                }
                
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    TextField(inputPlaceholderText, text: $inputText)
                        .keyboardType(.decimalPad)
                        .font(.system(size: 34, weight: .bold))
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                    
                    Text(inputUnitText)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(Color.theme.secondaryText)
                }
                
                Rectangle()
                    .fill(Color.theme.secondaryText.opacity(0.35))
                    .frame(height: 1)
            }
            
            VStack(spacing: 8) {
                HStack {
                    Text(estimateLabelText)
                        .font(.subheadline)
                        .foregroundStyle(Color.theme.secondaryText)
                        .fontWeight(.semibold)
                    Spacer()
                    Text(estimatedValueText)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(Color.primary)
                }
                
                HStack {
                    Text("Price")
                        .font(.caption)
                        .foregroundStyle(Color.theme.secondaryText)
                        .fontWeight(.semibold)
                    Spacer()
                    Text(currentPriceText)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.theme.secondaryText)
                }
            }
            
            if let errorText {
                Text(errorText)
                    .font(.footnote)
                    .foregroundStyle(Color.theme.red)
            }
            
            Button(action: onConfirm) {
                Text(confirmButtonTitle)
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(
                        tradeColor,
                        in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                    )
                    .foregroundStyle(.white)
            }
            .buttonStyle(.plain)
            .disabled(!isConfirmEnabled)
            .opacity(isConfirmEnabled ? 1 : 0.45)
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 28)
    }
}

struct PortfolioView: View {
    let preselectedCoin: CoinModel?
    let showsDismissButton: Bool
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var vm: HomeViewModel
    @EnvironmentObject private var tradeHistoryStore: TradeHistoryStore
    @State private var localSearchText: String = ""
    @State private var selectedTradeCoin: CoinModel? = nil
    @State private var inputMode: TradeInputMode = .usd
    @State private var tradeInputText: String = ""
    @State private var showTradeAlert: Bool = false
    @State private var tradeAlertMessage: String = ""
    
    init(preselectedCoin: CoinModel? = nil, showsDismissButton: Bool = true) {
        self.preselectedCoin = preselectedCoin
        self.showsDismissButton = showsDismissButton
    }
    
    private var parsedInput: Double? {
        let trimmed = tradeInputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return Double(trimmed)
    }
    
    private var tradeSide: TradeType {
        .buy
    }
    
    private var activeCoin: CoinModel? {
        guard let selectedTradeCoin else { return nil }
        return vm.allCoinsUnfiltered.first(where: { $0.id == selectedTradeCoin.id })
        ?? vm.allCoins.first(where: { $0.id == selectedTradeCoin.id })
        ?? vm.portfolioCoins.first(where: { $0.id == selectedTradeCoin.id })
        ?? selectedTradeCoin
    }
    
    private var selectedCoinSymbol: String {
        activeCoin?.symbol.uppercased() ?? "COIN"
    }
    
    private var currentPrice: Double {
        let price = activeCoin?.currentPrice ?? 0
        guard price.isFinite, price >= 0 else { return 0 }
        return price
    }
    
    private var tradeCoinAmountFromInput: Double {
        guard let input = parsedInput, input > 0 else { return 0 }
        
        if inputMode == .usd {
            guard currentPrice > 0 else { return 0 }
            return input / currentPrice
        }
        
        return input
    }
    
    private var tradeUSDValue: Double {
        if inputMode == .usd {
            return max(parsedInput ?? 0, 0)
        }
        
        let quantity = tradeCoinAmountFromInput
        guard quantity > 0 else { return 0 }
        return quantity * currentPrice
    }
    
    private var validationMessage: String? {
        guard selectedTradeCoin != nil else {
            return "Select a coin to trade."
        }
        
        guard let parsedInput, parsedInput > 0 else {
            return "Enter a valid trade amount."
        }
        
        guard let coin = activeCoin else {
            return "Select a coin to trade."
        }
        
        guard currentPrice > 0 else {
            return "Price is unavailable. Try again in a moment."
        }
        
        let quantity = tradeCoinAmountFromInput
        guard quantity > 0, tradeUSDValue > 0 else {
            return "Trade amount must be greater than zero."
        }
        
        return vm.tradeValidationMessage(coin: coin, type: .buy, quantity: quantity)
    }
    
    private var isTradeValid: Bool {
        validationMessage == nil
    }
        
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    SearchBarView(searchText: $localSearchText)
                    coinLogoList
                }
            }
            .navigationTitle("Trade")
            .toolbar {
                if showsDismissButton {
                    ToolbarItem(placement: .topBarLeading) {
                        Button(action: dismissTradeScreen) {
                            Image(systemName: "xmark")
                                .tint(.primary)
                        }
                    }
                }
            }
            .onAppear {
                applyPreselectedCoinIfNeeded()
            }
            .onChange(of: preselectedCoin?.id) { _, _ in
                applyPreselectedCoinIfNeeded()
            }
            .onDisappear {
                localSearchText = ""
            }
            .alert("Trade Error", isPresented: $showTradeAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(tradeAlertMessage)
            }
            .sheet(item: $selectedTradeCoin, onDismiss: resetTradeDraft) { _ in
                buyTradeSheet
                    .presentationDetents([.fraction(0.6), .large])
                    .presentationDragIndicator(.visible)
            }
        }
        .background(.clear)
    }
}

#Preview {
    PortfolioView()
        .environmentObject(DeveloperPreview.instance.homeVM)
        .environmentObject(TradeHistoryStore())
}

extension PortfolioView {
    private var popularCoinIDs: [String] {
        ["bitcoin", "ethereum", "solana", "ripple", "chainlink", "dogecoin"]
    }
    
    private var popularCoins: [CoinModel] {
        popularCoinIDs.compactMap { id in
            searchableCoins.first(where: { $0.id == id })
        }
    }
    
    private var searchableCoins: [CoinModel] {
        vm.allCoinsUnfiltered.isEmpty ? vm.allCoins : vm.allCoinsUnfiltered
    }
    
    private var filteredSearchCoins: [CoinModel] {
        let query = localSearchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else { return searchableCoins }
        
        return searchableCoins.filter { coin in
            coin.name.lowercased().contains(query) ||
            coin.symbol.lowercased().contains(query) ||
            coin.id.lowercased().contains(query)
        }
    }
    
    private var coinSelectionCoins: [CoinModel] {
        localSearchText.isEmpty ? popularCoins : filteredSearchCoins
    }

    private var topGainerCoins: [CoinModel] {
        searchableCoins
            .compactMap { coin -> (coin: CoinModel, change: Double)? in
                guard let change = coin.priceChangePercentage24H, change.isFinite else { return nil }
                return (coin, change)
            }
            .sorted { $0.change > $1.change }
            .prefix(10)
            .map(\.coin)
    }
    
    private var coinLogoList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Popular")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(Color.theme.secondaryText)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 10) {
                    ForEach(coinSelectionCoins) { coin in
                        CoinLogoView(coin: coin)
                            .padding(.vertical, 6)
                            .frame(width: 75)
                            .onTapGesture {
                                presentBuySheet(for: coin)
                            }
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(selectedTradeCoin?.id == coin.id ? Color.theme.green.opacity(0.2) : Color.clear)
                            )
                    }
                }
                .frame(height: 120)
                .padding(.leading)
            }
            
            topGainersSection
        }
    }

    private var topGainersSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Today's Top Gainers")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(Color.theme.secondaryText)
                .padding(.horizontal)
            
            VStack(spacing: 0) {
                ForEach(topGainerCoins) { coin in
                    Button {
                        presentBuySheet(for: coin)
                    } label: {
                        CoinRowView(coin: coin, showHoldingsColumn: false, showChangeBackground: false)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.plain)
                    
                    if coin.id != topGainerCoins.last?.id {
                        Divider()
                            .padding(.leading, 16)
                    }
                }
            }
            .padding(.horizontal, 5)
        }
    }
    
    private var buyTradeSheet: some View {
        TradeOverlayPanelContent(
            tradeSide: .buy,
            coinName: activeCoin?.name ?? "",
            coinSymbol: selectedCoinSymbol,
            inputText: $tradeInputText,
            inputMode: inputMode,
            availableHoldingsText: nil,
            canSellAll: false,
            estimatedValueText: tradeUSDValue.asCurrencyWithAdaptiveDecimals(),
            currentPriceText: currentPrice.asCurrencyWithAdaptiveDecimals(),
            errorText: tradeErrorText,
            isConfirmEnabled: isTradeValid,
            onClose: dismissBuySheet,
            onConfirm: confirmTrade,
            onSellAll: {},
            onToggleInputMode: toggleInputMode
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.theme.background.ignoresSafeArea())
    }
    
    private var tradeErrorText: String? {
        if let validationMessage, !tradeInputText.isEmpty {
            return validationMessage
        }
        return nil
    }
        
    private func presentBuySheet(for coin: CoinModel) {
        selectedTradeCoin = coin
        inputMode = .usd
        tradeInputText = ""
        tradeAlertMessage = ""
        showTradeAlert = false
        AppHaptics.impact(.light)
    }
    
    private func dismissBuySheet() {
        selectedTradeCoin = nil
    }
    
    private func resetTradeDraft() {
        tradeInputText = ""
        inputMode = .usd
        tradeAlertMessage = ""
        showTradeAlert = false
    }
    
    private func confirmTrade() {
        guard let coin = activeCoin else { return }
        
        guard isTradeValid else {
            tradeAlertMessage = validationMessage ?? "Unable to complete this trade."
            showTradeAlert = true
            return
        }
        
        let quantity = tradeCoinAmountFromInput
        let executionResult = vm.executeTrade(
            coin: coin,
            type: .buy,
            quantity: quantity,
            tradeHistoryStore: tradeHistoryStore
        )
        
        switch executionResult {
        case .success:
            dismissBuySheet()
        case .failure(let error):
            tradeAlertMessage = error.userMessage
            showTradeAlert = true
            AppHaptics.notification(.error)
            return
        }
        
        tradeInputText = ""
        dismissKeyboard()

        triggerTradeConfirmationHaptic()
        dismiss()
    }
    
    private func triggerTradeConfirmationHaptic() {
        AppHaptics.impact(.rigid)
        AppHaptics.notification(.success)
    }
    
    private func toggleInputMode() {
        let nextMode: TradeInputMode = inputMode == .usd ? .coin : .usd
        
        if let value = parsedInput, value > 0, currentPrice > 0 {
            let convertedValue: Double
            switch inputMode {
            case .usd:
                convertedValue = value / currentPrice
            case .coin:
                convertedValue = value * currentPrice
            }
            tradeInputText = formattedInputValue(convertedValue, mode: nextMode)
        } else {
            tradeInputText = ""
        }
        
        inputMode = nextMode
    }
    
    private func formattedInputValue(_ value: Double, mode: TradeInputMode) -> String {
        guard value.isFinite, value > 0 else { return "" }
        
        switch mode {
        case .usd:
            return String(format: "%.2f", value)
        case .coin:
            return formattedCoinInput(value)
        }
    }
    
    private func formattedCoinInput(_ value: Double) -> String {
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
    
    private func applyPreselectedCoinIfNeeded() {
        guard let preselectedCoin else { return }
        presentBuySheet(for: preselectedCoin)
    }
    
    private func dismissTradeScreen() {
        localSearchText = ""
        resetTradeDraft()
        dismiss()
    }
    
}
