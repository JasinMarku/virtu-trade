//
//  SearchBarView.swift
//  VirtuTrade
//
//  Created by Jasin ‎ on 10/22/24.
//

import SwiftUI

extension View {
    func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct SearchBarView: View {
    
    
    @Binding var searchText: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Color.theme.secondaryText)
            
            TextField("Search by name or symbol", text: $searchText)
                .autocorrectionDisabled(true)
                .fontWeight(.medium)
                .overlay(
                    Image(systemName: "xmark")
                        .padding()
                        .offset(x: 13)
                        .foregroundStyle(Color.theme.accent)
                        .opacity(searchText.isEmpty ? 0.0 : 1.0)
                        .onTapGesture {
                            dismissKeyboard()
                            searchText = ""
                        }
                        ,alignment: .trailing
                )

        }
        .font(.headline)
        .padding(.vertical, -5)
        .padding()
        .background(
            Capsule()
                .fill(Color.theme.accentBackground)
        )
        .padding()
    }
}

#Preview {
    SearchBarView(searchText: .constant(""))
}
