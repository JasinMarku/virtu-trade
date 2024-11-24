//
//  DescriptionView.swift
//  VirtuTrade
//
//  Created by Jasin ‎ on 11/24/24.
//

import SwiftUI

struct DescriptionView: View {
    let coin: CoinModel
    let description: String
    let redditURL: String?
    let websiteURL: String?
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.theme.background
                    .ignoresSafeArea()
                VStack(alignment: .leading, spacing: 15) {
                        Text("About \(coin.name)")
                            .font(.title.bold())
                            .foregroundStyle(Color.primary)
                    
                    VStack(alignment: .leading, spacing: 7) {
                            Text("Resources")
                            .font(.title3).bold()
                                .foregroundStyle(Color.primary)
                            
                        VStack(alignment: .leading) {
                            HStack(alignment: .center, spacing: 12) {
                                Image("reddit")
                                    .resizable()
                                    .renderingMode(.template)
                                    .foregroundStyle(Color.theme.accentTwo)
                                    .frame(width: 17, height: 17)
                                if let redditURL = redditURL, let url = URL(string: redditURL) {
                                    Link("Reddit", destination: url)
                                        .font(.body)
                                        .fontWeight(.medium)
                                        .foregroundStyle(Color.theme.accentTwo)
                                }
                            }
                            
                            HStack(alignment: .center, spacing: 12) {
                                Image("url")
                                    .resizable()
                                    .renderingMode(.template)
                                    .foregroundStyle(Color.theme.accentTwo)
                                    .frame(width: 17, height: 17)
                                if let websiteURL = websiteURL, let url = URL(string: websiteURL) {
                                    Link("Website", destination: url)
                                        .font(.body)
                                        .fontWeight(.medium)
                                        .foregroundStyle(Color.theme.accentTwo)
                                }
                            }
                        }
                    }
                    
                    Divider()
                    
                    Text(description)
                        .font(.body)
                        .foregroundStyle(Color.primary)
                    
                    Divider()
                    
                    Spacer()
                }
                .padding()
                .padding(.top, 15)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    XMarkButton()
                }
            }
        }
    }
}

#Preview {
    DescriptionView(
        coin: DeveloperPreview.instance.coin,
        description: "Bitcoin is a decentralized digital currency, often referred to as the first cryptocurrency. Created in 2009 by an anonymous entity known as Satoshi Nakamoto, Bitcoin operates on a peer-to-peer network that allows users to transfer value without the need for intermediaries like banks or governments. Its underlying technology, blockchain, ensures that all transactions are secure, transparent, and immutable. Unlike traditional fiat currencies, Bitcoin has a fixed supply of 21 million coins, making it inherently deflationary. This scarcity has positioned Bitcoin as a “digital gold,” appealing to investors and enthusiasts as a hedge against inflation and a store of value. Transactions are verified by miners, who solve complex cryptographic puzzles to add new blocks to the blockchain in exchange for rewards, a process known as Proof of Work. Bitcoin’s ecosystem has grown significantly, with widespread adoption in various sectors, from retail and e-commerce to financial services.",
        redditURL: "https://reddit.com/r/Bitcoin", websiteURL: "https://btc.com/")
}
