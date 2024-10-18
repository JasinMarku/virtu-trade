//
//  CoinImageService.swift
//  VirtuTrade
//
//  Created by Jasin ‎ on 10/18/24.
//

import Foundation
import SwiftUI
import Combine

class CoinImageService {
    
    @Published var image: UIImage? = nil
    
    private var imageSubscription: AnyCancellable?
    private let coin: CoinModel
    
    init(coin: CoinModel) {
        self.coin = coin
        getCoinImage()
    }
    
    private func getCoinImage() {
        // Validates the URL
        guard let url = URL(string: coin.image) else { return }
        
//       Starts download, calls a method to start downloading data from the URL.
//       Method returns a publisher, which is a Combine concept for handling asynchronous data streams.
        imageSubscription = NetworkingManager.download(url: url)
            .tryMap({ (data) -> UIImage? in // Convert Data to UIImage
                return UIImage(data: data)
            })
            .sink(receiveCompletion: NetworkingManager.handleCompletion, receiveValue: { [weak self ](returnedImage) in
                self?.image = returnedImage
                self?.imageSubscription?.cancel()
            })
    }
}
