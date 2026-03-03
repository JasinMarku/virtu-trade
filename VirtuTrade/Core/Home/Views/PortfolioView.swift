//
//  PortfolioView.swift
//  VirtuTrade
//
//  Created by Jasin ‎ on 10/28/24.
//

import UIKit
import SwiftUI

struct PortfolioView: View {
    
    enum TradeSide: String, CaseIterable, Identifiable {
        case buy = "Buy"
        case sell = "Sell"
        
        var id: String { rawValue }
    }
    
    enum InputMode {
        case usd
        case coin
    }
    
    private let holdingEpsilon = 0.00000001
    
    let preselectedCoin: CoinModel?
    @AppStorage("vt_sim_cash_balance") private var cashBalance: Double = 100_000
    @EnvironmentObject private var vm: HomeViewModel
    @State private var selectedCoin: CoinModel? = nil
    @State private var tradeSide: TradeSide = .buy
    @State private var inputMode: InputMode = .usd
    @State private var tradeInputText: String = ""
    @State private var showTradeAlert: Bool = false
    @State private var tradeAlertMessage: String = ""
    
    init(preselectedCoin: CoinModel? = nil) {
        self.preselectedCoin = preselectedCoin
    }
    
    private var parsedInput: Double? {
        let trimmed = tradeInputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return Double(trimmed)
    }
    
    private var selectedCoinSymbol: String {
        selectedCoin?.symbol.uppercased() ?? "COIN"
    }
    
    private var currentPrice: Double {
        selectedCoin?.currentPrice ?? 0
    }
    
    private var currentHoldings: Double {
        selectedCoin?.currentHoldings ?? 0
    }
    
    private var tradeCoinAmount: Double {
        guard let input = parsedInput, input > 0 else { return 0 }
        switch inputMode {
        case .usd:
            guard currentPrice > 0 else { return 0 }
            return input / currentPrice
        case .coin:
            return input
        }
    }
    
    private var tradeUSDValue: Double {
        guard let input = parsedInput, input > 0 else { return 0 }
        switch inputMode {
        case .usd:
            return input
        case .coin:
            return input * currentPrice
        }
    }
    
    private var projectedCashBalance: Double {
        switch tradeSide {
        case .buy:
            return cashBalance - tradeUSDValue
        case .sell:
            return cashBalance + tradeUSDValue
        }
    }
    
    private var validationMessage: String? {
        guard selectedCoin != nil else {
            return "Select a coin to trade."
        }
        
        guard let input = parsedInput, input > 0 else {
            return "Enter a valid trade amount."
        }
        
        guard currentPrice > 0 else {
            return "Price is unavailable. Try again in a moment."
        }
        
        guard tradeCoinAmount > 0, tradeUSDValue > 0 else {
            return "Trade amount must be greater than zero."
        }
        
        switch tradeSide {
        case .buy:
            guard tradeUSDValue <= cashBalance + holdingEpsilon else {
                return "Insufficient cash balance for this buy."
            }
        case .sell:
            guard currentHoldings > holdingEpsilon else {
                return "You do not have holdings to sell."
            }
            guard tradeCoinAmount <= currentHoldings + holdingEpsilon else {
                return "Insufficient holdings for this sell."
            }
        }
        
        return nil
    }
    
    private var isTradeValid: Bool {
        validationMessage == nil
    }
        
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    SearchBarView(searchText: $vm.searchText)
                    coinLogoList
                    
                    if selectedCoin != nil {
                        tradeSection
                    }
                }
            }
            .navigationTitle("Trade")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    XMarkButton()
                }
            }
            .onChange(of: vm.searchText) { _, newValue in
                if newValue.isEmpty {
                    removeSelectedCoin()
                }
            }
            .onAppear {
                applyPreselectedCoinIfNeeded()
            }
            .onChange(of: preselectedCoin?.id) { _, _ in
                applyPreselectedCoinIfNeeded()
            }
            .alert("Trade Error", isPresented: $showTradeAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(tradeAlertMessage)
            }
        }
        .background(.clear)
    }
}

#Preview {
    PortfolioView()
        .environmentObject(DeveloperPreview.instance.homeVM)
}

extension PortfolioView {
    
