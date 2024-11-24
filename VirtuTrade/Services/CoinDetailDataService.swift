//
//  CoinDetailDataService.swift
//  VirtuTrade
//
//  Created by Jasin ‎ on 11/11/24.
//

import Foundation
import Combine

class CoinDetailDataService {
    
    @Published var coinDetails: CoinDetailModel? = nil
    
    var coinDetailSubscription: AnyCancellable?
    let coin: CoinModel
    
    init(coin: CoinModel) {
        self.coin = coin
        getCoinDetails()
    }
    
    func getCoinDetails() {
        guard let url = URL(string: "https://api.coingecko.com/api/v3/coins/\(coin.id)?localization=false&tickers=false&market_data=false&community_data=false&developer_data=false&sparkline=false") else { 
            print("DEBUG: Invalid URL for coin details")
            return 
        }
        
        print("DEBUG: Fetching details for coin: \(coin.id)")
        
        coinDetailSubscription = NetworkingManager.download(url: url)
            .decode(type: CoinDetailModel.self, decoder: JSONDecoder())
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    print("DEBUG: Successfully completed coin details request")
                case .failure(let error):
                    print("DEBUG: Failed to fetch coin details: \(error)")
                }
            }, receiveValue: { [weak self] (returnedCoinDetails) in
                self?.coinDetails = returnedCoinDetails
                self?.coinDetailSubscription?.cancel()
            })
    }
}
