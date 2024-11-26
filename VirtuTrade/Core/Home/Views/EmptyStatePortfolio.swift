//
//  EmptyStatePortfolio.swift
//  VirtuTrade
//
//  Created by Jasin ‎ on 11/25/24.
//

import SwiftUI

struct EmptyStatePortfolio: View {
    var body: some View {
        VStack(alignment: .center, spacing: 10) {
            Image("wind")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 30)
                .foregroundStyle(Color.theme.secondaryText)
            
             Text("Your portfolio is empty!")
                .font(.title3)
                .fontWeight(.bold)
            
             Text("Start by adding your first asset")
                .fontWeight(.medium)
        }
        .multilineTextAlignment(.center)
        .foregroundStyle(Color.theme.secondaryText)
        .fontDesign(.rounded)
    }
}

#Preview {
    EmptyStatePortfolio()
}
