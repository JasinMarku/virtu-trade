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
    private let fileManager = LocalFileManager.instance
    private let folderName = "coin_images"
    private let imageName: String
    
    init(coin: CoinModel) {
        self.coin = coin
        self.imageName = coin.id
        getCoinImage()
    }
    
    private func getCoinImage() {
        if let savedImage = fileManager.getImage(imageName: imageName, folderName: folderName) {
            image = savedImage
            print("✅ - Retrieved image from File Manager")
        } else {
            downloadCoinImage()
            print("☁️ - Downloading Image Now.")
        }
    }
    
    
    private func downloadCoinImage() {
        print("Downloading Image Now.")
        // Validates the URL
        guard let url = URL(string: coin.image) else { return }
        
//       Starts download, calls a method to start downloading data from the URL.
//       Method returns a publisher, which is a Combine concept for handling asynchronous data streams.
        imageSubscription = NetworkingManager.download(url: url)
            .tryMap({ (data) -> UIImage? in // Convert Data to UIImage
                return UIImage(data: data)
            })
            .sink(receiveCompletion: NetworkingManager.handleCompletion, receiveValue: { [weak self ](returnedImage) in
                guard let self = self, let downloadedImage = returnedImage else { return }
                self.image = downloadedImage
                self.imageSubscription?.cancel()
                self.fileManager.saveImage(image: downloadedImage, imageName: self.imageName, folderName: self.folderName)
            })
    }
}
