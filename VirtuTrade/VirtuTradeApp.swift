//
//  VirtuTradeApp.swift
//  VirtuTrade
//
//  Created by Jasin ‎ on 10/17/24.
//

import SwiftUI
import UIKit

struct TradingProfile: Identifiable, Hashable {
    let id: String
    let title: String
    let startingBalance: Double?
    let shortDescription: String
    
    static let student = TradingProfile(
        id: "student",
        title: "Student",
        startingBalance: 2_500,
        shortDescription: "Start small and learn safely."
    )
    static let sideHustle = TradingProfile(
        id: "side_hustle",
        title: "Side Hustle",
        startingBalance: 15_000,
        shortDescription: "Grow steadily after work."
    )
    static let activeTrader = TradingProfile(
        id: "active_trader",
        title: "Active Trader",
        startingBalance: 50_000,
        shortDescription: "Trade frequently with discipline."
    )
    static let seriousInvestor = TradingProfile(
        id: "serious_investor",
        title: "Serious Investor",
        startingBalance: 100_000,
        shortDescription: "Balanced size for strategy testing."
    )
    static let highRoller = TradingProfile(
        id: "high_roller",
        title: "High Roller",
        startingBalance: 1_000_000,
        shortDescription: "Simulate larger risk exposure."
    )
    static let custom = TradingProfile(
        id: "custom",
        title: "Custom",
        startingBalance: nil,
        shortDescription: "Choose your own balance."
    )
    
    static let presets: [TradingProfile] = [
        .student,
        .sideHustle,
        .activeTrader,
        .seriousInvestor,
        .highRoller
    ]
    
    static func custom(amount: Double) -> TradingProfile {
        TradingProfile(
            id: custom.id,
            title: custom.title,
            startingBalance: amount,
            shortDescription: custom.shortDescription
        )
    }
}

enum TradingSession {
    enum StorageKeys {
        static let profileID = "vt_profile_id"
        static let cashBalance = "vt_sim_cash_balance"
        static let customProfileBalance = "vt_profile_custom_balance"
        static let hasCompletedOnboarding = "vt_has_completed_onboarding"
    }
    
    static let minCustomBalance: Double = 100
    static let maxCustomBalance: Double = 1_000_000
    
    static func initializeIfNeeded(defaults: UserDefaults = .standard) {
        guard defaults.bool(forKey: StorageKeys.hasCompletedOnboarding) == false else {
            return
        }
        
        defaults.set(TradingProfile.seriousInvestor.id, forKey: StorageKeys.profileID)
        defaults.set(TradingProfile.seriousInvestor.startingBalance ?? 100_000, forKey: StorageKeys.cashBalance)
        
        if defaults.object(forKey: StorageKeys.hasCompletedOnboarding) == nil {
            defaults.set(false, forKey: StorageKeys.hasCompletedOnboarding)
        }
    }
    
    static func currentProfile(defaults: UserDefaults = .standard) -> TradingProfile {
        profile(for: defaults.string(forKey: StorageKeys.profileID) ?? TradingProfile.seriousInvestor.id, defaults: defaults)
    }
    
    static func profile(for profileID: String, defaults: UserDefaults = .standard) -> TradingProfile {
        if profileID == TradingProfile.custom.id {
            let customBalance: Double
            if defaults.object(forKey: StorageKeys.customProfileBalance) != nil {
                customBalance = defaults.double(forKey: StorageKeys.customProfileBalance)
            } else if defaults.object(forKey: StorageKeys.cashBalance) != nil {
                customBalance = defaults.double(forKey: StorageKeys.cashBalance)
            } else {
                customBalance = TradingProfile.seriousInvestor.startingBalance ?? 100_000
            }
            
            return TradingProfile.custom(amount: clampCustomBalance(customBalance))
        }
        
        return TradingProfile.presets.first(where: { $0.id == profileID }) ?? TradingProfile.seriousInvestor
    }
    
    static func startingBalance(forProfileID profileID: String, defaults: UserDefaults = .standard) -> Double {
        profile(for: profileID, defaults: defaults).startingBalance ?? (TradingProfile.seriousInvestor.startingBalance ?? 100_000)
    }
    
