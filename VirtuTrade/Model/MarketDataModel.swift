//
//  MarketDataModel.swift
//  VirtuTrade
//
//  Created by Jasin ‎ on 10/24/24.
//

import Foundation

// JSON Data
/*
 URL: https://api.coingecko.com/api/v3/global
 
 
 JSON Response:
 {
   "data": {
     "active_cryptocurrencies": 14993,
     "upcoming_icos": 0,
     "ongoing_icos": 49,
     "ended_icos": 3376,
     "markets": 1140,
     "total_market_cap": {
       "btc": 35849997.59885481,
       "eth": 961285652.5213472,
       "ltc": 34107490492.35496,
       "bch": 6740528303.349158,
       "bnb": 4092504370.9401803,
       "eos": 5166104784786.5625,
       "xrp": 4575733651601.374,
       "xlm": 25340920804585.93,
       "link": 212098659062.23138,
       "dot": 577993836970.6914,
       "yfi": 490639980.04512125,
       "usd": 2423034654051.0576,
       "aed": 8899806284329.533,
       "ars": 2.386678145778135e+15,
       "aud": 3657221893299.87,
       "bdt": 289583791692613.8,
       "bhd": 913425911745.5493,
       "bmd": 2423034654051.0576,
       "brl": 13826078039480.715,
       "cad": 3359355820242.7354,
       "chf": 2098912577482.6072,
       "clp": 2293474991098944.5,
       "cny": 17250795219516.506,
       "czk": 56526490837426.125,
       "dkk": 16727831650132.66,
       "eur": 2242462842527.208,
       "gbp": 1870289565734.274,
       "gel": 6639114952099.899,
       "hkd": 18828626925541.45,
       "huf": 903159797411391.4,
       "idr": 3.78539927555773e+16,
       "ils": 9196010155614.018,
       "inr": 203741792062086.16,
       "jpy": 367616033215596.6,
       "krw": 3348703517799343.5,
       "kwd": 742342703926.9695,
       "lkr": 711719064146080.5,
       "mmk": 5.083526704199112e+15,
       "mxn": 48098485745760.414,
       "myr": 10535354675813.99,
       "ngn": 3981918229081358.5,
       "nok": 26560009554167.777,
       "nzd": 4034951188554.573,
       "php": 140439086125764.55,
       "pkr": 673181439422001.0,
       "pln": 9743628102602.797,
       "rub": 234434117606312.22,
       "sar": 9101637801908.006,
       "sek": 25638749971385.65,
       "sgd": 3199023617184.177,
       "thb": 81726853264027.83,
       "try": 82968958980525.95,
       "twd": 77816967009142.16,
       "uah": 99964625612213.5,
       "vef": 242618459910.13223,
       "vnd": 6.15452191860494e+16,
       "zar": 42880398235083.29,
       "xdr": 1818061053766.2053,
       "xag": 72584208023.63441,
       "xau": 888066431.0562524,
       "bits": 35849997598854.81,
       "sats": 3.584999759885481e+15
     },
     "total_volume": {
       "btc": 1591403.860729907,
       "eth": 42672072.55644579,
       "ltc": 1514052878.2371845,
       "bch": 299216275.69792974,
       "bnb": 181668833.81259328,
       "eos": 229326629012.3044,
       "xrp": 203119684422.5951,
       "xlm": 1124899355757.7559,
       "link": 9415192398.731247,
       "dot": 25657508653.853672,
       "yfi": 21779816.19996517,
       "usd": 107560026817.47417,
       "aed": 395067978500.5826,
       "ars": 105946138630490.4,
       "aud": 162346371837.11472,
       "bdt": 12854805996392.924,
       "bhd": 40547548669.54404,
       "bmd": 107560026817.47417,
       "brl": 613748269023.1882,
       "cad": 149123910180.4165,
       "chf": 93172044710.18097,
       "clp": 101808792183543.69,
       "cny": 765773610927.0073,
       "czk": 2509246353619.483,
       "dkk": 742558930338.9916,
       "eur": 99544330938.9554,
       "gbp": 83023325939.84503,
       "gel": 294714473479.8793,
       "hkd": 835814549190.0092,
       "huf": 40091829420441.625,
       "idr": 1680362461647472.2,
       "ils": 408216653978.88525,
       "inr": 9044225835317.521,
       "jpy": 16318706100672.156,
       "krw": 148651047799119.78,
       "kwd": 32953057856.042786,
       "lkr": 31593655294228.793,
       "mmk": 225660936263060.5,
       "mxn": 2135121925740.6768,
       "myr": 467670996602.37726,
       "ngn": 176759845670764.88,
       "nok": 1179015469358.8044,
       "nzd": 179114011977.7189,
       "php": 6234179046780.771,
       "pkr": 29882945981065.004,
       "pln": 432525757839.7671,
       "rub": 10406677401211.652,
       "sar": 404027406054.39685,
       "sek": 1138120179122.5579,
       "sgd": 142006663205.90424,
       "thb": 3627906234890.1,
       "try": 3683044086077.3745,
       "twd": 3454343933696.568,
       "uah": 4437492379100.691,
       "vef": 10769985485.23368,
       "vnd": 2.73203085026918e+15,
       "zar": 1903487750948.3372,
       "xdr": 80704869561.79446,
       "xag": 3222058482.9418335,
       "xau": 39421825.42887242,
       "bits": 1591403860729.907,
       "sats": 159140386072990.7
     },
     "market_cap_percentage": {
       "btc": 55.15303577211845,
       "eth": 12.516417762400566,
       "usdt": 4.965763468121427,
       "bnb": 3.5648986428618823,
       "sol": 3.413009448809537,
       "usdc": 1.4173906580388524,
       "xrp": 1.2392657016375348,
       "steth": 1.0135328732384135,
       "doge": 0.8491580222276793,
       "trx": 0.5852814117268288
     },
     "market_cap_change_percentage_24h_usd": 0.3389608851925839,
     "updated_at": 1729787435
   }
 }
 */

struct GlobalData: Codable {
    let data: MarketDataModel?
}

// Represents the market data model fetched from the API.
struct MarketDataModel: Codable {
    let totalMarketCap, totalVolume, marketCapPercentage: [String: Double]
    let marketCapChangePercentage24HUsd: Double
    
    // Maps JSON keys to Swift property names for decoding.
    enum CodingKeys: String, CodingKey {
        case totalMarketCap = "total_market_cap"
        case totalVolume = "total_volume"
        case marketCapPercentage = "market_cap_percentage"
        case marketCapChangePercentage24HUsd = "market_cap_change_percentage_24h_usd"
    }
    
    // Computed property to retrieve and format total market cap in USD.
    var marketCap: String {
        if let item = totalMarketCap.first(where: { $0.key == "usd" }) {
            return "$" + item.value.formattedWithAbbreviations()
        }
        return ""
    }
    
    // Computed property to retrieve and format total volume in USD.
    var volume: String {
        if let item = totalVolume.first(where: { $0.key == "usd" }) {
            return "$" + item.value.formattedWithAbbreviations()
        }
        return ""
    }
     
    // Computed property to retrieve and format Bitcoin dominance as a percentage.
    var btcDominance: String {
        if let item = marketCapPercentage.first(where: { $0.key == "btc" }) {
            return item.value.asPercentString()
        }
        return ""
    }
}
