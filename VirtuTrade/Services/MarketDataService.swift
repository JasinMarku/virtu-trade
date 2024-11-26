//
//  MarketDataService.swift
//  VirtuTrade
//
//  Created by Jasin ‎ on 10/25/24.
//

import Foundation
import Combine

class MarketDataService {
    
    // Published property to provide market data updates to subscribers
    @Published var marketData: MarketDataModel? = nil
    
    // Subscription to manage the network call lifecycle
    var marketDataSubscription: AnyCancellable?
    
    // Initializes the service and fetches global market data
    init() {
        getData()
    }
    
    // Fetches global market data from the CoinGecko API
    func getData() {
        // Ensure the URL is valid
        guard let url = URL(string: "https://api.coingecko.com/api/v3/global") else { return }
        
        marketDataSubscription = NetworkingManager.download(url: url)
            .decode(type: GlobalData.self, decoder: JSONDecoder()) // Decode JSON into GlobalData model
            .receive(on: DispatchQueue.main) // Process the data on the main thread
            .sink(
                receiveCompletion: NetworkingManager.handleCompletion, // Handle success or failure
                receiveValue: { [weak self] returnedGlobalData in
                    self?.marketData = returnedGlobalData.data // Update the published data
                    self?.marketDataSubscription?.cancel() // Cancel subscription once data is received
                }
            )
    }
}
