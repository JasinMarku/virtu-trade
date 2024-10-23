//
//  CircleButtonView.swift
//  VirtuTrade
//
//  Created by Jasin ‎ on 10/17/24.
//

import SwiftUI

struct CircleButtonView: View {
    
    let iconName: String
    
    var body: some View {
        Image(systemName: iconName)
            .font(.headline)
            .foregroundStyle(Color.theme.accent)
            .frame(width: 50, height: 50)
            .fontWeight(.bold)
            .background(
                Circle()
                    .foregroundStyle(Color.theme.accentBackground)
            )
//            .shadow(color: Color.primary.opacity(0.35),
//                    radius: 10, x: 0, y: 0)
            .padding()
    }
}

#Preview {
    Group {
        CircleButtonView(iconName: "plus")

        CircleButtonView(iconName: "info")
    }
}