    @discardableResult
    static func applyProfile(_ profile: TradingProfile, markOnboardingComplete: Bool, defaults: UserDefaults = .standard) -> Double {
        let resolvedBalance: Double
        
        if profile.id == TradingProfile.custom.id {
            resolvedBalance = clampCustomBalance(profile.startingBalance ?? defaults.double(forKey: StorageKeys.cashBalance))
            defaults.set(resolvedBalance, forKey: StorageKeys.customProfileBalance)
        } else {
            resolvedBalance = profile.startingBalance ?? (TradingProfile.seriousInvestor.startingBalance ?? 100_000)
        }
        
        defaults.set(profile.id, forKey: StorageKeys.profileID)
        defaults.set(resolvedBalance, forKey: StorageKeys.cashBalance)
        
        if markOnboardingComplete {
            defaults.set(true, forKey: StorageKeys.hasCompletedOnboarding)
        }
        
        return resolvedBalance
    }
    
    private static func clampCustomBalance(_ value: Double) -> Double {
        min(max(value, minCustomBalance), maxCustomBalance)
    }
}

enum AppThemeMode: String, CaseIterable, Identifiable {
    case system
    case light
    case dark
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .system:
            return "System"
        case .light:
            return "Light"
        case .dark:
            return "Dark"
        }
    }
    
    var colorScheme: ColorScheme? {
        switch self {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}

enum AppTab: Hashable {
    case home
    case portfolio
    case news
}

enum AppHaptics {
    private static let enabledKey = "vt_haptics_enabled"
    
    static var isEnabled: Bool {
        let defaults = UserDefaults.standard
        guard defaults.object(forKey: enabledKey) != nil else {
            return true
        }
        return defaults.bool(forKey: enabledKey)
    }
    
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        guard isEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
    
    static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        guard isEnabled else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }
}

private enum OnboardingPalette {
    static let textPrimary = Color.primary
    static let textSecondary = Color.theme.secondaryText
    static let textMuted = Color.theme.secondaryText.opacity(0.72)
    static let cardBackground = Color.theme.accentBackground.opacity(0.9)
    static let cardBorder = Color.theme.secondaryText.opacity(0.16)
    static let selectedCardBackground = Color.theme.accent.opacity(0.14)
    static let chipBackground = Color.theme.secondaryText.opacity(0.12)
}

struct PrimaryButtonStyle: ButtonStyle {
    var isDisabled: Bool = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isDisabled ? Color.theme.accent.opacity(0.35) : Color.theme.accent)
            )
            .opacity(configuration.isPressed ? 0.9 : 1)
            .scaleEffect(configuration.isPressed ? 0.99 : 1)
            .animation(.easeOut(duration: 0.16), value: configuration.isPressed)
    }
}

struct OnboardingCardStyle: ViewModifier {
    let isSelected: Bool
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(isSelected ? OnboardingPalette.selectedCardBackground : OnboardingPalette.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(isSelected ? Color.theme.accent : OnboardingPalette.cardBorder, lineWidth: isSelected ? 1.6 : 1)
            )
            .shadow(color: isSelected ? Color.theme.accent.opacity(0.16) : .clear, radius: 10, x: 0, y: 4)
    }
}

struct OnboardingBackgroundView: View {
    var body: some View {
        Color.theme.background
            .ignoresSafeArea()
    }
}

struct OnboardingProgressView: View {
    let currentStep: Int
    let totalSteps: Int
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(1...totalSteps, id: \.self) { step in
                Capsule(style: .continuous)
                    .fill(step <= currentStep ? Color.theme.accent : Color.theme.secondaryText.opacity(0.25))
                    .frame(width: step == currentStep ? 28 : 18, height: 6)
            }
        }
    }
}

