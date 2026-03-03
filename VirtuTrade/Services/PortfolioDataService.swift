//
//  PortfolioDataService.swift
//  VirtuTrade
//
//  Created by Jasin ‎ on 10/30/24.
//

import Foundation
import CoreData
import os

@MainActor
final class PortfolioDataService {
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "me.marku.jasin.VirtuTrade",
        category: "PortfolioDataService"
    )
    
    // Core Data container and configuration
    private let container: NSPersistentContainer
    private let containerName: String = "PortfolioContainer"
    private let entityName: String = "PortfolioEntity"
    
    // Published array of portfolio entities to notify subscribers about updates
    @Published var savedEntities: [PortfolioEntity] = []
    
    // Initializes the Core Data container and loads the saved portfolio
    init() {
        container = NSPersistentContainer(name: containerName)
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.automaticallyMergesChangesFromParent = true

        container.loadPersistentStores { [weak self] _, error in
            guard let self else { return }
            if let error {
                self.logger.error("Error loading Core Data persistent stores: \(error.localizedDescription, privacy: .public)")
            }

            Task { @MainActor in
                self.getPortfolio() // Load initial portfolio data
            }
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
        } else if amount > 0 {
            add(coin: coin, amount: amount)
        }
    }
    
    /// Deletes all holdings from persistence.
    func removeAllPortfolio() {
        savedEntities.forEach { container.viewContext.delete($0) }
        applyChanges()
    }
    
    // MARK: PRIVATE METHODS
    
    /// Fetches the saved portfolio entities from Core Data.
    private func getPortfolio() {
        let request = NSFetchRequest<PortfolioEntity>(entityName: entityName)
        do {
            savedEntities = try container.viewContext.fetch(request)
        } catch let error {
            logger.error("Error fetching portfolio entities: \(error.localizedDescription, privacy: .public)")
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
        guard container.viewContext.hasChanges else { return }
        do {
            try container.viewContext.save()
        } catch let error {
            logger.error("Error saving Core Data context: \(error.localizedDescription, privacy: .public)")
        }
    }

    /// Saves changes and reloads the portfolio.
    private func applyChanges() {
        save()
        getPortfolio()
    }
}
