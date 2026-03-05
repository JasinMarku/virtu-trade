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
        return "Version \(shortVersion) (Build \(buildVersion))"
    }
    
    private var selectedThemeMode: AppThemeMode {
        AppThemeMode(rawValue: themeModeRawValue) ?? .system
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.theme.background
                    .ignoresSafeArea()
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 22) {
                        sectionHeader("Appearance")
                        appearanceCard
                        
                        sectionHeader("Accessibility")
                        accessibilityCard
                        
                        sectionHeader("Trading")
                        tradingCard
                        
                        sectionHeader("About")
                        aboutCard
                        
                        Text(appVersionText)
                            .font(.footnote)
                            .foregroundStyle(Color.theme.secondaryText.opacity(0.85))
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 2)
                            .padding(.bottom, 8)
                            .accessibilityLabel(appVersionText)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 22)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
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
    private var appearanceCard: some View {
        cardContainer {
            VStack(alignment: .leading, spacing: 14) {
                Text("Theme")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.primary)
                
                HStack(spacing: 8) {
                    ForEach(AppThemeMode.allCases) { mode in
                        Button {
                            themeModeRawValue = mode.rawValue
                        } label: {
                            Text(mode.displayName)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(selectedThemeMode == mode ? Color.white : Color.theme.secondaryText)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(
                                    Capsule(style: .continuous)
                                        .fill(selectedThemeMode == mode ? Color.theme.accent : Color.clear)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(5)
                .background(
                    Capsule(style: .continuous)
                        .fill(Color.theme.background.opacity(0.65))
                )
            }
            .padding(16)
        }
    }
    
    private var accessibilityCard: some View {
        cardContainer {
            VStack(spacing: 0) {
                toggleRow(title: "Reduce Motion", isOn: $reduceMotion)
                cardDivider
                toggleRow(title: "Haptics", isOn: $hapticsEnabled)
            }
        }
    }
    
    private var tradingCard: some View {
        cardContainer {
            VStack(spacing: 0) {
                tradingActionRow(
                    title: "Switch Trading Profile",
                    subtitle: "Change your simulated trading account type.",
                    titleColor: Color.primary
                ) {
                    showProfileSwitcher = true
                }
                
                cardDivider
                
                tradingActionRow(
                    title: "Reset Trading Session",
                    subtitle: "Clears holdings and trade history and resets your balance.",
                    titleColor: Color.theme.red
                ) {
                    showResetConfirmation = true
                }
            }
        }
    }
    
    private var aboutCard: some View {
        cardContainer {
            VStack(spacing: 0) {
                VStack(spacing: 8) {
                    Image("roundedlogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 34, height: 34)

                    
                    Text("VirtuTrade")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Color.primary)
                    
                    Text("by Jasin Marku")
                        .font(.subheadline)
                        .foregroundStyle(Color.theme.secondaryText)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                
                cardDivider
                
                VStack(spacing: 0) {
                    if let linkedInURL {
                        Link(destination: linkedInURL) {
                            aboutLinkRow(title: "Connect", iconName: "linkedin")
                        }
                        .buttonStyle(.plain)
                    }
                    
                    if linkedInURL != nil, githubURL != nil || coinGeckoURL != nil {
                        cardDivider
                    }
                    
                    if githubURL != nil, coinGeckoURL != nil {
                        cardDivider
                    }
                    
                    if let coinGeckoURL {
                        Link(destination: coinGeckoURL) {
                            aboutLinkRow(title: "Powered by CoinGecko", iconName: "cglogo", iconIsTemplate: false)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
    
    private func sectionHeader(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.caption.weight(.semibold))
            .tracking(0.7)
            .foregroundStyle(Color.theme.secondaryText.opacity(0.9))
            .padding(.horizontal, 2)
    }
    
    @ViewBuilder
    private func cardContainer<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.theme.accentBackground.opacity(0.9))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.theme.secondaryText.opacity(0.12), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.14), radius: 10, x: 0, y: 6)
    }
    
    private var cardDivider: some View {
        Rectangle()
            .fill(Color.theme.secondaryText.opacity(0.15))
            .frame(height: 1)
    }
    
    private func toggleRow(title: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color.primary)
            
            Spacer(minLength: 0)
            
            Toggle("", isOn: isOn)
                .labelsHidden()
                .toggleStyle(.switch)
                .tint(Color.theme.accent)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
    }
    
    private func tradingActionRow(title: String, subtitle: String, titleColor: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(titleColor)
                    
                    Text(subtitle)
                        .font(.body)
                        .foregroundStyle(Color.theme.secondaryText)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer(minLength: 0)
                
                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.theme.secondaryText.opacity(0.85))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
        .buttonStyle(.plain)
    }
    
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

    private func aboutLinkRow(title: String, iconName: String, iconIsTemplate: Bool = true) -> some View {
        HStack(spacing: 10) {
            Group {
                if iconIsTemplate {
                    Image(iconName)
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                } else {
                    Image(iconName)
                        .resizable()
                        .scaledToFit()
                }
            }
            .frame(width: 20, height: 20)
            
            Text(title)
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color.primary)
            
            Spacer(minLength: 0)
            
            Image(systemName: "arrow.up.right.square")
                .font(.footnote)
                .foregroundStyle(Color.theme.secondaryText.opacity(0.9))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}
