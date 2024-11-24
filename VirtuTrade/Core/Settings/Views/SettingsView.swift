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
                
                List {
                    Section {
                        VStack(alignment: .leading) {
                            Image("logo")
                                .resizable()
                                .frame(width: 100, height: 100)
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                            
                            Text("description here")
                        }
                    } header: {
                        Text("Coin Gecko")
                    }
                }
                .scrollContentBackground(.hidden)
                .listRowBackground(Color.theme.background)
                .listStyle(.grouped)
            }
            .navigationTitle("Settings")
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
