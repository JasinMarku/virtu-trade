//
//  CoinDetailDataService.swift
//  VirtuTrade
//
//  Created by Jasin ‎ on 11/11/24.
//

import Foundation
import Combine
class CoinDetailDataService {
    
    // Published property to hold the details of a specific coin
    @Published var coinDetails: CoinDetailModel? = nil
    
    // Combine subscription for managing the API call lifecycle
    var coinDetailSubscription: AnyCancellable?
    
    // The coin for which details are being fetched
    let coin: CoinModel
    
    // Initialize the service with a specific coin and fetch its details
    init(coin: CoinModel) {
        self.coin = coin
        getCoinDetails()
    }
    
    // Fetches details for the specific coin from the API
    func getCoinDetails() {
        guard let url = URL(string: "https://api.coingecko.com/api/v3/coins/\(coin.id)?localization=false&tickers=false&market_data=false&community_data=false&developer_data=false&sparkline=false") else {
            print("DEBUG: Invalid URL for coin details")
            return
        }
        
        coinDetailSubscription = NetworkingManager.download(url: url)
            .decode(type: CoinDetailModel.self, decoder: JSONDecoder()) // Decode JSON response into a CoinDetailModel
            .receive(on: DispatchQueue.main) // Ensure updates are made on the main thread
            .sink(
                receiveCompletion: NetworkingManager.handleCompletion, // Handle errors or successful completion
                receiveValue: { [weak self] (returnedCoinDetails) in
                    self?.coinDetails = returnedCoinDetails // Update the coin details
                    self?.coinDetailSubscription?.cancel()  // Cancel the subscription
                }
            )
    }
}
