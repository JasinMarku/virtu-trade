//
//  PortfolioDataService.swift
//  VirtuTrade
//
//  Created by Jasin ‎ on 10/30/24.
//

import Foundation
import CoreData

class PortfolioDataService {
    
    // Core Data container and configuration
    private let container: NSPersistentContainer
    private let containerName: String = "PortfolioContainer"
    private let entityName: String = "PortfolioEntity"
    
    // Published array of portfolio entities to notify subscribers about updates
    @Published var savedEntities: [PortfolioEntity] = []
    
    // Initializes the Core Data container and loads the saved portfolio
    init() {
        container = NSPersistentContainer(name: containerName)
        container.loadPersistentStores { _, error in
            if let error = error {
                print("Error Loading Core Data! \(error)")
            }
            self.getPortfolio() // Load initial portfolio data
        }
    }
    
    // MARK: PUBLIC METHODS
    
    /// Updates the portfolio based on the given coin and amount.
    /// - Parameters:
    ///   - coin: The `CoinModel` to add/update in the portfolio.
    ///   - amount: The amount of the coin to save; removes the coin if amount <= 0.
    func updatePortfolio(coin: CoinModel, amount: Double) {
        if let entity = savedEntities.first(where: { $0.coinID == coin.id }) {
            if amount > 0 {
                update(entity: entity, amount: amount)
            } else {
                delete(entity: entity)
            }
        } else {
            add(coin: coin, amount: amount)
        }
    }
    
    // MARK: PRIVATE METHODS
    
    /// Fetches the saved portfolio entities from Core Data.
    private func getPortfolio() {
        let request = NSFetchRequest<PortfolioEntity>(entityName: entityName)
        do {
            savedEntities = try container.viewContext.fetch(request)
        } catch let error {
            print("Error Fetching Portfolio Entities: \(error)")
        }
    }
    
    /// Adds a new coin to the portfolio.
    /// - Parameters:
    ///   - coin: The `CoinModel` to add.
    ///   - amount: The amount of the coin.
    private func add(coin: CoinModel, amount: Double) {
        let entity = PortfolioEntity(context: container.viewContext)
        entity.coinID = coin.id
        entity.amount = amount
        applyChanges() // Save changes and refresh portfolio
    }
    
    /// Updates an existing portfolio entity with a new amount.
    /// - Parameters:
    ///   - entity: The `PortfolioEntity` to update.
    ///   - amount: The new amount to save.
    private func update(entity: PortfolioEntity, amount: Double) {
        entity.amount = amount
        applyChanges() // Save changes and refresh portfolio
    }
    
    /// Deletes a coin from the portfolio.
    /// - Parameter entity: The `PortfolioEntity` to delete.
    private func delete(entity: PortfolioEntity) {
        container.viewContext.delete(entity)
        applyChanges() // Save changes and refresh portfolio
    }
    
    /// Saves changes to the Core Data context.
    private func save() {
        do {
            try container.viewContext.save()
        } catch let error {
            print("Error saving to CoreData: \(error)")
        }
    }

    /// Saves changes and reloads the portfolio.
    private func applyChanges() {
        save()
        getPortfolio()
    }
}
