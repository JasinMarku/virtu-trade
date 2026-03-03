//
//  DetailView.swift
//  VirtuTrade
//
//  Created by Jasin ‎ on 11/10/24.
//

import SwiftUI
import Charts

struct DetailLoadingView: View {
    
    @Binding var coin: CoinModel?

    var body: some View {
        ZStack {
            if let coin = coin {
                DetailView(coin: coin)
            }
        }
    }
}

struct DetailView: View {
    
    @EnvironmentObject private var watchlistStore: WatchlistStore
    @State private var showDescriptionSheet: Bool = false
    @StateObject private var vm: DetailViewModel
    private let columns: [GridItem] = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    private let spacing: CGFloat = 30
    
    init(coin: CoinModel, mockDetailData: CoinDetailModel? = nil) {
        _vm = StateObject(wrappedValue: DetailViewModel(coin: coin))
    }
    
    var body: some View {
        ZStack {
            Color.theme.background
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    ChartView(coin: vm.coin)
                        .padding(.vertical)
                    
                    detailStateContent
                }
                .padding()
                .padding(.top, -15)
            }
        }
        .scrollIndicators(.hidden)
        .task(id: vm.coin.id) {
            vm.loadCoinDetails()
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                navigationBarTrailingItems
            }
        }
    }
}

#Preview {
    NavigationStack {
        DetailView(coin: DeveloperPreview.instance.coin)
    }
    .environmentObject(WatchlistStore())
}

struct ChartView: View {
    let coin: CoinModel
    
    @State private var selectedPrice: Double?
    @State private var selectedIndex: Int?
    @State private var previousIndex: Int?
    
    private var priceData: [Double] {
        coin.sparklineIn7D?.price ?? []
    }
    
    private var displayPrice: Double {
        selectedPrice ?? coin.currentPrice
    }
    
    private var dateText: String {
        let calendar = Calendar.current
        let selectedDate: Date
        
        if let index = selectedIndex, !priceData.isEmpty {
            // Calculate date for dragging
            let endDate = Date()
            let hoursPerDataPoint = 168.0 / Double(priceData.count)
            guard let startDate = calendar.date(byAdding: .day, value: -7, to: endDate),
                  let date = calendar.date(byAdding: .hour,
                                         value: Int(Double(index) * hoursPerDataPoint),
                                         to: startDate) else { return "" }
            selectedDate = date
        } else {
            // Use current date when not dragging
            selectedDate = Date()
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "E, MMM d"
        return formatter.string(from: selectedDate)
    }
    
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8){
            VStack(alignment: .leading, spacing: 10) {
                Text(coin.name)
                    .font(.title)
                    .fontWeight(.bold)
                
                    Text(displayPrice.asCurrencyWithAdaptiveDecimals())
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(coin.priceChangePercentage24H ?? 0 >= 0 ? Color.theme.green : Color.theme.red)
                        .shadow(color: coin.priceChangePercentage24H ?? 0 >= 0 ? Color.theme.green.opacity(0.5) : Color.theme.red.opacity(0.5), radius: 8)
                
                
                    Text(dateText)
                        .font(.headline)
                        .foregroundStyle(Color.theme.secondaryText)
            }
            
            Chart {
                ForEach(Array(priceData.enumerated()), id: \.offset) { index, price in
                    LineMark(
                        x: .value("Time", index),
                        y: .value("Price", price)
                    )
                    .interpolationMethod(.cardinal)
                    if let selectedIndex, selectedIndex == index {
                        RuleMark (
                            x: .value("Time", index)
                        )
                        .foregroundStyle(Color.theme.secondaryText)
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                    }
                }
            }
            .chartXAxis(.hidden)
            .chartYScale(domain: .automatic(includesZero: false))
            .chartYAxis {
                AxisMarks(position: .trailing) { _ in
                        AxisGridLine(centered: true, stroke: StrokeStyle(lineWidth: 0))
                        AxisValueLabel()
                }
            }
            .frame(height: 200)
            .foregroundStyle(coin.priceChangePercentage24H ?? 0 >= 0 ? Color.theme.green : Color.theme.red)
            .shadow(color: coin.priceChangePercentage24H ?? 0 >= 0 ? Color.theme.green : Color.theme.red, radius: 10, x: 0, y: 11)
            .overlay(
                GeometryReader { proxy in
                    Rectangle()
                        .fill(.clear)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    guard !priceData.isEmpty, proxy.size.width > 0 else { return }

                                    let clampedX = min(max(value.location.x, 0), proxy.size.width)
                                    let normalizedX = clampedX / proxy.size.width
                                    let scaledIndex = normalizedX * CGFloat(max(priceData.count - 1, 0))
                                    let index = Int(scaledIndex.rounded(.towardZero))

                                    if index >= 0 && index < priceData.count {
                                        if index != previousIndex {
                                            AppHaptics.impact(.light)
                                            previousIndex = index
                                        }
                                        
                                        selectedIndex = index
                                        selectedPrice = priceData[index]
                                    }
                                }
                                .onEnded { _ in
                                    selectedIndex = nil
                                    selectedPrice = nil
                                }
                        )
                }
            )
        }
    }
}