private struct OnboardingSparklineShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let points: [CGPoint] = [
            CGPoint(x: rect.minX, y: rect.maxY * 0.72),
            CGPoint(x: rect.maxX * 0.14, y: rect.maxY * 0.68),
            CGPoint(x: rect.maxX * 0.27, y: rect.maxY * 0.63),
            CGPoint(x: rect.maxX * 0.42, y: rect.maxY * 0.66),
            CGPoint(x: rect.maxX * 0.58, y: rect.maxY * 0.53),
            CGPoint(x: rect.maxX * 0.71, y: rect.maxY * 0.56),
            CGPoint(x: rect.maxX * 0.86, y: rect.maxY * 0.4),
            CGPoint(x: rect.maxX, y: rect.maxY * 0.44)
        ]
        
        guard let firstPoint = points.first else { return path }
        path.move(to: firstPoint)
        
        for point in points.dropFirst() {
            path.addLine(to: point)
        }
        
        return path
    }
}

private extension TradingProfile {
    var iconName: String {
        switch id {
        case TradingProfile.student.id:
            return "graduationcap.fill"
        case TradingProfile.sideHustle.id:
            return "briefcase.fill"
        case TradingProfile.activeTrader.id:
            return "bolt.fill"
        case TradingProfile.seriousInvestor.id:
            return "chart.line.uptrend.xyaxis"
        case TradingProfile.highRoller.id:
            return "crown.fill"
        default:
            return "person.crop.circle"
        }
    }
}

private enum TradingProfileFlowStep {
    case welcome
    case profileSelection
    case confirmation
}

struct TradingProfileFlowView: View {
    enum Mode {
        case onboarding
        case switchProfile
    }
    
    let mode: Mode
    let onComplete: (TradingProfile) -> Void
    let onClose: (() -> Void)?
    
    @FocusState private var isCustomAmountFocused: Bool
    @State private var step: TradingProfileFlowStep
    @State private var selectedPresetID: String?
    @State private var isCustomSelected: Bool = false
    @State private var customAmountText: String = "100000"
    @State private var confirmedProfile: TradingProfile?
    
    init(
        mode: Mode,
        initialProfile: TradingProfile? = nil,
        onComplete: @escaping (TradingProfile) -> Void,
        onClose: (() -> Void)? = nil
    ) {
        self.mode = mode
        self.onComplete = onComplete
        self.onClose = onClose
        _step = State(initialValue: mode == .onboarding ? .welcome : .profileSelection)
        
        if let initialProfile {
            if initialProfile.id == TradingProfile.custom.id {
                _selectedPresetID = State(initialValue: nil)
                _isCustomSelected = State(initialValue: true)
                _customAmountText = State(initialValue: String(format: "%.0f", initialProfile.startingBalance ?? 100_000))
            } else {
                _selectedPresetID = State(initialValue: initialProfile.id)
                _isCustomSelected = State(initialValue: false)
            }
            _confirmedProfile = State(initialValue: initialProfile)
        }
    }
    
    private var selectedPresetProfile: TradingProfile? {
        TradingProfile.presets.first(where: { $0.id == selectedPresetID })
    }
    
