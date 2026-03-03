//
//  CoinDetailDataService.swift
//  VirtuTrade
//
//  Created by Jasin ‎ on 11/11/24.
//

import Foundation
import Combine
import os

final class CoinDetailDataService {
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "me.marku.jasin.VirtuTrade",
        category: "CoinDetailDataService"
    )
    
    // The coin for which details are being fetched
    let coin: CoinModel
    
    enum CoinDetailServiceError: LocalizedError {
        case invalidCoinID
        case transport(URLError)
        case badStatusCode(statusCode: Int, bodySnippet: String)
        case decoding(DecodingError, bodySnippet: String)
        case networking(NetworkingManager.NetworkingError)
        case unknown(Error)
        
        var isCancellation: Bool {
            switch self {
            case .transport(let urlError):
                return urlError.code == .cancelled
            case .networking(let networkingError):
                if case .requestFailed(_, let underlying) = networkingError {
                    return underlying.code == .cancelled
                }
                return false
            case .unknown(let error):
                let nsError = error as NSError
                return nsError.domain == NSURLErrorDomain && nsError.code == URLError.cancelled.rawValue
            default:
                return false
            }
        }
        
        var userFacingMessage: String {
            switch self {
            case .invalidCoinID:
                return "This coin identifier is invalid."
            case .transport(let urlError):
                if urlError.code == .timedOut {
                    return "The request timed out. Please try again."
                }
                if urlError.code == .notConnectedToInternet {
                    return "No internet connection. Please reconnect and retry."
                }
                return "We couldn't reach CoinGecko right now."
            case .badStatusCode(let statusCode, _):
                if statusCode == 429 {
                    return "Too many requests right now. Please wait a moment and retry."
                }
                return "Coin details request failed with status \(statusCode)."
            case .decoding(_, let bodySnippet):
                if bodySnippet.lowercased().contains("rate limit") {
                    return "CoinGecko rate limit reached. Please retry in a moment."
                }
                return "Received unexpected data format from CoinGecko."
            case .networking(let error):
                return error.localizedDescription
            case .unknown:
                return "An unexpected error occurred while loading coin details."
            }
        }
        
        var errorDescription: String? {
            userFacingMessage
        }
    }
    
    // Initialize the service with a specific coin
    init(coin: CoinModel) {
        self.coin = coin
    }
    
    // Fetches details for the specific coin from the API.
    func getCoinDetails() -> AnyPublisher<CoinDetailModel, CoinDetailServiceError> {
        let trimmedCoinID = coin.id.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedCoinID.isEmpty,
              let encodedCoinID = trimmedCoinID.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let url = URL(string: "https://api.coingecko.com/api/v3/coins/\(encodedCoinID)?localization=false&tickers=false&market_data=false&community_data=false&developer_data=false&sparkline=false") else {
            logger.error("Coin detail request aborted: invalid coin id '\(self.coin.id, privacy: .public)'")
            return Fail(error: CoinDetailServiceError.invalidCoinID).eraseToAnyPublisher()
        }
        
        let start = Date()
        logger.notice("Coin detail request start coinID=\(trimmedCoinID, privacy: .public) url=\(url.absoluteString, privacy: .public)")
        
        return NetworkingManager.downloadResponse(url: url)
            .tryMap { [logger] response in
                let duration = Date().timeIntervalSince(start)
                logger.notice(
                    "Coin detail response coinID=\(trimmedCoinID, privacy: .public) status=\(response.statusCode, privacy: .public) elapsed=\(duration, privacy: .public)s"
                )
                
                guard (200...299).contains(response.statusCode) else {
                    let snippet = response.bodySnippet(maxLength: 200)
                    logger.error(
                        "Coin detail HTTP failure coinID=\(trimmedCoinID, privacy: .public) status=\(response.statusCode, privacy: .public) body=\(snippet, privacy: .public)"
                    )
                    throw CoinDetailServiceError.badStatusCode(statusCode: response.statusCode, bodySnippet: snippet)
                }
                
                do {
                    return try JSONDecoder().decode(CoinDetailModel.self, from: response.data)
                } catch let decodingError as DecodingError {
                    let snippet = response.bodySnippet(maxLength: 200)
                    logger.error(
                        "Coin detail decode failure coinID=\(trimmedCoinID, privacy: .public) error=\(String(describing: decodingError), privacy: .public) body=\(snippet, privacy: .public)"
                    )
                    throw CoinDetailServiceError.decoding(decodingError, bodySnippet: snippet)
                } catch {
                    throw CoinDetailServiceError.unknown(error)
                }
            }
            .mapError { [logger] error in
                let mappedError: CoinDetailServiceError
                
                if let serviceError = error as? CoinDetailServiceError {
                    mappedError = serviceError
                } else if let networkError = error as? NetworkingManager.NetworkingError {
                    mappedError = .networking(networkError)
                } else if let urlError = error as? URLError {
                    mappedError = .transport(urlError)
                } else {
                    mappedError = .unknown(error)
                }
                
                switch mappedError {
                case .transport(let urlError):
                    if urlError.code == .cancelled {
                        logger.debug("Coin detail request cancelled coinID=\(trimmedCoinID, privacy: .public)")
                    } else {
                        logger.error(
                            "Coin detail transport failure coinID=\(trimmedCoinID, privacy: .public) code=\(urlError.code.rawValue, privacy: .public) message=\(urlError.localizedDescription, privacy: .public)"
                        )
                    }
                case .networking(let networkingError):
                    logger.error("Coin detail networking failure coinID=\(trimmedCoinID, privacy: .public) message=\(networkingError.localizedDescription, privacy: .public)")
                case .badStatusCode, .decoding, .invalidCoinID:
                    break
                case .unknown(let unknownError):
                    logger.error("Coin detail unknown failure coinID=\(trimmedCoinID, privacy: .public) message=\(unknownError.localizedDescription, privacy: .public)")
                }
                
                return mappedError
            }
            .eraseToAnyPublisher()
    }
}
