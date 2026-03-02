//
//  CoinDataService.swift
//  VirtuTrade
//
//  Created by Jasin ‎ on 10/18/24.
//

import Foundation
import Combine
import os

final class CoinDataService {
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "me.marku.jasin.VirtuTrade",
        category: "CoinDataService"
    )
    
    // Published property to hold an array of all coins fetched from the API
    @Published private(set) var allCoins: [CoinModel] = []
    
    // AnyCancellable to manage the subscription lifecycle for the coin data fetch
    private var coinSubscription: AnyCancellable?
    
    // Initializer automatically fetches coins when the service is instantiated
    init() {
        getCoins()
    }
    
    // Fetches coin data from the CoinGecko API
    func getCoins() {
        coinSubscription?.cancel()
        
        // Ensure the API URL is valid
        guard let url = URL(string: "https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd&order=market_cap_desc&per_page=250&page=1&sparkline=true&price_change_percentage=24h") else {
            logger.error("Failed to construct market coins URL.")
            return
        }
        
        // Create a subscription to download and decode the coin data
        coinSubscription = NetworkingManager.download(url: url)
            .decode(type: [CoinModel].self, decoder: JSONDecoder()) // Decode JSON into an array of CoinModel
            .receive(on: DispatchQueue.main) // Ensure updates are made on the main thread
            .sink(
                receiveCompletion: { [weak self] completion in
                    NetworkingManager.handleCompletion(completion: completion)
                    self?.coinSubscription = nil
                }, // Handle errors or completion
                receiveValue: { [weak self] (returnedCoins) in
                    // Update the published property with the fetched coins
                    self?.allCoins = returnedCoins
                }
            )
    }
}
