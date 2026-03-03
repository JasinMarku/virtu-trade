//
//  VirtuTradeApp.swift
//  VirtuTrade
//
//  Created by Jasin ‎ on 10/17/24.
//

import SwiftUI

@main
struct VirtuTradeApp: App {
    private enum SimulationDefaults {
        static let cashBalanceKey = "vt_sim_cash_balance"
        static let hasInitializedKey = "vt_has_initialized_sim_balance"
        static let startingBalance: Double = 100_000
    }
    
    @StateObject private var vm = HomeViewModel()
    @StateObject private var watchlistStore = WatchlistStore()
    @State private var showLaunchView: Bool = true
    
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
                
                ZStack {
                    if showLaunchView {
                        LaunchView(showLaunchView: $showLaunchView)
                            .transition(.move(edge: .leading))
                    }
                }
                .zIndex(2.0)
            }
        }
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
