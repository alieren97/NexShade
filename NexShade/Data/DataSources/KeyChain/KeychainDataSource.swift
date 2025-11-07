//
//  KeychainDataSource.swift
//  NexShade
//
//  Created by Ali Eren on 6.11.2025.
//


// Data/DataSources/Keychain/KeychainDataSource.swift

import Foundation
import Security
import OSLog

/// Data source for secure keychain storage
final class KeychainDataSource {
    
    // MARK: - Properties
    
    private let logger = Logger(subsystem: "com.pergola.keychain", category: "KeychainDataSource")
    private let service = "com.pergola.pergolacontrol"
    
    // MARK: - Public Methods
    
    /// Save private key to keychain
    func savePrivateKey(_ key: Data, for deviceId: UUID) throws {
        logger.info("Saving private key for device: \(deviceId)")
        
        let account = "privatekey-\(deviceId.uuidString)"
        
        // Delete existing key if present
        try? deletePrivateKey(for: deviceId)
        
        // Create query
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: key,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // Add to keychain
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            logger.error("Failed to save key: \(status)")
            throw KeychainError.saveFailed(status)
        }
        
        logger.info("Private key saved successfully")
    }
    
    /// Get private key from keychain
    func getPrivateKey(for deviceId: UUID) throws -> Data {
        logger.info("Retrieving private key for device: \(deviceId)")
        
        let account = "privatekey-\(deviceId.uuidString)"
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                logger.info("Private key not found")
                throw KeychainError.itemNotFound
            }
            logger.error("Failed to retrieve key: \(status)")
            throw KeychainError.retrieveFailed(status)
        }
        
        guard let data = result as? Data else {
            logger.error("Invalid key data")
            throw KeychainError.invalidData
        }
        
        logger.info("Private key retrieved successfully")
        return data
    }
    
    /// Delete private key from keychain
    func deletePrivateKey(for deviceId: UUID) throws {
        logger.info("Deleting private key for device: \(deviceId)")
        
        let account = "privatekey-\(deviceId.uuidString)"
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            logger.error("Failed to delete key: \(status)")
            throw KeychainError.deleteFailed(status)
        }
        
        logger.info("Private key deleted successfully")
    }
    
    /// Check if private key exists
    func keyExists(for deviceId: UUID) -> Bool {
        do {
            _ = try getPrivateKey(for: deviceId)
            return true
        } catch {
            return false
        }
    }
    
    /// Delete all keys for the app
    func deleteAllKeys() throws {
        logger.warning("Deleting all keychain items")
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            logger.error("Failed to delete all keys: \(status)")
            throw KeychainError.deleteFailed(status)
        }
        
        logger.info("All keys deleted successfully")
    }
}

// MARK: - Keychain Errors

enum KeychainError: LocalizedError {
    case saveFailed(OSStatus)
    case retrieveFailed(OSStatus)
    case deleteFailed(OSStatus)
    case itemNotFound
    case invalidData
    case unknown(OSStatus)
    
    var errorDescription: String? {
        switch self {
        case .saveFailed(let status):
            return "Failed to save to keychain (status: \(status))"
        case .retrieveFailed(let status):
            return "Failed to retrieve from keychain (status: \(status))"
        case .deleteFailed(let status):
            return "Failed to delete from keychain (status: \(status))"
        case .itemNotFound:
            return "Item not found in keychain"
        case .invalidData:
            return "Invalid data in keychain"
        case .unknown(let status):
            return "Unknown keychain error (status: \(status))"
        }
    }
}