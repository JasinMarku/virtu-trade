//
//  VirtuTradeApp.swift
//  VirtuTrade
//
//  Created by Jasin ‎ on 10/17/24.
//

import SwiftUI
import UIKit

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

@main
struct VirtuTradeApp: App {
    private enum SimulationDefaults {
        static let cashBalanceKey = "vt_sim_cash_balance"
        static let hasInitializedKey = "vt_has_initialized_sim_balance"
        static let startingBalance: Double = 100_000
    }
    
    @StateObject private var vm = HomeViewModel()
    @StateObject private var watchlistStore = WatchlistStore()
    @StateObject private var tradeHistoryStore = TradeHistoryStore()
    @State private var showLaunchView: Bool = true
    @AppStorage("vt_theme_mode") private var themeModeRawValue: String = AppThemeMode.system.rawValue
    @AppStorage("vt_reduce_motion") private var reduceMotion: Bool = false
    
    init() {
        Self.initializeSimulationBalanceIfNeeded()
        UINavigationBar.appearance().largeTitleTextAttributes = [.foregroundColor : UIColor(Color.primary)]
        UINavigationBar.appearance().titleTextAttributes = [.foregroundColor : UIColor(Color.primary)]

    }
    
    var body: some Scene {
        WindowGroup {
            
            ZStack {
                NavigationStack {
                    HomeView()
                        .toolbar(.hidden)
                }
                .environmentObject(vm)
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
            .preferredColorScheme(selectedThemeMode.colorScheme)
        }
    }
    
    private var selectedThemeMode: AppThemeMode {
        AppThemeMode(rawValue: themeModeRawValue) ?? .system
    }
    
    private static func initializeSimulationBalanceIfNeeded() {
        let defaults = UserDefaults.standard
        
        if !defaults.bool(forKey: SimulationDefaults.hasInitializedKey) {
            defaults.set(SimulationDefaults.startingBalance, forKey: SimulationDefaults.cashBalanceKey)
            defaults.set(true, forKey: SimulationDefaults.hasInitializedKey)
            return
        }
        
        if defaults.object(forKey: SimulationDefaults.cashBalanceKey) == nil {
            defaults.set(SimulationDefaults.startingBalance, forKey: SimulationDefaults.cashBalanceKey)
        }
    }
}