    private var parsedCustomAmount: Double? {
        let sanitized = customAmountText.replacingOccurrences(of: ",", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return Double(sanitized)
    }
    
    private var validatedCustomAmount: Double? {
        guard let parsedCustomAmount else { return nil }
        guard parsedCustomAmount >= TradingSession.minCustomBalance, parsedCustomAmount <= TradingSession.maxCustomBalance else { return nil }
        return parsedCustomAmount
    }
    
    private var selectedProfile: TradingProfile? {
        if isCustomSelected {
            guard let validatedCustomAmount else { return nil }
            return TradingProfile.custom(amount: validatedCustomAmount)
        }
        
        return selectedPresetProfile
    }
    
    private var canContinueFromProfileSelection: Bool {
        selectedProfile != nil
    }
    
    private var confirmationProfile: TradingProfile? {
        confirmedProfile ?? selectedProfile
    }
    
    var body: some View {
        ZStack {
            OnboardingBackgroundView()
            
            VStack(spacing: 0) {
                switch step {
                case .welcome:
                    welcomeScreen
                case .profileSelection:
                    profileSelectionScreen
                case .confirmation:
                    confirmationScreen
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 32)
            .padding(.bottom, 24)
        }
    }
}

private extension TradingProfileFlowView {
    var currentStep: Int {
        switch step {
        case .welcome:
            return 1
        case .profileSelection:
            return 2
        case .confirmation:
            return 3
        }
    }
    
    var welcomeScreen: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image("logo")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .shadow(color: Color.theme.accent.opacity(0.35), radius: 24, x: 0, y: 10)
            
            VStack(spacing: 4) {
                Text("Welcome to")
                    .font(.system(size: 50, weight: .bold, design: .rounded))
                    .foregroundStyle(OnboardingPalette.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
                
                Text("VirtuTrade")
                    .font(.system(size: 50, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.theme.accent)
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
            }
            
            Text("Track real market prices and practice simulated trades with virtual USD.")
                .font(.title3)
                .multilineTextAlignment(.center)
                .foregroundStyle(OnboardingPalette.textSecondary)
                .padding(.top, 4)
                .padding(.horizontal, 8)
            
            Spacer()
            
            Button(action: moveToProfileSelection) {
                Text("Continue")
            }
            .buttonStyle(PrimaryButtonStyle())
            
            Text("This is a simulated trading environment using virtual USD. No real cryptocurrency is bought, sold, or stored.")
                .font(.caption2)
                .multilineTextAlignment(.center)
                .foregroundStyle(OnboardingPalette.textMuted)
                .padding(.horizontal, 6)
                .padding(.bottom, 4)
        }
    }
    
    var profileSelectionScreen: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 14) {
                Button(action: moveBackFromProfileSelection) {
                    Image(systemName: "chevron.left")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(OnboardingPalette.textPrimary)
                        .frame(width: 34, height: 34)
                        .background(OnboardingPalette.chipBackground, in: Circle())
                }
                .buttonStyle(.plain)
                
                OnboardingProgressView(currentStep: currentStep, totalSteps: 3)
                
                Spacer()
                
                if mode == .switchProfile, let onClose {
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(OnboardingPalette.textPrimary)
                            .frame(width: 30, height: 30)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            Text("Choose your simulated trading profile.")
                .font(.system(size: 42, weight: .bold, design: .rounded))
                .foregroundStyle(OnboardingPalette.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            
            Text("Choose a starting profile. Your virtual USD balance can mirror real-life scenarios.")
                .font(.title3)
                .foregroundStyle(OnboardingPalette.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 12) {
                    ForEach(TradingProfile.presets) { profile in
                        profileCard(for: profile)
                    }
                }
                .padding(.top, 4)
            }
            
            Button(action: moveToConfirmation) {
                Text("Select Profile")
            }
            .buttonStyle(PrimaryButtonStyle(isDisabled: !canContinueFromProfileSelection))
            .disabled(!canContinueFromProfileSelection)
            
            VStack(alignment: .center, spacing: 10) {
                Button {
                    AppHaptics.impact(.light)
                    isCustomSelected = true
                    selectedPresetID = nil
                    isCustomAmountFocused = true
                } label: {
                    Text("Custom Amount")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.theme.accent.opacity(0.95))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
                
                if isCustomSelected {
                    customAmountSection
                        .transition(.opacity)
                }
            }
            .padding(.bottom, 4)
        }
    }
    
    func profileCard(for profile: TradingProfile) -> some View {
        let isSelected = !isCustomSelected && selectedPresetID == profile.id
        
        return Button {
            AppHaptics.impact(.light)
            selectedPresetID = profile.id
            isCustomSelected = false
            isCustomAmountFocused = false
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(OnboardingPalette.chipBackground)
                    Image(systemName: profile.iconName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(OnboardingPalette.textPrimary)
                }
                .frame(width: 38, height: 38)
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(profile.title)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(OnboardingPalette.textPrimary)
                    
                    Text(profile.shortDescription)
                        .font(.subheadline)
                        .foregroundStyle(OnboardingPalette.textSecondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer(minLength: 10)
                
                VStack(alignment: .trailing, spacing: 8) {
                    Text((profile.startingBalance ?? 0).asCurrencyWith2Decimals())
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(Color.theme.accent)
                    
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.headline)
                        .foregroundStyle(isSelected ? Color.theme.accent : OnboardingPalette.textSecondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity, minHeight: 110, alignment: .leading)
            .modifier(OnboardingCardStyle(isSelected: isSelected))
        }
        .buttonStyle(.plain)
    }
    
    var customAmountSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Custom Amount")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(OnboardingPalette.textPrimary)
                Spacer()
                Button {
                    AppHaptics.impact(.light)
                    isCustomAmountFocused = false
                    isCustomSelected = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(OnboardingPalette.textSecondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Dismiss custom amount")
            }
            
            Text("Enter amount (\(Int(TradingSession.minCustomBalance).formatted()) - \(Int(TradingSession.maxCustomBalance).formatted()))")
                .font(.caption)
                .foregroundStyle(OnboardingPalette.textSecondary)
            
            TextField("100000", text: $customAmountText)
                .keyboardType(.numberPad)
                .focused($isCustomAmountFocused)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
                .font(.title2.weight(.semibold))
                .foregroundStyle(OnboardingPalette.textPrimary)
                .padding(.horizontal, 2)
                .padding(.vertical, 6)
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .fill(validatedCustomAmount != nil || customAmountText.isEmpty ? Color.theme.accent.opacity(0.8) : Color.theme.red)
                        .frame(height: 1.5)
                }
            
            if let validatedCustomAmount {
                Text("Starting balance: \(validatedCustomAmount.asCurrencyWith2Decimals())")
                    .font(.caption)
                    .foregroundStyle(OnboardingPalette.textSecondary)
            } else if !customAmountText.isEmpty {
                Text("Enter a value between \(TradingSession.minCustomBalance.asCurrencyWith2Decimals()) and \(TradingSession.maxCustomBalance.asCurrencyWith2Decimals()).")
                    .font(.caption)
                    .foregroundStyle(Color.theme.red)
            }
        }
        .padding(14)
        .modifier(OnboardingCardStyle(isSelected: validatedCustomAmount != nil))
    }
    
