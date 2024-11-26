//
//  PortfolioView.swift
//  VirtuTrade
//
//  Created by Jasin ‎ on 10/28/24.
//

import UIKit
import SwiftUI

struct PortfolioView: View {
    
    @EnvironmentObject private var vm: HomeViewModel
    @State private var selectedCoin: CoinModel? = nil
    @State private var quantityText: String = ""
        
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    SearchBarView(searchText: $vm.searchText)
                    coinLogoList
                    
                    if selectedCoin != nil {
                        portfolioInputSection
                    }
                }
            }
            .navigationTitle("Edit Portfolio")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    XMarkButton()
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        saveButtonPressed()
                    } label: {
                        Text("Save")
                    }
                    .opacity(selectedCoin != nil &&
                             selectedCoin?.currentHoldings != Double(quantityText) ? 1.0 : 0.0
                    )
                    .font(.headline)
                }
            }
            .onChange(of: vm.searchText) {
                if vm.searchText.isEmpty {
                    removeSelectedCoin()
                }
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
    
    private func updateSelectedCoin(coin: CoinModel) {
        selectedCoin = coin
        
       if let portfolioCoin = vm.portfolioCoins.first(where: {$0.id == coin.id }),
          let amount = portfolioCoin.currentHoldings {
           quantityText = "\(amount)"
       } else {
           quantityText = ""
       }
    }
    
    private func getCurrentValue() -> Double {
        if let quantity = Double(quantityText) {
            return quantity * (selectedCoin?.currentPrice ?? 0)
        }
        return 0
    }
    
    private var portfolioInputSection: some View {
        VStack(spacing: 0) {
            // Coin Header
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
                    Text(selectedCoin?.symbol.uppercased() ?? "")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text(selectedCoin?.currentPrice.asCurrencyWith6Decimals() ?? "")
                    .font(.title3)
                    .fontWeight(.semibold)
            }
            .padding()
            .background(Color.theme.accent.opacity(0.1))
            
            // Input Section
            VStack(spacing: 15) {
                // Amount Holding
                HStack {
                    Text("Amount")
                        .foregroundColor(.secondary)
                        .fontWeight(.medium)
                        .fontDesign(.rounded)
                    
                    Spacer()
                    
                    TextField("0.00", text: $quantityText)
                        .multilineTextAlignment(.trailing)
                        .keyboardType(.decimalPad)
                        .font(.title3)
                        .foregroundColor(.primary)
                }
                .padding(.horizontal, 15)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.theme.accent.opacity(0.05))
                )
                
                // Current Value
                HStack {
                    Text("Total Value")
                        .foregroundColor(.secondary)
                        .fontWeight(.medium)
                        .fontDesign(.rounded)
                    
                    Spacer()
                    
                    Text(getCurrentValue().asCurrencyWith2Decimals())
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.theme.accent)
                }
                .padding(.horizontal, 15)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.theme.accent.opacity(0.05))
                )
            }
            .padding()
        }
        .background(
            RoundedRectangle(cornerRadius: 15)
                .stroke(Color.theme.accent.opacity(0.2), lineWidth: 1)
        )
        .padding()
        .animation(.easeInOut, value: quantityText)
    }
    
    private var trailingNavBarButtons: some View {
        HStack(spacing: 10) {
            Button(action: {
                saveButtonPressed()
            }, label: {
                Text("Save")
            }).opacity(
                selectedCoin != nil &&
                selectedCoin?.currentHoldings != Double(quantityText)
                ? 1.0 : 0.0)
        }
        .font(.headline)
    }
    
    private func saveButtonPressed() {
        guard
            let coin = selectedCoin,
            let amount = Double(quantityText)
                else { return }
        
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.prepare()
        impact.impactOccurred()
        
        vm.updatePortfolio(coin: coin, amount: amount)
        
        withAnimation(.easeIn) {
            removeSelectedCoin()
        }
        
        dismissKeyboard()
    }
    
    private func removeSelectedCoin() {
        selectedCoin = nil
        vm.searchText = ""
    }
    
}