extension DetailView {
    @ViewBuilder
    private var detailStateContent: some View {
        switch vm.viewState {
        case .loading:
            loadingStateSection
        case .failed(let message):
            failureStateSection(message: message)
        case .empty:
            emptyStateSection
        case .loaded:
            loadedContentSection
        }
    }
    
    private var loadedContentSection: some View {
        VStack(spacing: 20) {
            overviewTitle
            
            Divider()
            
            descriptionSection
            
            overviewGrid
            
            additionalTitle
            
            Divider()
            
            additionalGrid
        }
    }
    
    private var loadingStateSection: some View {
        VStack(spacing: 12) {
            ProgressView()
                .progressViewStyle(.circular)
            
            Text("Loading coin details...")
                .font(.subheadline)
                .foregroundStyle(Color.theme.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 30)
    }
    
    private var emptyStateSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("No detail data available right now.")
                .font(.headline)
                .foregroundStyle(Color.primary)
            
            Text("Please try again in a moment.")
                .font(.subheadline)
                .foregroundStyle(Color.theme.secondaryText)
            
            Button(action: vm.loadCoinDetails) {
                Text("Retry")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color.primary)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.theme.accentBackground)
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 8)
    }
    
    private func failureStateSection(message: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Couldn't load coin details.")
                .font(.headline)
                .foregroundStyle(Color.primary)
            
            Text(message)
                .font(.subheadline)
                .foregroundStyle(Color.theme.secondaryText)
            
            Button(action: vm.loadCoinDetails) {
                Text("Retry")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color.primary)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.theme.accentBackground)
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 8)
    }
    
    
    private var descriptionSection: some View {
          Group {
              if let coinDescription = vm.coinDescription,
                 !coinDescription.isEmpty {
                  VStack(alignment: .leading, spacing: 10) {
                      HStack {
                          Text("About \(vm.coin.name)")
                              .font(.headline)
                              .foregroundStyle(Color.theme.accent)
                          
                          Spacer()
                          
                          Button {
                              showDescriptionSheet = true
                          } label: {
                              HStack(spacing: 4) {
                                  Text("View More")
                                  Image(systemName: "chevron.right")
                              }
                              .font(.callout)
                              .foregroundStyle(Color.theme.secondaryText)
                          }
                      }
                      
                      Text(coinDescription)
                          .lineLimit(3)
                          .font(.callout)
                          .foregroundStyle(Color.theme.secondaryText)
                  }
                  .frame(maxWidth: .infinity, alignment: .leading)
                  .sheet(isPresented: $showDescriptionSheet) {
                      DescriptionView(coin: vm.coin, description: vm.coinDescription ?? "", redditURL: vm.redditURL, websiteURL: vm.websiteURL)
                  }
              }
          }
      }
    
    private var overviewTitle: some View {
        Text("Overview")
            .font(.title.bold())
            .foregroundStyle(Color.theme.accent)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var additionalTitle: some View {
        Text("Additional Details")
            .font(.title.bold())
            .foregroundStyle(Color.theme.accent)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var overviewGrid: some View {
        LazyVGrid(columns: columns,
                  alignment: .leading,
                  spacing: spacing,
                  pinnedViews: []
                  ,content: {
            ForEach(vm.overviewStatistics) { stat in
                StatisticView(stat: stat)
            }
        })
    }
    
    private var additionalGrid: some View {
        LazyVGrid(columns: columns,
                  alignment: .leading,
                  spacing: spacing,
                  pinnedViews: []
                  ,content: {
            ForEach(vm.additionalStatistics) { stat in
                StatisticView(stat: stat)
            }
        })
    }
    
    private var isWatchlisted: Bool {
        watchlistStore.isWatchlisted(vm.coin.id)
    }
    
    private func toggleWatchlist() {
        AppHaptics.impact(.light)
        watchlistStore.toggle(vm.coin.id)
    }
    
    private var navigationBarTrailingItems: some View {
        HStack {
            Button(action: toggleWatchlist) {
                Image(systemName: isWatchlisted ? "star.fill" : "star")
                    .font(.headline)
                    .foregroundStyle(isWatchlisted ? Color.theme.accent : Color.theme.secondaryText)
            }
            .accessibilityLabel(isWatchlisted ? "Remove from Watchlist" : "Add to Watchlist")
            
            Text(vm.coin.symbol.uppercased())
                .font(.headline)
                .foregroundStyle(Color.theme.secondaryText)
            
            CoinImageView(coin: vm.coin)
                .frame(width: 25, height: 25)
        }
    }
}