    var confirmationScreen: some View {
        VStack(alignment: .leading, spacing: 18) {
            OnboardingProgressView(currentStep: currentStep, totalSteps: 3)
                .padding(.bottom, 4)
            
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64, weight: .semibold))
                .foregroundStyle(Color.theme.green)
                .shadow(color: Color.theme.green.opacity(0.28), radius: 16, x: 0, y: 8)
            
            Text("You're ready to simulate")
                .font(.system(size: 46, weight: .bold, design: .rounded))
                .foregroundStyle(OnboardingPalette.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            
            if let confirmationProfile, let startingBalance = confirmationProfile.startingBalance {
                Text("You're using the \(confirmationProfile.title) profile with \(startingBalance.asCurrencyWith2Decimals()) in virtual USD.")
                    .font(.title3)
                    .foregroundStyle(OnboardingPalette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                
                totalBalanceCard(balance: startingBalance)
            } else {
                Text("Select a profile to continue.")
                    .font(.title3)
                    .foregroundStyle(OnboardingPalette.textSecondary)
            }
            
            Spacer(minLength: 16)
            
            Button(action: completeFlow) {
                Text(mode == .onboarding ? "Launch Simulator →" : "Switch Profile →")
            }
            .buttonStyle(PrimaryButtonStyle(isDisabled: confirmationProfile == nil))
            .disabled(confirmationProfile == nil)
            
            Button(action: moveBackToProfileSelection) {
                Text("Change Profile")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(OnboardingPalette.textSecondary)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.plain)
        }
    }
    
