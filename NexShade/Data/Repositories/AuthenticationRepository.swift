//
//  AuthenticationRepository.swift
//  NexShade
//
//  Created by Ali Eren on 6.11.2025.
//

import Foundation
import CryptoKit
import OSLog

/// Concrete implementation of AuthenticationRepositoryProtocol
final class AuthenticationRepository: AuthenticationRepositoryProtocol {
    
    // MARK: - Dependencies
    
    private let bleDataSource: BLEDataSource
    private let keychainDataSource: KeychainDataSource
    private let localDataSource: LocalDataSource
    private let cryptoManager: CryptoManager
    
    // MARK: - Logger
    
    private let logger = Logger(subsystem: "com.pergola.auth", category: "AuthRepository")
    
    // MARK: - In-Memory Cache
    
    private var authStateCache: [UUID: AuthenticationResult] = [:]
    private var permissionsCache: [UUID: Permissions] = [:]
    
    // MARK: - Initialization
    
    init(
        bleDataSource: BLEDataSource,
        keychainDataSource: KeychainDataSource,
        localDataSource: LocalDataSource,
        cryptoManager: CryptoManager
    ) {
        self.bleDataSource = bleDataSource
        self.keychainDataSource = keychainDataSource
        self.localDataSource = localDataSource
        self.cryptoManager = cryptoManager
        
        logger.info("AuthenticationRepository initialized")
    }
    
    // MARK: - Key Management
    
    /// Generate a new ECDSA key pair
    func generateKeyPair() async throws -> KeyPair {
        logger.info("Generating new key pair")
        
        do {
            let keyPair = try cryptoManager.generateKeyPair()
            logger.info("Key pair generated successfully")
            return keyPair
        } catch {
            logger.error("Failed to generate key pair: \(error.localizedDescription)")
            throw DomainError.cryptoError("Failed to generate key pair: \(error.localizedDescription)")
        }
    }
    
    /// Get private key for a device from keychain
    func getPrivateKey(for deviceId: UUID) async throws -> Data? {
        logger.info("Retrieving private key for device: \(deviceId)")
        
        do {
            let key = try keychainDataSource.getPrivateKey(for: deviceId)
            logger.info("Private key retrieved successfully")
            return key
        } catch KeychainError.itemNotFound {
            logger.info("No private key found for device: \(deviceId)")
            return nil
        } catch {
            logger.error("Failed to retrieve private key: \(error.localizedDescription)")
            throw DomainError.cryptoError("Failed to retrieve private key")
        }
    }
    
    /// Save private key to keychain
    func savePrivateKey(_ key: Data, for deviceId: UUID) async throws {
        logger.info("Saving private key for device: \(deviceId)")
        
        do {
            try keychainDataSource.savePrivateKey(key, for: deviceId)
            logger.info("Private key saved successfully")
        } catch {
            logger.error("Failed to save private key: \(error.localizedDescription)")
            throw DomainError.cryptoError("Failed to save private key")
        }
    }
    
    /// Delete private key from keychain
    func deletePrivateKey(for deviceId: UUID) async throws {
        logger.info("Deleting private key for device: \(deviceId)")
        
        do {
            try keychainDataSource.deletePrivateKey(for: deviceId)
            logger.info("Private key deleted successfully")
            
            // Clear cached auth state
            authStateCache.removeValue(forKey: deviceId)
            permissionsCache.removeValue(forKey: deviceId)
            
        } catch {
            logger.error("Failed to delete private key: \(error.localizedDescription)")
            throw DomainError.cryptoError("Failed to delete private key")
        }
    }
    
    // MARK: - Authentication
    
    /// Check if credentials exist for a device
    func hasCredentials(for deviceId: UUID) async throws -> Bool {
        logger.info("Checking credentials for device: \(deviceId)")
        
        let exists = keychainDataSource.keyExists(for: deviceId)
        logger.info("Credentials exist: \(exists)")
        return exists
    }
    
