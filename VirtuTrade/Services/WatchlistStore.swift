//
//  WatchlistStore.swift
//  VirtuTrade
//
//  Created by Codex on 3/3/26.
//

import Foundation
import Combine

@MainActor
final class WatchlistStore: ObservableObject {
    private enum StorageKeys {
        static let watchlistIDsData = "vt_watchlist_coin_ids_data"
    }
    
    @Published private(set) var ids: [String]
    
    private let defaults: UserDefaults
    
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.ids = Self.loadIDs(from: defaults)
    }
    
    func isWatchlisted(_ coinID: String) -> Bool {
        ids.contains(coinID)
    }
    
    func toggle(_ coinID: String) {
        guard !coinID.isEmpty else { return }
        
        if let index = ids.firstIndex(of: coinID) {
            ids.remove(at: index)
        } else {
            ids.append(coinID)
        }
        
        persist()
    }
    
    func remove(_ coinID: String) {
        guard let index = ids.firstIndex(of: coinID) else { return }
        ids.remove(at: index)
        persist()
    }
    
    private func persist() {
        do {
            let data = try JSONEncoder().encode(ids)
            defaults.set(data, forKey: StorageKeys.watchlistIDsData)
        } catch {
            defaults.removeObject(forKey: StorageKeys.watchlistIDsData)
        }
    }
    
    private static func loadIDs(from defaults: UserDefaults) -> [String] {
        guard let data = defaults.data(forKey: StorageKeys.watchlistIDsData) else {
            return []
        }
        
        guard let decoded = try? JSONDecoder().decode([String].self, from: data) else {
            return []
        }
        
        var seen = Set<String>()
        return decoded.compactMap { id in
            let trimmed = id.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty, seen.insert(trimmed).inserted else {
                return nil
            }
            return trimmed
        }
    }
}
