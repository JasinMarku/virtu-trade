//
//  DetailViewModel.swift
//  VirtuTrade
//
//  Created by Jasin ‎ on 11/11/24.
//

import Foundation
import Combine

@MainActor
final class DetailViewModel: ObservableObject {
    
    // Published properties to update UI with coin details and statistics
    @Published var overviewStatistics: [StatisticModel] = [] // Key overview statistics (e.g., price, market cap)
    @Published var additionalStatistics: [StatisticModel] = [] // Additional details (e.g., block time, 24h high/low)
    @Published var coinDescription: String? = nil // Coin description from API
    @Published var websiteURL: String? = nil // Official website URL
    @Published var redditURL: String? = nil // Subreddit URL
    
    @Published var coin: CoinModel // Coin model passed to initialize this ViewModel
    private let coinDetailService: CoinDetailDataService // Service to fetch coin details
    private var cancellables = Set<AnyCancellable>() // Store Combine subscriptions
    
    // MARK: - Initialization
    init(coin: CoinModel) {
        self.coin = coin
        self.coinDetailService = CoinDetailDataService(coin: coin)
        self.addSubscribers() // Subscribe to service data updates
    }
    
    // MARK: - Subscribers
    private func addSubscribers() {
        // Listen for updates to coin details and process them
        coinDetailService.$coinDetails
            .sink { [weak self] returnedCoinDetails in
                guard let self else { return }
                // Update the UI properties with data from the API
                self.coinDescription = returnedCoinDetails?.readableDescription
                self.websiteURL = returnedCoinDetails?.links?.homepage?.first
                self.redditURL = returnedCoinDetails?.links?.subredditURL

                guard let returnedCoinDetails else {
                    self.overviewStatistics = []
                    self.additionalStatistics = []
                    return
                }

                // Generate and assign statistics based on the fetched details
                let overviewStats = self.mapDataToStatistics(coinModel: self.coin, coinDetailModel: returnedCoinDetails)
                self.overviewStatistics = overviewStats.overview
                self.additionalStatistics = overviewStats.additional
            }
            .store(in: &cancellables) // Retain the subscription
    }
    
    // MARK: - Data Mapping
    /// Maps the coin details to displayable statistics
    private func mapDataToStatistics(coinModel: CoinModel, coinDetailModel: CoinDetailModel) -> (overview: [StatisticModel], additional: [StatisticModel]) {
        // Overview statistics
        let price = coinModel.currentPrice
        let priceChange = coinModel.priceChangePercentage24H ?? 0
        let priceStat = StatisticModel(title: "Current Price", value: price.asCurrencyWith6Decimals(), percentageChange: priceChange)
        
        let marketCap = coinModel.marketCap ?? 0
        let marketCapChange = coinModel.marketCapChangePercentage24H ?? 0
        let marketCapStat = StatisticModel(title: "Market Capitalization", value: marketCap.formattedWithAbbreviations(), percentageChange: marketCapChange)
        
        let rankString = coinModel.marketCapRank.map { String(Int($0)) } ?? ""
        let rankStat = StatisticModel(title: "Rank", value: rankString)
        
        let volume = coinModel.totalVolume ?? 0
        let volumeStat = StatisticModel(title: "Volume", value: volume.formattedWithAbbreviations())
        
        let overview: [StatisticModel] = [priceStat, marketCapStat, rankStat, volumeStat]
        
        // Additional statistics
        let high = coinModel.high24H ?? 0
        let highStat = StatisticModel(title: "24h High", value: high.asCurrencyWith6Decimals())
        
        let low = coinModel.low24H ?? 0
        let lowStat = StatisticModel(title: "24h Low", value: low.asCurrencyWith6Decimals())
        
        let priceChange2 = coinModel.priceChange24H ?? 0
        let pricePercentageChange2 = coinModel.priceChangePercentage24H ?? 0
        let priceChangeStat = StatisticModel(title: "24h Price Change", value: priceChange2.asCurrencyWith6Decimals(), percentageChange: pricePercentageChange2)
        
        let marketCapChange2 = coinModel.marketCapChange24H ?? 0
        let marketCapPercentageChange2 = coinModel.marketCapChangePercentage24H ?? 0
        let marketCapChangeStat = StatisticModel(title: "24h Market Cap Change", value: marketCapChange2.formattedWithAbbreviations(), percentageChange: marketCapPercentageChange2)
        
        let blockTime = coinDetailModel.blockTimeInMinutes ?? 0
        let blockTimeString = blockTime == 0 ? "n/a" : "\(blockTime)"
        let blockStat = StatisticModel(title: "Block Time", value: blockTimeString)
        
        let hashing = coinDetailModel.hashingAlgorithm ?? "n/a"
        let hashingStat = StatisticModel(title: "Hashing Algorithm", value: hashing)
        
        let additional: [StatisticModel] = [highStat, lowStat, priceChangeStat, marketCapChangeStat, blockStat, hashingStat]
        
        return (overview: overview, additional: additional)
    }
}
