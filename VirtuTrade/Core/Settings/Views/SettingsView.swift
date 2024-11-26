//
//  SettingsView.swift
//  VirtuTrade
//
//  Created by Jasin ‎ on 11/24/24.
//

import SwiftUI

struct SettingsView: View {
    
    let coingeckoURL = URL(string: "https://www.coingecko.com")!
    let repositoryURL = URL(string: "https://github.com/JasinMarku/virtu-trade")
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.theme.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        personalTag
                        
                        coingeckoCredit

                        version
                    }
                }
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
    SettingsView()
}

extension SettingsView {
    private var coingeckoCredit: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image("cglogo")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 72)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(color: Color("Gecko"), radius: 6)

                
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Powered By CoinGecko")
                        .font(.callout)
                        .fontWeight(.bold)
                    
                    Link(destination: URL(string: "https://www.coingecko.com")!, label: {
                        Text("via CoinGecko.com")
                            .fontWeight(.medium)
                    })
                }
                .foregroundStyle(Color.theme.secondaryText)
            }

            
            Text("This app integrates the CoinGecko API, delivering precise and real-time cryptocurrency data. From market trends and historical price charts to in-depth information about various cryptocurrencies, CoinGecko has been instrumental in enabling the seamless functionality of this project. Their reliable and expansive platform provides access to a wealth of data that powers the analytics and insights offered in this app.")
                .font(.body)
                .fontWeight(.medium)
            
            Spacer()
        }
        .padding()
        .background(.gray.opacity(0.15), in: RoundedRectangle(cornerRadius: 25))
        .padding(.horizontal)
    }
    
    private var personalTag: some View {
        HStack(spacing: 15) {
                Image("logo")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 72)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(color: Color.theme.accentTwo, radius: 10)
                
                VStack(alignment: .leading) {
                    Text("Developer")
                        .font(.callout)
                        .fontWeight(.bold)
                    
                    Text("Jasin Marku")
                        .fontWeight(.medium)
                }
                .foregroundStyle(Color.theme.secondaryText)
                
                
                Spacer()
                
                HStack(spacing: 20) {
                    Link(destination: URL(string: "https://www.linkedin.com/in/jasin-marku/")!, label: {
                        Image("linkedin")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 30)
                    })
                    
                    Link(destination: URL(string: "https://github.com/JasinMarku?tab=repositories")!, label: {
                        Image("github")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 30)
                    })
                }
                .padding(.trailing, 15)
            }
            .padding()
            .padding(.vertical, 10)
            .background(.gray.opacity(0.15), in: RoundedRectangle(cornerRadius: 25))
            .padding(.horizontal)
    }
    
    private var version: some View {
        HStack {
            Text("Version 1.0")
                .foregroundStyle(Color.theme.secondaryText)
                .font(.body)
                .fontWeight(.medium)
            
            Image("logo")
                .resizable()
                .scaledToFit()
                .frame(width: 20)
                .clipShape(RoundedRectangle(cornerRadius: 5))
        }
    }
}
