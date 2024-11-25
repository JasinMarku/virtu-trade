//
//  LaunchView.swift
//  VirtuTrade
//
//  Created by Jasin ‎ on 11/25/24.
//

import SwiftUI

struct LaunchView: View {
    
    @State private var loadingText: [String] = "Analyzing The Market…".map { String ($0) }
    @State private var showingLoadingText: Bool = false
    private let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    
    @State private var counter: Int = 0
    @State private var loops: Int = 0
    @Binding var showLaunchView: Bool
    
    
    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()
            
            Image("roundedlogo")
                .resizable()
                .frame(width: 100, height: 100)
            
            ZStack {
                if showingLoadingText {
                    HStack(spacing: 0) {
                        ForEach(0..<21) { index in
                            Text(loadingText[index])
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundStyle(Color("IconAccent"))
                                .fontDesign(.rounded)
                                .offset(y: counter == index ? -5 : 0)
                        }
                    }
                    .transition(AnyTransition.scale.animation(.easeIn))

                }
            }
            .offset(y: 80)
        }
        .onAppear {
            showingLoadingText.toggle()
        }
        .onReceive(timer, perform: { _ in
            withAnimation(.spring()) {
                let lastIndex = loadingText.count - 1
                if counter == lastIndex {
                    counter = 0
                    loops += 1
                    if loops >= 2 {
                        showLaunchView = false
                    }
                } else {
                    counter += 1
                }
            }
        })
    }
}

#Preview {
    LaunchView(showLaunchView: .constant(true))
}
