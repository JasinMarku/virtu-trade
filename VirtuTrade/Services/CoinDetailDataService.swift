//
//  CoinDetailDataService.swift
//  VirtuTrade
//
//  Created by Jasin ‎ on 11/11/24.
//

import Foundation
import Combine
import os

final class CoinDetailDataService {
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "me.marku.jasin.VirtuTrade",
        category: "CoinDetailDataService"
    )
    
    // Published property to hold the details of a specific coin
    @Published private(set) var coinDetails: CoinDetailModel? = nil
    
    // Combine subscription for managing the API call lifecycle
    private var coinDetailSubscription: AnyCancellable?
    
    // The coin for which details are being fetched
    let coin: CoinModel
    
    // Initialize the service with a specific coin and fetch its details
    init(coin: CoinModel) {
        self.coin = coin
        getCoinDetails()
    }
    
    // Fetches details for the specific coin from the API
    func getCoinDetails() {
        coinDetailSubscription?.cancel()

        guard let url = URL(string: "https://api.coingecko.com/api/v3/coins/\(coin.id)?localization=false&tickers=false&market_data=false&community_data=false&developer_data=false&sparkline=false") else {
            logger.error("Failed to construct coin detail URL for coin id: \(self.coin.id, privacy: .public)")
            return
        }
        
        coinDetailSubscription = NetworkingManager.download(url: url)
            .decode(type: CoinDetailModel.self, decoder: JSONDecoder()) // Decode JSON response into a CoinDetailModel
            .receive(on: DispatchQueue.main) // Ensure updates are made on the main thread
            .sink(
                receiveCompletion: { [weak self] completion in
                    NetworkingManager.handleCompletion(completion: completion)
                    self?.coinDetailSubscription = nil
                }, // Handle errors or successful completion
                receiveValue: { [weak self] (returnedCoinDetails) in
                    self?.coinDetails = returnedCoinDetails // Update the coin details
                }
            )
    }
}
