//
//  LocalFileManager.swift
//  VirtuTrade
//
//  Created by Jasin ‎ on 10/21/24.
//

import Foundation
import SwiftUI

/// A singleton class for managing local image storage in the app.
class LocalFileManager {
    
    static let instance = LocalFileManager() // Singleton instance
    private init() { } // Prevent external initialization
    
    /// Saves an image to the specified folder in the caches directory.
    /// - Parameters:
    ///   - image: The image to save.
    ///   - imageName: The name to assign to the image file.
    ///   - folderName: The folder to save the image in.
    func saveImage(image: UIImage, imageName: String, folderName: String) {
        // Ensure the folder exists.
        createFolderIfNeeded(folderName: folderName)
        
        // Prepare data and URL for saving the image.
        guard let data = image.pngData(),
              let url = getURLForImage(imageName: imageName, folderName: folderName) else { return }
        
        // Attempt to write the image data to disk.
        do {
            try data.write(to: url)
        } catch let error {
            print("Error saving image: \(error) \n Image Name: \(imageName)")
        }
    }
    
    /// Retrieves an image from the specified folder.
    /// - Parameters:
    ///   - imageName: The name of the image file.
    ///   - folderName: The folder where the image is stored.
    /// - Returns: The loaded image, or `nil` if not found.
    func getImage(imageName: String, folderName: String) -> UIImage? {
        guard let url = getURLForImage(imageName: imageName, folderName: folderName),
              FileManager.default.fileExists(atPath: url.path) else {
            return nil
        }
        return UIImage(contentsOfFile: url.path)
    }
    
    /// Creates a folder in the caches directory if it does not already exist.
    /// - Parameter folderName: The name of the folder to create.
    private func createFolderIfNeeded(folderName: String) {
        guard let url = getURLForFolder(folderName: folderName) else { return }
        
        // Check if folder already exists.
        if !FileManager.default.fileExists(atPath: url.path) {
            do {
                try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
            } catch let error {
                print("Error creating directory: \(error) \n\n Folder Name: \(folderName)")
            }
        }
    }
    
    /// Retrieves the URL for the specified folder in the caches directory.
    /// - Parameter folderName: The folder name.
    /// - Returns: The URL for the folder, or `nil` if invalid.
    private func getURLForFolder(folderName: String) -> URL? {
        guard let url = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            return nil
        }
        return url.appendingPathComponent(folderName)
    }
    
    /// Retrieves the URL for the specified image within a folder.
    /// - Parameters:
    ///   - imageName: The name of the image file.
    ///   - folderName: The folder where the image resides.
    /// - Returns: The full URL for the image, or `nil` if invalid.
    private func getURLForImage(imageName: String, folderName: String) -> URL? {
        guard let folderURL = getURLForFolder(folderName: folderName) else {
            return nil
        }
        return folderURL.appendingPathComponent(imageName + ".png")
    }
}
