//
//  CoinModel.swift
//  VirtuTrade
//
//  Created by Jasin ‎ on 10/17/24.
//

import Foundation

// Coin Gecko API Info
/*
 URL:
 https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd&order=market_cap_desc&per_page=250&page=1&sparkline=true&price_change_percentage=24h
 
 JSON Response:
 {
 "id":"bitcoin",
 "symbol":"btc",
 "name":"Bitcoin",
 "image":"https://coin-images.coingecko.com/coins/images/1/large/bitcoin.png?1696501400",
 "current_price":67424,
 "market_cap":1332907052406,
 "market_cap_rank":1,
 "fully_diluted_valuation":1415906407211,
 "total_volume":33692992347,
 "high_24h":68038,
 "low_24h":66739,
 "price_change_24h":-447.22363182902336,
 "price_change_percentage_24h":-0.65893,
 "market_cap_change_24h":-8711445420.195557,
 "market_cap_change_percentage_24h":-0.64932,
 "circulating_supply":19768996.0,
 "total_supply":21000000.0,
 "max_supply":21000000.0,
 "ath":73738,"ath_change_percentage":-8.52846,
 "ath_date":"2024-03-14T07:10:36.635Z","atl":67.81,
 "atl_change_percentage":99369.43001,
 "atl_date":"2013-07-06T00:00:00.000Z",
 "roi":null,
 "last_updated":"2024-10-17T17:21:45.840Z",
 "sparkline_in_7d":{
 "price":[
 61226.55340601267,
 60966.09545988984
 ]
 },
 "price_change_percentage_24h_in_currency":-0.6589259200101212
 }
 */

struct CoinModel: Identifiable, Codable {
    let id, symbol, name: String
    let image: String
    let currentPrice: Double
    let marketCap, marketCapRank, fullyDilutedValuation: Double?
    let totalVolume, high24H, low24H: Double?
    let priceChange24H, priceChangePercentage24H, marketCapChange24H, marketCapChangePercentage24H: Double?
    let circulatingSupply, totalSupply, maxSupply, ath: Double?
    let athChangePercentage: Double?
    let athDate: String?
    let atl, atlChangePercentage: Double?
    let atlDate: String?
    let lastUpdated: String?
    let sparklineIn7D: SparklineIn7D?
    let priceChangePercentage24HInCurrency: Double?
    let currentHoldings: Double?
    
    enum CodingKeys: String, CodingKey {
        case id, symbol, name, image
        case currentPrice = "current_price"
        case marketCap = "market_cap"
        case marketCapRank = "market_cap_rank"
        case fullyDilutedValuation = "fully_diluted_valuation"
        case totalVolume = "total_volume"
        case high24H = "high_24h"
        case low24H = "low_24h"
        case priceChange24H = "price_change_24h"
        case priceChangePercentage24H = "price_change_percentage_24h"
        case marketCapChange24H = "market_cap_change_24h"
        case marketCapChangePercentage24H = "market_cap_change_percentage_24h"
        case circulatingSupply = "circulating_supply"
        case totalSupply = "total_supply"
        case maxSupply = "max_supply"
        case ath
        case athChangePercentage = "ath_change_percentage"
        case athDate = "ath_date"
        case atl
        case atlChangePercentage = "atl_change_percentage"
        case atlDate = "atl_date"
        case lastUpdated = "last_updated"
        case sparklineIn7D = "sparkline_in_7d"
        case priceChangePercentage24HInCurrency = "price_change_percentage_24h_in_currency"
        case currentHoldings
    }
    
    func updateHoldings(amount: Double) -> CoinModel {
        // Returns a new CoinModel instance with updated holdings.
        // This is useful for updating portfolio data without modifying the original object.
        return CoinModel(id: id, symbol: symbol, name: name, image: image, currentPrice: currentPrice, marketCap: marketCap, marketCapRank: marketCapRank, fullyDilutedValuation: fullyDilutedValuation, totalVolume: totalVolume, high24H: high24H, low24H: low24H, priceChange24H: priceChange24H, priceChangePercentage24H: priceChangePercentage24H, marketCapChange24H: marketCapChange24H, marketCapChangePercentage24H: marketCapChangePercentage24H, circulatingSupply: circulatingSupply, totalSupply: totalSupply, maxSupply: maxSupply, ath: ath, athChangePercentage: athChangePercentage, athDate: athDate, atl: atl, atlChangePercentage: atlChangePercentage, atlDate: atlDate, lastUpdated: lastUpdated, sparklineIn7D: sparklineIn7D, priceChangePercentage24HInCurrency: priceChangePercentage24HInCurrency, currentHoldings: amount)
    }
    
    var currentHoldingsValue: Double {
        // Calculates the total value of the holdings based on the current price./
        return (currentHoldings ?? 0) * currentPrice
    }
    
    var rank: Int {
        // Returns the market cap rank of the coin as an integer.
        return Int(marketCapRank ?? 0)
    }
    
}

struct SparklineIn7D: Codable {
    let price: [Double]?
    // Represents the 7-day price trend of the coin.
    // The `price` array contains historical price data.
}
