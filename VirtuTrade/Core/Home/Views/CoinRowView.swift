//
//  CoinRowView.swift
//  VirtuTrade
//
//  Created by Jasin ‎ on 10/17/24.
//

import SwiftUI

struct CoinRowView: View {
    
    let coin: CoinModel
    let showHoldingsColumn: Bool
    
    var body: some View {
        HStack(spacing: 0) {
            leftColumn
            Spacer()
            if showHoldingsColumn {
                centerColumn
            }
            rightColumn
        }
        .font(.subheadline)
        .background(Color.theme.background.opacity(0.001))
    }
}

#Preview {
    CoinRowView(coin: DeveloperPreview.instance.coin, showHoldingsColumn: true)
}


extension CoinRowView { 
    private var leftColumn: some View {
        HStack(spacing: 13) {
            Text("\(coin.rank)")
                .font(.caption)
                .foregroundStyle(Color.theme.secondaryText)
                
           CoinImageView(coin: coin)
                .frame(width: 30, height: 30)
            
            VStack(alignment: .leading, spacing: 6){
                Text(coin.symbol)
                    .font(.headline)
                    .textCase(.uppercase)
                
                Text(coin.name)
                    .font(.headline)
                    .fontWeight(.regular)
                    .foregroundStyle(Color.primary.opacity(0.7))
            }
        }
        .padding(.leading, 15)
    }
    
    private var centerColumn: some View {
        VStack(alignment: .trailing, spacing: 6) {
            Text("\(coin.currentHoldingsValue, format: .currency(code: "USD"))")
                .bold()
            Text(String(format: "%.2f", coin.currentHoldings ?? ""))
        }
        .foregroundStyle(Color.primary.opacity(0.5))
    }
    
    private var rightColumn: some View {
        VStack(alignment: .trailing, spacing: 6) {
            Text("\(coin.currentPrice, format: .currency(code: "USD"))")
                .bold()
                .foregroundStyle(Color.primary)
            
            HStack {
                Image(coin.priceChangePercentage24H ?? 0 >= 0 ? "trending-up" : "trending-down")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 13)
                    .foregroundStyle(coin.priceChangePercentage24H ?? 0 >= 0 ? Color.theme.green : Color.theme.red)

                
                Text("\(coin.priceChangePercentage24H ?? 0 >= 0 ? "+" : "")\(String(format: "%.2f", coin.priceChangePercentage24H ?? 0))%")
                    .foregroundStyle(
                        (coin.priceChangePercentage24H ?? 0) >= 0 ?
                        Color.theme.green:
                        Color.theme.red)
                    .font(.system(size: 12))
            }
            .padding(2)
            .padding(.horizontal, 3)
            .background(coin.priceChangePercentage24H ?? 0 >= 0 ? Color.theme.green.opacity(0.2) : Color.theme.red.opacity(0.2), in: RoundedRectangle(cornerRadius: 6))
        }
        .frame(width: UIScreen.main.bounds.width / 3.5, alignment: .trailing)
    }
}
