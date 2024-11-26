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
    
    // Published image that can be observed by the UI
    @Published var image: UIImage? = nil
    
    // Private properties for managing image subscription and file storage
    private var imageSubscription: AnyCancellable?
    private let coin: CoinModel
    private let fileManager = LocalFileManager.instance
    private let folderName = "coin_images"
    private let imageName: String
    
    // Initialize the service with a specific coin and fetch its image
    init(coin: CoinModel) {
        self.coin = coin
        self.imageName = coin.id
        getCoinImage()
    }
    
    // Attempts to retrieve the image from local storage or downloads it if not available
    private func getCoinImage() {
        if let savedImage = fileManager.getImage(imageName: imageName, folderName: folderName) {
            image = savedImage // Load from local storage
        } else {
            downloadCoinImage() // Fetch from the network
        }
    }
    
    // Downloads the coin image from the provided URL
    private func downloadCoinImage() {
        guard let url = URL(string: coin.image) else { return }
        
        imageSubscription = NetworkingManager.download(url: url)
            .tryMap { data -> UIImage? in
                UIImage(data: data) // Convert downloaded data into a UIImage
            }
            .receive(on: DispatchQueue.main) // Ensure updates are made on the main thread
            .sink(
                receiveCompletion: NetworkingManager.handleCompletion, // Handle completion or errors
                receiveValue: { [weak self] downloadedImage in
                    guard let self = self, let downloadedImage = downloadedImage else { return }
                    self.image = downloadedImage // Update the published image
                    self.imageSubscription?.cancel() // Cancel subscription after successful fetch
                    self.fileManager.saveImage(
                        image: downloadedImage,
                        imageName: self.imageName,
                        folderName: self.folderName
                    ) // Save image locally for future use
                }
            )
    }
}
