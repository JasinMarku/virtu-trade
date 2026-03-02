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
                    
                    overviewTitle
                    
                    Divider()
                    
                    descriptionSection
                    
                    overviewGrid
                    
                    additionalTitle
                    
                    Divider()
                    
                    additionalGrid
                }
                .padding()
                .padding(.top, -15)
            }
        }
        .scrollIndicators(.hidden)
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
}

struct ChartView: View {
    let coin: CoinModel
    
    @State private var selectedPrice: Double?
    @State private var selectedIndex: Int?
    
    private let impactGenerator = UIImpactFeedbackGenerator(style: .light)
    
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
                
                    Text(displayPrice.asCurrencyWith2Decimals())
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
                                            impactGenerator.impactOccurred()
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
    
    private var navigationBarTrailingItems: some View {
        HStack {
            Text(vm.coin.symbol.uppercased())
                .font(.headline)
                .foregroundStyle(Color.theme.secondaryText)
            
            CoinImageView(coin: vm.coin)
                .frame(width: 25, height: 25)
        }
    }
}
