//
//  CoinImageService.swift
//  VirtuTrade
//
//  Created by Jasin ‎ on 10/18/24.
//

import Foundation
import SwiftUI
import Combine
import os

final class CoinImageService {
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "me.marku.jasin.VirtuTrade",
        category: "CoinImageService"
    )
    
    // Published image that can be observed by the UI
    @Published private(set) var image: UIImage? = nil
    @Published private(set) var isLoading: Bool = false
    
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
            isLoading = false
        } else {
            downloadCoinImage() // Fetch from the network
        }
    }
    
    // Downloads the coin image from the provided URL
    private func downloadCoinImage() {
        imageSubscription?.cancel()
        isLoading = true

        guard let url = URL(string: coin.image) else {
            logger.error("Failed to construct coin image URL for coin id: \(self.coin.id, privacy: .public)")
            isLoading = false
            return
        }
        
        imageSubscription = NetworkingManager.download(url: url)
            .tryMap { data -> UIImage in
                guard let image = UIImage(data: data) else {
                    throw NetworkingManager.NetworkingError.invalidImageData(url: url)
                }
                return image
            }
            .receive(on: DispatchQueue.main) // Ensure updates are made on the main thread
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    NetworkingManager.handleCompletion(completion: completion)
                    self?.imageSubscription = nil
                }, // Handle completion or errors
                receiveValue: { [weak self] downloadedImage in
                    guard let self else { return }
                    self.image = downloadedImage // Update the published image
                    self.fileManager.saveImage(
                        image: downloadedImage,
                        imageName: self.imageName,
                        folderName: self.folderName
                    ) // Save image locally for future use
                }
            )
    }
}