    private var coinLogoList: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 10) {
                ForEach(vm.searchText.isEmpty ? vm.portfolioCoins : vm.allCoins) { coin in
                    CoinLogoView(coin: coin)
                        .padding(.vertical, 6)
                        .frame(width: 75)
                        .onTapGesture {
                            withAnimation(.easeIn) {
                                updateSelectedCoin(coin: coin)
                            }
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(selectedCoin?.id == coin.id ? Color.theme.green.opacity(0.2) : Color.clear)
                        )
                }
            }
            .frame(height: 120)
            .padding(.leading)
        }
    }
    
    private var tradeSection: some View {
        VStack(spacing: 14) {
            coinHeader
            
            Picker("Trade Side", selection: $tradeSide) {
                ForEach(TradeSide.allCases) { side in
                    Text(side.rawValue).tag(side)
                }
            }
            .pickerStyle(.segmented)
            
            HStack(spacing: 12) {
                tradeInfoCard(title: "Cash Balance", value: cashBalance.asCurrencyWith2Decimals(), color: Color.theme.accent)
                tradeInfoCard(
                    title: "Holdings",
                    value: "\(formattedCoinAmount(currentHoldings)) \(selectedCoinSymbol)",
                    color: Color.primary
                )
            }
            
            tradeInputCard
            tradePreviewCard
            
            if let validationMessage, !tradeInputText.isEmpty {
                Text(validationMessage)
                    .font(.footnote)
                    .foregroundStyle(Color.theme.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            Button {
                confirmTrade()
            } label: {
                Text(tradeSide == .buy ? "Confirm Buy" : "Confirm Sell")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(tradeSide == .buy ? Color.theme.green : Color.theme.red, in: RoundedRectangle(cornerRadius: 12))
                    .foregroundStyle(.white)
            }
            .disabled(!isTradeValid)
            .opacity(isTradeValid ? 1.0 : 0.45)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.theme.accent.opacity(0.2), lineWidth: 1)
        )
        .padding()
        .animation(.easeInOut, value: tradeInputText)
        .animation(.easeInOut, value: tradeSide)
    }
    
    private var coinHeader: some View {
        HStack {
            AsyncImage(url: URL(string: selectedCoin?.image ?? "")) { image in
                image.resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 40, height: 40)
            } placeholder: {
                Color.gray.opacity(0.2)
            }
            .frame(width: 40, height: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(selectedCoin?.name ?? "")
                    .font(.headline)
                Text(selectedCoinSymbol)
                    .font(.subheadline)
                    .foregroundStyle(Color.theme.secondaryText)
            }
            
            Spacer()
            
            Text(currentPrice.asCurrencyWithAdaptiveDecimals())
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(Color.primary)
        }
    }
    
    private var tradeInputCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(inputMode == .usd ? "Trade Amount (USD)" : "Trade Quantity (\(selectedCoinSymbol))")
                .font(.caption)
                .foregroundStyle(Color.theme.secondaryText)
            
            TextField(inputMode == .usd ? "0.00" : "0.000000", text: $tradeInputText)
                .keyboardType(.decimalPad)
                .font(.title3)
                .fontWeight(.semibold)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
            
            Button {
                toggleInputMode()
            } label: {
                Text("Switch to \(inputMode == .usd ? "COIN" : "USD")")
                    .font(.subheadline)
                    .foregroundStyle(Color.theme.accent)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.theme.accent.opacity(0.05))
        )
    }
    
    private var tradePreviewCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Preview")
                .font(.caption)
                .foregroundStyle(Color.theme.secondaryText)
            
            if tradeCoinAmount > 0, tradeUSDValue > 0, selectedCoin != nil {
                Text(
                    "You will \(tradeSide.rawValue.lowercased()) \(formattedCoinAmount(tradeCoinAmount)) " +
                    "\(selectedCoinSymbol) for \(tradeUSDValue.asCurrencyWith2Decimals())"
                )
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(Color.primary)
                
                Text("Cash after trade: \(max(projectedCashBalance, 0).asCurrencyWith2Decimals())")
                    .font(.footnote)
                    .foregroundStyle(Color.theme.secondaryText)
            } else {
                Text("Enter a trade amount to see the estimate.")
                    .font(.footnote)
                    .foregroundStyle(Color.theme.secondaryText)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.theme.accent.opacity(0.05))
        )
    }
    
    private func tradeInfoCard(title: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(Color.theme.secondaryText)
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(color)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.theme.accent.opacity(0.05))
        )
    }
    
    private func updateSelectedCoin(coin: CoinModel) {
        selectedCoin = coin
        tradeInputText = ""
    }
    
    private func confirmTrade() {
        guard let coin = selectedCoin else { return }
        
        guard isTradeValid else {
            tradeAlertMessage = validationMessage ?? "Unable to complete this trade."
            showTradeAlert = true
            return
        }
        
        let coinAmount = tradeCoinAmount
        let usdValue = tradeUSDValue
        
        let updatedHoldings: Double
        switch tradeSide {
        case .buy:
            updatedHoldings = currentHoldings + coinAmount
            cashBalance = max(cashBalance - usdValue, 0)
        case .sell:
            updatedHoldings = max(currentHoldings - coinAmount, 0)
            cashBalance += usdValue
        }
        
        let normalizedHoldings = updatedHoldings <= holdingEpsilon ? 0 : updatedHoldings
        vm.updatePortfolio(coin: coin, amount: normalizedHoldings)
        selectedCoin = coin.updateHoldings(amount: normalizedHoldings)
        
        tradeInputText = ""
        dismissKeyboard()
        
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.prepare()
        impact.impactOccurred()
    }
    
    private func toggleInputMode() {
        let nextMode: InputMode = inputMode == .usd ? .coin : .usd
        
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
    
    private func formattedInputValue(_ value: Double, mode: InputMode) -> String {
        switch mode {
        case .usd:
            return String(format: "%.2f", value)
        case .coin:
            return String(format: "%.6f", value)
        }
    }
    
    private func formattedCoinAmount(_ value: Double) -> String {
        let fixed = String(format: "%.6f", value)
        return fixed
            .replacingOccurrences(of: #"([0-9])0+$"#, with: "$1", options: .regularExpression)
            .replacingOccurrences(of: #"\.$"#, with: "", options: .regularExpression)
    }
    
    private func removeSelectedCoin() {
        selectedCoin = nil
        vm.searchText = ""
    }
    
    private func applyPreselectedCoinIfNeeded() {
        guard let preselectedCoin else { return }
        updateSelectedCoin(coin: preselectedCoin)
    }
    
}
