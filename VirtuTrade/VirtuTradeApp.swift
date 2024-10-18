//
//  VirtuTradeApp.swift
//  VirtuTrade
//
//  Created by Jasin ‎ on 10/17/24.
//

import SwiftUI

@main
struct VirtuTradeApp: App {
    
    @StateObject private var vm = HomeViewModel()
    
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                HomeView()
                    .toolbar(.hidden)
            }
            .environmentObject(vm)
        }
    }
}
