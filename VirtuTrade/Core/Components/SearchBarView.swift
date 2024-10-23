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
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack {
           if isFocused {
               Button(action: {
                   dismissKeyboard()
               }, label: {
                   Image(systemName: "arrow.left")
                      .foregroundStyle(Color.theme.accent)
               })
           } else {
               Image(systemName: "magnifyingglass")
                   .foregroundStyle(Color.theme.secondaryText)
           }
            
            TextField("Search", text: $searchText)
                .focused($isFocused)
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
                .overlay(
                    Capsule()
                        .stroke(isFocused ? Color.theme.accent : Color.clear, lineWidth: 1.0)
                )
        )
        .padding()
    }
}

#Preview {
    SearchBarView(searchText: .constant(""))
}
