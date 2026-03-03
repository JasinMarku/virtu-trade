//
//  NetworkingManager.swift
//  VirtuTrade
//
//  Created by Jasin ‎ on 10/18/24.
//

import Foundation
import Combine
import os

enum NetworkingManager {
    struct HTTPDataResponse {
        let data: Data
        let response: HTTPURLResponse
        
        var statusCode: Int { response.statusCode }
        
        func bodySnippet(maxLength: Int = 200) -> String {
            guard maxLength > 0 else { return "" }
            
            if let utf8String = String(data: data, encoding: .utf8) {
                let compact = utf8String.replacingOccurrences(of: "\n", with: " ")
                    .replacingOccurrences(of: "\r", with: " ")
                return String(compact.prefix(maxLength))
            }
            
            return data.prefix(maxLength).map { String(format: "%02x", $0) }.joined()
        }
    }
    
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "me.marku.jasin.VirtuTrade",
        category: "Networking"
    )
    private static let session: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 20
        configuration.timeoutIntervalForResource = 60
        configuration.waitsForConnectivity = true
        return URLSession(configuration: configuration)
    }()
    
    /// Custom errors for network-related issues.
    enum NetworkingError: LocalizedError {
        case badURLResponse(url: URL, statusCode: Int) // Invalid HTTP response.
        case requestFailed(url: URL, underlying: URLError)
        case invalidImageData(url: URL)
        case unknown                  // General fallback error
        
        var errorDescription: String? {
            switch self {
            case .badURLResponse(url: let url, statusCode: let statusCode):
                return "[Network] Bad response (\(statusCode)) from URL: \(url)"
            case .requestFailed(url: let url, underlying: let error):
                return "[Network] Request failed for URL: \(url). \(error.localizedDescription)"
            case .invalidImageData(url: let url):
                return "[Network] Could not decode image data from URL: \(url)"
            case .unknown: return "[Network] Unknown error occurred."
            }
        }
    }
    
    /// Downloads data from the given URL, retrying up to 3 times on failure.
    static func download(url: URL) -> AnyPublisher<Data, Error> {
        downloadResponse(url: url)
            .tryMap { try handleURLResponse(output: $0, url: url) } // Validates the response
            .eraseToAnyPublisher()
    }
    
    /// Downloads raw HTTP data and response for callers that need status/body inspection.
    static func downloadResponse(url: URL) -> AnyPublisher<HTTPDataResponse, Error> {
        session.dataTaskPublisher(for: url)
            .mapError { NetworkingError.requestFailed(url: url, underlying: $0) as Error }
            .tryMap { output in
                guard let response = output.response as? HTTPURLResponse else {
                    throw NetworkingError.badURLResponse(url: url, statusCode: -1)
                }
                return HTTPDataResponse(data: output.data, response: response)
            }
            .retry(2) // Retries in case of transient failures
            .eraseToAnyPublisher()
    }
    
    /// Validates the HTTP response and extracts its data.
    static func handleURLResponse(output: HTTPDataResponse, url: URL) throws -> Data {
        guard output.statusCode >= 200 && output.statusCode < 300 else {
            let statusCode = output.statusCode
            throw NetworkingError.badURLResponse(url: url, statusCode: statusCode)
        }
        return output.data
    }
    
    /// Handles the completion state of a publisher, logging errors when necessary.
    static func handleCompletion(completion: Subscribers.Completion<Error>) {
        switch completion {
        case .finished:
            break
        case .failure(let error):
            logger.error("Network pipeline failed: \(error.localizedDescription, privacy: .public)")
        }
    }
}
