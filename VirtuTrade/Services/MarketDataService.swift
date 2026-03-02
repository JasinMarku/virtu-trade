//
//  MarketDataService.swift
//  VirtuTrade
//
//  Created by Jasin ‎ on 10/25/24.
//

import Foundation
import Combine
import os

final class MarketDataService {
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "me.marku.jasin.VirtuTrade",
        category: "MarketDataService"
    )
    
    // Published property to provide market data updates to subscribers
    @Published private(set) var marketData: MarketDataModel? = nil
    
    // Subscription to manage the network call lifecycle
    private var marketDataSubscription: AnyCancellable?
    
    // Initializes the service and fetches global market data
    init() {
        getData()
    }
    
    // Fetches global market data from the CoinGecko API
    func getData() {
        marketDataSubscription?.cancel()

        // Ensure the URL is valid
        guard let url = URL(string: "https://api.coingecko.com/api/v3/global") else {
            logger.error("Failed to construct global market data URL.")
            return
        }
        
        marketDataSubscription = NetworkingManager.download(url: url)
            .decode(type: GlobalData.self, decoder: JSONDecoder()) // Decode JSON into GlobalData model
            .receive(on: DispatchQueue.main) // Process the data on the main thread
            .sink(
                receiveCompletion: { [weak self] completion in
                    NetworkingManager.handleCompletion(completion: completion)
                    self?.marketDataSubscription = nil
                }, // Handle success or failure
                receiveValue: { [weak self] returnedGlobalData in
                    self?.marketData = returnedGlobalData.data // Update the published data
                }
            )
    }
}
