//
//  TradeHistoryStore.swift
//  VirtuTrade
//
//  Created by Codex on 3/3/26.
//

import Foundation
import Combine

enum TradeType: String, Codable, CaseIterable {
    case buy
    case sell
}

struct TradeModel: Identifiable, Codable {
    let id: UUID
    let coinID: String
    let symbol: String
    let name: String
    let type: TradeType
    let quantity: Double
    let priceAtExecution: Double
    let totalValue: Double
    let timestamp: Date
}

struct TradePositionSnapshot {
    let quantity: Double
    let averageCost: Double
}

@MainActor
final class TradeHistoryStore: ObservableObject {
    private enum StorageKeys {
        static let tradeHistoryData = "vt_trade_history"
    }
    
    @Published private(set) var trades: [TradeModel]
    
    private let defaults: UserDefaults
    private let holdingEpsilon: Double = 0.00000001
    
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.trades = Self.loadTrades(from: defaults)
    }
    
    func addTrade(trade: TradeModel) {
        trades.append(trade)
        trades.sort { $0.timestamp > $1.timestamp }
        persist()
    }
    
    func getTrades() -> [TradeModel] {
        trades
    }
    
    func getTrades(for coinID: String) -> [TradeModel] {
        trades.filter { $0.coinID == coinID }
    }
    
    func clearTrades() {
        trades = []
        defaults.removeObject(forKey: StorageKeys.tradeHistoryData)
    }
    
    func position(for coinID: String) -> TradePositionSnapshot {
        let orderedTrades = getTrades(for: coinID).sorted { $0.timestamp < $1.timestamp }
        var quantity: Double = 0
        var averageCost: Double = 0
        
        for trade in orderedTrades {
            let tradeQuantity = max(trade.quantity, 0)
            guard tradeQuantity > 0 else { continue }
            
            switch trade.type {
            case .buy:
                let newQuantity = quantity + tradeQuantity
                guard newQuantity > 0 else { continue }
                
                let totalCost = (quantity * averageCost) + (tradeQuantity * trade.priceAtExecution)
                quantity = newQuantity
                averageCost = totalCost / newQuantity
            case .sell:
                quantity = max(quantity - tradeQuantity, 0)
                if quantity <= holdingEpsilon {
                    quantity = 0
                    averageCost = 0
                }
            }
        }
        
        return TradePositionSnapshot(quantity: quantity, averageCost: averageCost)
    }
    
    private func persist() {
        do {
            let data = try JSONEncoder().encode(trades)
            defaults.set(data, forKey: StorageKeys.tradeHistoryData)
        } catch {
            defaults.removeObject(forKey: StorageKeys.tradeHistoryData)
        }
    }
    
    private static func loadTrades(from defaults: UserDefaults) -> [TradeModel] {
        guard let data = defaults.data(forKey: StorageKeys.tradeHistoryData) else {
            return []
        }
        
        guard let decoded = try? JSONDecoder().decode([TradeModel].self, from: data) else {
            return []
        }
        
        return decoded.sorted { $0.timestamp > $1.timestamp }
    }
}