    /// Authenticate with a device using challenge-response
    func authenticate(deviceId: UUID) async throws -> AuthenticationResult {
        logger.info("Authenticating with device: \(deviceId)")
        
        // Step 1: Check if we have cached auth state
        if let cachedResult = authStateCache[deviceId] {
            logger.info("Using cached authentication result")
            return cachedResult
        }
        
        // Step 2: Get private key
        guard let privateKeyData = try await getPrivateKey(for: deviceId) else {
            logger.error("No private key found for device")
            throw DomainError.authenticationFailed("No credentials found for this device")
        }
        
        // Step 3: Read challenge from device
        logger.info("Reading challenge from device")
        let challenge = try await bleDataSource.readChallenge(from: deviceId)
        
        // Step 4: Sign challenge
        logger.info("Signing challenge")
        let signature = try await signChallenge(challenge, with: privateKeyData)
        
        // Step 5: Send signature to device and get auth result
        logger.info("Sending signature to device")
        let authResult = try await bleDataSource.sendAuthResponse(
            deviceId: deviceId,
            signature: signature
        )
        
        // Step 6: Cache the result
        authStateCache[deviceId] = authResult
        permissionsCache[deviceId] = authResult.permissions
        
        // Step 7: Save to local database
        try await storeAuthResult(authResult, for: deviceId)
        
        logger.info("Authentication successful - Role: \(authResult.role.rawValue)")
        return authResult
    }
    
    /// Sign challenge with private key
    func signChallenge(_ challenge: Data, with privateKeyData: Data) async throws -> Data {
        logger.info("Signing challenge with private key")
        
        do {
            // Convert Data to PrivateKey
            let privateKey = try P256.Signing.PrivateKey(rawRepresentation: privateKeyData)
            
            // Sign the challenge
            let signature = try cryptoManager.sign(challenge, with: privateKey)
            
            logger.info("Challenge signed successfully")
            return signature
        } catch {
            logger.error("Failed to sign challenge: \(error.localizedDescription)")
            throw DomainError.cryptoError("Failed to sign challenge")
        }
    }
    
    // MARK: - Permissions
    
    /// Get permissions for a device
    func getPermissions(for deviceId: UUID) async throws -> Permissions {
        logger.info("Getting permissions for device: \(deviceId)")
        
        // Check cache first
        if let cachedPermissions = permissionsCache[deviceId] {
            logger.info("Using cached permissions")
            return cachedPermissions
        }
        
        // Try to get from database
        if let authResult = try await getStoredAuthResult(for: deviceId) {
            let permissions = authResult.permissions
            permissionsCache[deviceId] = permissions
            logger.info("Permissions retrieved from database")
            return permissions
        }
        
        logger.error("No permissions found for device")
        throw DomainError.authenticationFailed("Not authenticated with device")
    }
    
    /// Check if user is owner of a device
    func isOwner(of deviceId: UUID) async throws -> Bool {
        logger.info("Checking if user is owner of device: \(deviceId)")
        
        let permissions = try await getPermissions(for: deviceId)
        let isOwner = permissions.contains(.userManagement)
        
        logger.info("Is owner: \(isOwner)")
        return isOwner
    }
    
    // MARK: - Auth State
    
    /// Store authentication result
    func storeAuthResult(_ result: AuthenticationResult, for deviceId: UUID) async throws {
        logger.info("Storing auth result for device: \(deviceId)")
        
        // Update cache
        authStateCache[deviceId] = result
        permissionsCache[deviceId] = result.permissions
        
        // Save to database
        let model = AuthenticationResultModel(
            deviceId: deviceId,
            role: result.role.rawValue,
            permissionRawValue: result.permissions.rawValue,
            authenticatedAt: result.authenticatedAt,
            expiresAt: result.expiresAt
        )
        
        try await localDataSource.save(model)
        logger.info("Auth result stored successfully")
    }
    
    /// Clear authentication state for a device
    func clearAuthState(for deviceId: UUID) async throws {
        logger.info("Clearing auth state for device: \(deviceId)")
        
        // Clear cache
        authStateCache.removeValue(forKey: deviceId)
        permissionsCache.removeValue(forKey: deviceId)
        
        // Delete from database
        let predicate = #Predicate<AuthenticationResultModel> { model in
            model.deviceId == deviceId
        }
        
        let models = try await localDataSource.fetch(
            AuthenticationResultModel.self,
            predicate: predicate
        )
        
        for model in models {
            try await localDataSource.delete(model)
        }
        
        logger.info("Auth state cleared")
    }
    
    // MARK: - Private Methods
    
    /// Get stored authentication result from database
    private func getStoredAuthResult(for deviceId: UUID) async throws -> AuthenticationResult? {
        let predicate = #Predicate<AuthenticationResultModel> { model in
            model.deviceId == deviceId
        }
        
        let models = try await localDataSource.fetch(
            AuthenticationResultModel.self,
            predicate: predicate
        )
        
        guard let model = models.first else {
            return nil
        }
        
        // Convert model to domain entity
        return AuthenticationResult(
            role: UserRole(rawValue: model.role) ?? .guest,
            permissions: Permissions(rawValue: model.permissionRawValue),
            authenticatedAt: model.authenticatedAt,
            expiresAt: model.expiresAt
        )
    }
}
