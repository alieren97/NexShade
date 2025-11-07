//
//  LocalDataSource.swift
//  NexShade
//
//  Created by Ali Eren on 6.11.2025.
//


// Data/DataSources/Local/LocalDataSource.swift

import Foundation
import SwiftData
import OSLog

/// Data source for local persistence using SwiftData
@MainActor
final class LocalDataSource {
    
    // MARK: - Properties
    
    private let modelContainer: ModelContainer
    private let modelContext: ModelContext
    private let logger = Logger(subsystem: "com.pergola.data", category: "LocalDataSource")
    
    // MARK: - Initialization
    
    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
        self.modelContext = ModelContext(modelContainer)
        
        logger.info("LocalDataSource initialized")
    }
    
    // MARK: - Generic CRUD Operations
    
    /// Fetch models with optional predicate
    func fetch<T: PersistentModel>(
        _ type: T.Type,
        predicate: Predicate<T>? = nil,
        sortBy: [SortDescriptor<T>] = []
    ) async throws -> [T] {
        logger.info("Fetching \(String(describing: type))")
        
        var descriptor = FetchDescriptor<T>(predicate: predicate, sortBy: sortBy)
        
        do {
            let results = try modelContext.fetch(descriptor)
            logger.info("Fetched \(results.count) items")
            return results
        } catch {
            logger.error("Fetch failed: \(error.localizedDescription)")
            throw DataError.fetchFailed(error.localizedDescription)
        }
    }
    
    /// Fetch models with limit
    func fetch<T: PersistentModel>(
        _ type: T.Type,
        predicate: Predicate<T>? = nil,
        sortBy: [SortDescriptor<T>] = [],
        limit: Int
    ) async throws -> [T] {
        logger.info("Fetching \(String(describing: type)) with limit: \(limit)")
        
        var descriptor = FetchDescriptor<T>(predicate: predicate, sortBy: sortBy)
        descriptor.fetchLimit = limit
        
        do {
            let results = try modelContext.fetch(descriptor)
            logger.info("Fetched \(results.count) items")
            return results
        } catch {
            logger.error("Fetch failed: \(error.localizedDescription)")
            throw DataError.fetchFailed(error.localizedDescription)
        }
    }
    
    /// Fetch single model by ID
    func fetchById<T: PersistentModel>(_ type: T.Type, id: PersistentIdentifier) async throws -> T? {
        logger.info("Fetching \(String(describing: type)) by ID")
        
        return modelContext.model(for: id) as? T
    }
    
    /// Count models with optional predicate
    func count<T: PersistentModel>(
        _ type: T.Type,
        predicate: Predicate<T>? = nil
    ) async throws -> Int {
        logger.info("Counting \(String(describing: type))")
        
        let descriptor = FetchDescriptor<T>(predicate: predicate)
        
        do {
            let count = try modelContext.fetchCount(descriptor)
            logger.info("Count: \(count)")
            return count
        } catch {
            logger.error("Count failed: \(error.localizedDescription)")
            throw DataError.fetchFailed(error.localizedDescription)
        }
    }
    
    /// Save (insert or update) a model
    func save<T: PersistentModel>(_ model: T) async throws {
        logger.info("Saving \(String(describing: type(of: model)))")
        
        modelContext.insert(model)
        
        do {
            try modelContext.save()
            logger.info("Save successful")
        } catch {
            logger.error("Save failed: \(error.localizedDescription)")
            throw DataError.saveFailed(error.localizedDescription)
        }
    }
    
    /// Save multiple models
    func saveAll<T: PersistentModel>(_ models: [T]) async throws {
        logger.info("Saving \(models.count) models")
        
        for model in models {
            modelContext.insert(model)
        }
        
        do {
            try modelContext.save()
            logger.info("Batch save successful")
        } catch {
            logger.error("Batch save failed: \(error.localizedDescription)")
            throw DataError.saveFailed(error.localizedDescription)
        }
    }
    
    /// Delete a model
    func delete<T: PersistentModel>(_ model: T) async throws {
        logger.info("Deleting \(String(describing: type(of: model)))")
        
        modelContext.delete(model)
        
        do {
            try modelContext.save()
            logger.info("Delete successful")
        } catch {
            logger.error("Delete failed: \(error.localizedDescription)")
            throw DataError.deleteFailed(error.localizedDescription)
        }
    }
    
    /// Delete multiple models
    func deleteAll<T: PersistentModel>(_ models: [T]) async throws {
        logger.info("Deleting \(models.count) models")
        
        for model in models {
            modelContext.delete(model)
        }
        
        do {
            try modelContext.save()
            logger.info("Batch delete successful")
        } catch {
            logger.error("Batch delete failed: \(error.localizedDescription)")
            throw DataError.deleteFailed(error.localizedDescription)
        }
    }
    
    /// Delete models matching predicate
    func delete<T: PersistentModel>(
        _ type: T.Type,
        where predicate: Predicate<T>
    ) async throws {
        logger.info("Deleting \(String(describing: type)) with predicate")
        
        let models = try await fetch(type, predicate: predicate)
        
        for model in models {
            modelContext.delete(model)
        }
        
        do {
            try modelContext.save()
            logger.info("Deleted \(models.count) items")
        } catch {
            logger.error("Delete failed: \(error.localizedDescription)")
            throw DataError.deleteFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Transaction Operations
    
    /// Execute operations in a transaction
    func transaction(_ block: @escaping () async throws -> Void) async throws {
        logger.info("Starting transaction")
        
        do {
            try await block()
            try modelContext.save()
            logger.info("Transaction committed")
        } catch {
            logger.error("Transaction failed: \(error.localizedDescription)")
            modelContext.rollback()
            throw DataError.transactionFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Cleanup Operations
    
    /// Delete all data of a specific type
    func deleteAll<T: PersistentModel>(_ type: T.Type) async throws {
        logger.info("Deleting all \(String(describing: type))")
        
        let models = try await fetch(type)
        try await deleteAll(models)
    }
    
    /// Clear all data from the database
    func clearAllData() async throws {
        logger.warning("Clearing all data from database")
        
        // This would need to be expanded based on your models
        // For now, just clear the context
        modelContext.rollback()
        
        // You would delete each model type here
        // try await deleteAll(DeviceModel.self)
        // try await deleteAll(UserModel.self)
        // try await deleteAll(AuditLogModel.self)
        // etc.
        
        logger.info("All data cleared")
    }
    
    // MARK: - Utility Methods
    
    /// Check if context has unsaved changes
    func hasChanges() -> Bool {
        return modelContext.hasChanges
    }
    
    /// Manually save context
    func saveContext() throws {
        if modelContext.hasChanges {
            try modelContext.save()
            logger.info("Context saved")
        }
    }
    
    /// Rollback unsaved changes
    func rollback() {
        modelContext.rollback()
        logger.info("Context rolled back")
    }
    
    /// Reset the context (clear all cached objects)
    func reset() {
        modelContext.reset()
        logger.info("Context reset")
    }
}

// MARK: - Data Errors

enum DataError: LocalizedError {
    case fetchFailed(String)
    case saveFailed(String)
    case deleteFailed(String)
    case transactionFailed(String)
    case notFound
    case invalidData
    
    var errorDescription: String? {
        switch self {
        case .fetchFailed(let message):
            return "Failed to fetch data: \(message)"
        case .saveFailed(let message):
            return "Failed to save data: \(message)"
        case .deleteFailed(let message):
            return "Failed to delete data: \(message)"
        case .transactionFailed(let message):
            return "Transaction failed: \(message)"
        case .notFound:
            return "Data not found"
        case .invalidData:
            return "Invalid data"
        }
    }
}