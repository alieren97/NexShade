//
//  AuthenticationRepositoryProtocol.swift
//  NexShade
//
//  Created by Ali Eren on 6.11.2025.
//

import Foundation

protocol AuthenticationRepositoryProtocol {
    // Key Management
    func generateKeyPair() async throws -> KeyPair
    func getPrivateKey(for deviceId: UUID) async throws -> Data?
    func savePrivateKey(_ key: Data, for deviceId: UUID) async throws
    func deletePrivateKey(for deviceId: UUID) async throws

    // Authentication
    func hasCredentials(for deviceId: UUID) async throws -> Bool
    func authenticate(deviceId: UUID) async throws -> AuthenticationResult
    func signChallenge(_ challenge: Data, with privateKeyData: Data) async throws -> Data

    // Permissions
    func getPermissions(for deviceId: UUID) async throws -> Permissions
    func isOwner(of deviceId: UUID) async throws -> Bool
    
    // State
    func storeAuthResult(_ result: AuthenticationResult, for deviceId: UUID) async throws
    func clearAuthState(for deviceId: UUID) async throws
}