    @ViewBuilder
    func totalBalanceCard(balance: Double) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Text("TOTAL BALANCE")
                    .font(.caption2.weight(.semibold))
                    .tracking(0.8)
                    .foregroundStyle(OnboardingPalette.textMuted)
                Spacer()
                Text("+0.00%")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.theme.green)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(
                        Capsule(style: .continuous)
                            .fill(Color.theme.green.opacity(0.2))
                    )
            }
            
            Text(balance.asCurrencyWith2Decimals())
                .font(.system(size: 45, weight: .bold, design: .rounded))
                .foregroundStyle(OnboardingPalette.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            
            OnboardingSparklineShape()
                .stroke(
                    Color.theme.accent.opacity(0.9),
                    style: StrokeStyle(lineWidth: 2.6, lineCap: .round, lineJoin: .round)
                )
                .frame(height: 56)
                .padding(.top, 4)
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .fill(Color.theme.accent.opacity(0.12))
                        .frame(height: 32)
                        .blur(radius: 10)
                }
                .clipped()
        }
        .padding(18)
        .modifier(OnboardingCardStyle(isSelected: false))
    }

    func moveToProfileSelection() {
        AppHaptics.impact(.light)
        withAnimation(.easeInOut(duration: 0.22)) {
            step = .profileSelection
        }
    }
    
    func moveBackFromProfileSelection() {
        AppHaptics.impact(.light)
        if mode == .onboarding {
            withAnimation(.easeInOut(duration: 0.22)) {
                step = .welcome
            }
        } else {
            onClose?()
        }
    }
    
    func moveToConfirmation() {
        guard let selectedProfile else { return }
        confirmedProfile = selectedProfile
        AppHaptics.impact(.light)
        withAnimation(.easeInOut(duration: 0.22)) {
            step = .confirmation
        }
    }
    
    func moveBackToProfileSelection() {
        AppHaptics.impact(.light)
        withAnimation(.easeInOut(duration: 0.22)) {
            step = .profileSelection
        }
    }
    
    func completeFlow() {
        guard let profile = confirmationProfile else { return }
        onComplete(profile)
        AppHaptics.notification(.success)
    }
}

@main
struct VirtuTradeApp: App {
    @StateObject private var vm = HomeViewModel()
    @StateObject private var newsService = NewsService()
    @StateObject private var watchlistStore = WatchlistStore()
    @StateObject private var tradeHistoryStore = TradeHistoryStore()
    @State private var selectedTab: AppTab = .home
    @State private var showLaunchView: Bool = true
    @AppStorage(TradingSession.StorageKeys.profileID) private var profileID: String = TradingProfile.seriousInvestor.id
    @AppStorage(TradingSession.StorageKeys.cashBalance) private var simCashBalance: Double = 100_000
    @AppStorage(TradingSession.StorageKeys.hasCompletedOnboarding) private var hasCompletedOnboarding: Bool = false
    @AppStorage("vt_theme_mode") private var themeModeRawValue: String = AppThemeMode.system.rawValue
    @AppStorage("vt_reduce_motion") private var reduceMotion: Bool = false
    
    init() {
        TradingSession.initializeIfNeeded()
        UINavigationBar.appearance().largeTitleTextAttributes = [.foregroundColor : UIColor(Color.primary)]
        UINavigationBar.appearance().titleTextAttributes = [.foregroundColor : UIColor(Color.primary)]

    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                if hasCompletedOnboarding {
                    mainAppRoot
                } else {
                    TradingProfileFlowView(mode: .onboarding) { selectedProfile in
                        let resolvedBalance = TradingSession.applyProfile(selectedProfile, markOnboardingComplete: true)
                        profileID = selectedProfile.id
                        simCashBalance = resolvedBalance
                        vm.clearPortfolioStateImmediately(resetAccountSnapshots: true)
                        hasCompletedOnboarding = true
                    }
                }
            }
            .preferredColorScheme(selectedThemeMode.colorScheme)
        }
    }
    
    private var selectedThemeMode: AppThemeMode {
        AppThemeMode(rawValue: themeModeRawValue) ?? .system
    }
    
    private var mainAppRoot: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                NavigationStack {
                    HomeView(screenMode: .live) {
                        selectedTab = .news
                    }
                    .toolbar(.hidden)
                }
                .tabItem {
                    Label("Home", systemImage: "house")
                }
                .tag(AppTab.home)
                
                NavigationStack {
                    PortfolioRootView()
                        .toolbar(.hidden)
                }
                .tabItem {
                    Label("Portfolio", systemImage: "chart.pie")
                }
                .tag(AppTab.portfolio)
                
                NavigationStack {
                    NewsView()
                }
                .tabItem {
                    Label("News", systemImage: "newspaper")
                }
                .tag(AppTab.news)
            }
            .environmentObject(vm)
            .environmentObject(newsService)
            .environmentObject(watchlistStore)
            .environmentObject(tradeHistoryStore)
            
            ZStack {
                if showLaunchView {
                    LaunchView(showLaunchView: $showLaunchView)
                        .transition(reduceMotion ? .identity : .move(edge: .leading))
                }
            }
            .zIndex(2.0)
        }
    }
}
