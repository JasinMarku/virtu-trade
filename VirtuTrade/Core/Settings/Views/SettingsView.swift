//
//  SettingsView.swift
//  VirtuTrade
//
//  Created by Jasin ‎ on 11/24/24.
//

import SwiftUI

struct SettingsView: View {
    
    @AppStorage("vt_sim_cash_balance") private var simulatedCashBalance: Double = 100_000
    @EnvironmentObject private var vm: HomeViewModel
    @State private var showResetConfirmation: Bool = false
    
    private let coinGeckoURL = URL(string: "https://www.coingecko.com")
    private let linkedInURL = URL(string: "https://www.linkedin.com/in/jasin-marku/")
    private let githubURL = URL(string: "https://github.com/JasinMarku?tab=repositories")

    private var appVersionText: String {
        let shortVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let buildVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "Version \(shortVersion) (\(buildVersion))"
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.theme.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        personalTag
                        
                        coingeckoCredit
                        
                        resetPortfolioSection

                        version
                    }
                }
            }
            .alert("Reset Portfolio?", isPresented: $showResetConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive) {
                    resetPortfolio()
                }
            } message: {
                Text("This clears all holdings and resets paper cash balance to $100,000.")
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
        .environmentObject(DeveloperPreview.instance.homeVM)
}

extension SettingsView {
    private var resetPortfolioSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Paper Trading")
                .font(.callout)
                .fontWeight(.bold)
                .foregroundStyle(Color.theme.secondaryText)
            
            Button(role: .destructive) {
                showResetConfirmation = true
            } label: {
                HStack {
                    Image(systemName: "arrow.counterclockwise")
                    Text("Reset Portfolio")
                        .fontWeight(.semibold)
                    Spacer()
                }
                .padding()
                .background(Color.theme.red.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
            }
        }
        .padding(.horizontal)
    }
    
    private func resetPortfolio() {
        vm.resetPortfolio()
        simulatedCashBalance = 100_000
    }
    
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
                    
                    if let coinGeckoURL {
                        Link(destination: coinGeckoURL, label: {
                            Text("via CoinGecko.com")
                                .fontWeight(.medium)
                        })
                    }
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
                    if let linkedInURL {
                        Link(destination: linkedInURL, label: {
                            Image("linkedin")
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 30)
                        })
                        .accessibilityLabel("LinkedIn Profile")
                    }
                    
                    if let githubURL {
                        Link(destination: githubURL, label: {
                            Image("github")
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 30)
                        })
                        .accessibilityLabel("GitHub Profile")
                    }
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
            Text(appVersionText)
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
