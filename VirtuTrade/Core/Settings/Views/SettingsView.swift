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
    @AppStorage(TradingSession.StorageKeys.profileID) private var profileID: String = TradingProfile.seriousInvestor.id
    @AppStorage(TradingSession.StorageKeys.cashBalance) private var simulatedCashBalance: Double = 100_000
    @EnvironmentObject private var vm: HomeViewModel
    @EnvironmentObject private var tradeHistoryStore: TradeHistoryStore
    @State private var showProfileSwitcher: Bool = false
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
                
                Section("Trading") {
                    Button {
                        showProfileSwitcher = true
                    } label: {
                        Label("Switch Trading Profile", systemImage: "person.crop.circle.badge.checkmark")
                    }
                    
                    Button(role: .destructive) {
                        showResetConfirmation = true
                    } label: {
                        Label("Reset Trading Session", systemImage: "arrow.counterclockwise")
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
            .sheet(isPresented: $showProfileSwitcher) {
                TradingProfileFlowView(
                    mode: .switchProfile,
                    initialProfile: TradingSession.currentProfile()
                ) { selectedProfile in
                    applyProfileSwitch(selectedProfile)
                } onClose: {
                    showProfileSwitcher = false
                }
            }
            .alert("Reset Trading Session?", isPresented: $showResetConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive) {
                    resetTradingSession()
                }
            } message: {
                Text("This clears holdings and trade history, then resets cash to your current profile starting balance.")
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
    private func applyProfileSwitch(_ profile: TradingProfile) {
        let resolvedBalance = TradingSession.applyProfile(profile, markOnboardingComplete: false)
        resetSandbox(to: resolvedBalance)
        showProfileSwitcher = false
    }
    
    private func resetTradingSession() {
        let resetBalance = TradingSession.startingBalance(forProfileID: profileID)
        resetSandbox(to: resetBalance)
    }
    
    private func resetSandbox(to cashBalance: Double) {
        vm.resetPortfolio()
        vm.clearPortfolioStateImmediately()
        tradeHistoryStore.clearTrades()
        simulatedCashBalance = cashBalance
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
