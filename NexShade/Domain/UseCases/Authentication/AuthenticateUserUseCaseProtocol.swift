//
//  AuthenticateUserUseCaseProtocol.swift
//  NexShade
//
//  Created by Ali Eren on 6.11.2025.
//


// Domain/UseCases/Authentication/AuthenticateUserUseCase.swift

import Foundation

/// Use case for authenticating with a device
protocol AuthenticateUserUseCaseProtocol {
    func execute(deviceId: UUID) async throws -> AuthenticationResult
}

final class AuthenticateUserUseCase: AuthenticateUserUseCaseProtocol {
    
    // MARK: - Dependencies
    
    private let authenticationRepository: AuthenticationRepositoryProtocol
    private let deviceRepository: DeviceRepositoryProtocol
    
    // MARK: - Initialization
    
    init(
        authenticationRepository: AuthenticationRepositoryProtocol,
        deviceRepository: DeviceRepositoryProtocol
    ) {
        self.authenticationRepository = authenticationRepository
        self.deviceRepository = deviceRepository
    }
    
    // MARK: - Execute
    
    /// Authenticate user with device using challenge-response
    /// - Parameter deviceId: UUID of the device
    /// - Returns: Authentication result with role and permissions
    /// - Throws: DomainError if authentication fails
    func execute(deviceId: UUID) async throws -> AuthenticationResult {
        // Step 1: Get private key from keychain
        guard let privateKey = try await authenticationRepository.getPrivateKey(for: deviceId) else {
            throw DomainError.authenticationFailed("No credentials found for this device")
        }
        
        // Step 2: Read challenge from device
        let challenge = try await deviceRepository.readChallenge(from: deviceId)
        
        // Step 3: Sign challenge with private key
        let signature = try await authenticationRepository.signChallenge(
            challenge,
            with: privateKey
        )
        
        // Step 4: Send signature to device
        let authResult = try await deviceRepository.sendAuthResponse(
            deviceId: deviceId,
            signature: signature
        )
        
        // Step 5: Store authentication result
        try await authenticationRepository.storeAuthResult(authResult, for: deviceId)
        
        return authResult
    }
}