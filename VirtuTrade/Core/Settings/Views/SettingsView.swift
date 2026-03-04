//
//  SettingsView.swift
//  VirtuTrade
//
//  Created by Jasin ‎ on 11/24/24.
//

import SwiftUI

struct SettingsView: View {
    
    @AppStorage("vt_theme_mode") private var themeModeRawValue: String = AppThemeMode.system.rawValue
    @AppStorage("vt_reduce_motion") private var reduceMotion: Bool = false
    @AppStorage("vt_haptics_enabled") private var hapticsEnabled: Bool = true
    @AppStorage("vt_sim_cash_balance") private var simulatedCashBalance: Double = 100_000
    @EnvironmentObject private var vm: HomeViewModel
    @EnvironmentObject private var tradeHistoryStore: TradeHistoryStore
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
            List {
                Section("Appearance") {
                    Picker("Theme", selection: Binding<AppThemeMode>(
                        get: { AppThemeMode(rawValue: themeModeRawValue) ?? .system },
                        set: { themeModeRawValue = $0.rawValue }
                    )) {
                        ForEach(AppThemeMode.allCases) { mode in
                            Text(mode.displayName).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section("Accessibility") {
                    Toggle("Reduce Motion", isOn: $reduceMotion)
                    Toggle("Haptics", isOn: $hapticsEnabled)
                }
                
                Section("Portfolio") {
                    Button(role: .destructive) {
                        showResetConfirmation = true
                    } label: {
                        Label("Reset Portfolio", systemImage: "arrow.counterclockwise")
                    }
                }
                
                Section("About") {
                    aboutDeveloperRow
                    
                    if let linkedInURL {
                        Link(destination: linkedInURL) {
                            aboutLinkRow(title: "LinkedIn", iconName: "linkedin")
                        }
                    }
                    
                    if let githubURL {
                        Link(destination: githubURL) {
                            aboutLinkRow(title: "GitHub", iconName: "github")
                        }
                    }
                    
                    if let coinGeckoURL {
                        Link(destination: coinGeckoURL) {
                            HStack(spacing: 10) {
                                Image("cglogo")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 24, height: 24)
                                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                                Text("Powered by CoinGecko")
                                Spacer()
                                Image(systemName: "arrow.up.right.square")
                                    .font(.footnote)
                                    .foregroundStyle(Color.theme.secondaryText)
                            }
                        }
                    }
                    
                    Text(appVersionText)
                        .font(.footnote)
                        .foregroundStyle(Color.theme.secondaryText)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.theme.background.ignoresSafeArea())
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
        .environmentObject(TradeHistoryStore())
}

extension SettingsView {
    private func resetPortfolio() {
        vm.resetPortfolio()
        tradeHistoryStore.clearTrades()
        simulatedCashBalance = 100_000
    }
    
    private var aboutDeveloperRow: some View {
        HStack(spacing: 12) {
            Image("logo")
                .resizable()
                .scaledToFit()
                .frame(width: 28, height: 28)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Developer")
                    .font(.caption)
                    .foregroundStyle(Color.theme.secondaryText)
                Text("Jasin Marku")
                    .font(.subheadline)
            }
            
            Spacer()
        }
    }
    
    private func aboutLinkRow(title: String, iconName: String) -> some View {
        HStack(spacing: 10) {
            Image(iconName)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 18, height: 18)
            Text(title)
            Spacer()
            Image(systemName: "arrow.up.right.square")
                .font(.footnote)
                .foregroundStyle(Color.theme.secondaryText)
        }
    }
}
