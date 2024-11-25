//
//  DetailViewModel.swift
//  VirtuTrade
//
//  Created by Jasin ‎ on 11/11/24.
//

import Foundation
import Combine

class DetailViewModel: ObservableObject {
    
    @Published var overviewStatistics: [StatisticModel] = []
    @Published var additionalStatistics: [StatisticModel] = []
    @Published var coinDescription: String? = nil
    @Published var websiteURL: String? = nil
    @Published var redditURL: String? = nil
    
    @Published var coin: CoinModel
    private let coinDetailService: CoinDetailDataService
    private var cancellables = Set<AnyCancellable>()
    
    init(coin: CoinModel) {
        self.coin = coin
        self.coinDetailService = CoinDetailDataService(coin: coin)
        self.addSubscribers()
    }
    
    private func addSubscribers() {
        coinDetailService.$coinDetails
            .sink { [weak self] returnedCoinDetails in
                self?.coinDescription = returnedCoinDetails?.readableDescription
                self?.websiteURL = returnedCoinDetails?.links?.homepage?.first
                self?.redditURL = returnedCoinDetails?.links?.subredditURL
                
                if let returnedCoinDetails = returnedCoinDetails {
                    let overviewStats = self?.mapDataToStatistics(coinModel: self?.coin, coinDetailModel: returnedCoinDetails)
                    self?.overviewStatistics = overviewStats?.overview ?? []
                    self?.additionalStatistics = overviewStats?.additional ?? []
                }
            }
            .store(in: &cancellables)
    }
    
    private func mapDataToStatistics(coinModel: CoinModel?, coinDetailModel: CoinDetailModel) -> (overview: [StatisticModel], additional: [StatisticModel]) {
        let price = coinModel?.currentPrice ?? 0
        let priceChange = coinModel?.priceChangePercentage24H ?? 0
        let priceStat = StatisticModel(title: "Current Price", value: price.asCurrencyWith6Decimals(), percentageChange: priceChange)
        
        let marketCap = coinModel?.marketCap ?? 0
        let marketCapChange = coinModel?.marketCapChangePercentage24H ?? 0
        let marketCapStat = StatisticModel(title: "Market Capitalization", value: marketCap.formattedWithAbbreviations(), percentageChange: marketCapChange)
        
        let rank = coinModel?.rank
        let rankString = rank == nil ? "" : "\(rank!)"
        let rankStat = StatisticModel(title: "Rank", value: rankString)
        
        let volume = coinModel?.totalVolume ?? 0
        let volumeStat = StatisticModel(title: "Volume", value: volume.formattedWithAbbreviations())
        
        let overview: [StatisticModel] = [
            priceStat, marketCapStat, rankStat, volumeStat
        ]
        
        let high = coinModel?.high24H ?? 0
        let highStat = StatisticModel(title: "24h High", value: high.asCurrencyWith6Decimals())
        
        let low = coinModel?.low24H ?? 0
        let lowStat = StatisticModel(title: "24h Low", value: low.asCurrencyWith6Decimals())
        
        let priceChange2 = coinModel?.priceChange24H ?? 0
        let pricePercentageChange2 = coinModel?.priceChangePercentage24H ?? 0
        let priceChangeStat = StatisticModel(title: "24h Price Change", value: priceChange2.asCurrencyWith6Decimals(), percentageChange: pricePercentageChange2)
        
        let marketCapChange2 = coinModel?.marketCapChange24H ?? 0
        let marketCapPercentageChange2 = coinModel?.marketCapChangePercentage24H ?? 0
        let marketCapChangeStat = StatisticModel(title: "24h Market Cap Change", value: marketCapChange2.formattedWithAbbreviations(), percentageChange: marketCapPercentageChange2)
        
        let blockTime = coinDetailModel.blockTimeInMinutes ?? 0
        let blockTimeString = blockTime == 0 ? "n/a" : "\(blockTime)"
        let blockStat = StatisticModel(title: "Block Time", value: blockTimeString)
        
        let hashing = coinDetailModel.hashingAlgorithm ?? "n/a"
        let hashingStat = StatisticModel(title: "Hashing Algorithm", value: hashing)
        
        let additional: [StatisticModel] = [
            highStat, lowStat, priceChangeStat, marketCapChangeStat, blockStat, hashingStat
        ]
        
        return (overview: overview, additional: additional)
    }
}
