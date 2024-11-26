//
//  NetworkingManager.swift
//  VirtuTrade
//
//  Created by Jasin ‎ on 10/18/24.
//

import Foundation
import Combine

class NetworkingManager {
    
    /// Custom errors for network-related issues.
    enum networkingError: LocalizedError {
        case badURLResponse(url: URL) // Invalid HTTP response.
        case unknown                  // General fallback error
        
        var errorDescription: String? {
            switch self {
            case .badURLResponse(url: let url): return "[🔥] Bad response from URL: \(url)"
            case .unknown: return "[⚠️] Unknown Error Occured..."
            }
        }
    }
    
    /// Downloads data from the given URL, retrying up to 3 times on failure.
    static func download(url: URL) -> AnyPublisher<Data, any Error> {
       return URLSession.shared.dataTaskPublisher(for: url)
             .tryMap({try handleURLResponse(output: $0, url: url)}) // Validates the response
             .retry(3) // Retries in case of transient faliures
             .eraseToAnyPublisher()
    }
    
    /// Validates the HTTP response and extracts its data.
    static func handleURLResponse(output: URLSession.DataTaskPublisher.Output, url: URL) throws -> Data {
        guard let response = output.response as? HTTPURLResponse,
              response.statusCode >= 200 && response.statusCode < 300 else {
            throw networkingError.badURLResponse(url: url)
        }
        return output.data
    }
    
    /// Handles the completion state of a publisher, logging errors when necessary.
    static func handleCompletion(completion: Subscribers.Completion<Error>) {
        switch completion {
        case .finished:
            break
        case .failure(let error):
            print(error.localizedDescription)
        }
    }
}
