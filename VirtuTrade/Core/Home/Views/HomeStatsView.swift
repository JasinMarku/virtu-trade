//
//  HomeStatsView.swift
//  VirtuTrade
//
//  Created by Jasin ‎ on 10/23/24.
//

import SwiftUI

struct HomeStatsView: View {
    
    @EnvironmentObject private var vm: HomeViewModel
    @Binding var showPortfolio: Bool
    
    private let horizontalInset: CGFloat = 14
    
    private var availableWidth: CGFloat {
        UIScreen.main.bounds.width - (horizontalInset * 2)
    }
    
    private var statWidth: CGFloat {
        availableWidth / 3
    }
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(vm.statistics) { stat in
                StatisticView(stat: stat)
                    .frame(width: statWidth, alignment: .leading)
            }
        }
        .offset(x: showPortfolio ? -statWidth : 0)
        .frame(width: availableWidth, alignment: .leading)
        .padding(.horizontal, horizontalInset)
        .clipped()
        .animation(
            .interactiveSpring(response: 0.32, dampingFraction: 0.86, blendDuration: 0.1),
            value: showPortfolio
        )
    }
}

#Preview {
    HomeStatsView(showPortfolio: .constant(false))
        .environmentObject(DeveloperPreview.instance.homeVM)
}
