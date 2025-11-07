//
//  CreateInvitationUseCaseProtocol.swift
//  NexShade
//
//  Created by Ali Eren on 6.11.2025.
//


// Domain/UseCases/UserManagement/CreateInvitationUseCase.swift

import Foundation

/// Use case for creating guest access invitations
protocol CreateInvitationUseCaseProtocol {
    func execute(
        deviceId: UUID,
        permissions: Permissions,
        expiresAt: Date?,
        guestName: String?
    ) async throws -> Invitation
}

final class CreateInvitationUseCase: CreateInvitationUseCaseProtocol {
    
    // MARK: - Dependencies
    
    private let userRepository: UserRepositoryProtocol
    private let deviceRepository: DeviceRepositoryProtocol
    private let authenticationRepository: AuthenticationRepositoryProtocol
    
    // MARK: - Initialization
    
    init(
        userRepository: UserRepositoryProtocol,
        deviceRepository: DeviceRepositoryProtocol,
        authenticationRepository: AuthenticationRepositoryProtocol
    ) {
        self.userRepository = userRepository
        self.deviceRepository = deviceRepository
        self.authenticationRepository = authenticationRepository
    }
    
    // MARK: - Execute
    
    /// Create an invitation for guest access
    /// - Parameters:
    ///   - deviceId: UUID of the device
    ///   - permissions: Permissions to grant
    ///   - expiresAt: Optional expiration date
    ///   - guestName: Optional guest name
    /// - Returns: Created invitation with code
    /// - Throws: DomainError if creation fails
    func execute(
        deviceId: UUID,
        permissions: Permissions,
        expiresAt: Date?,
        guestName: String?
    ) async throws -> Invitation {
        // Step 1: Verify user is owner of this device
        let isOwner = try await authenticationRepository.isOwner(of: deviceId)
        guard isOwner else {
            throw DomainError.permissionDenied("Only owners can create invitations")
        }
        
        // Step 2: Validate permissions (can't grant higher than owner)
        guard !permissions.contains(.userManagement) else {
            throw DomainError.invalidInput("Cannot grant user management permission to guests")
        }
        
        // Step 3: Generate invitation code (8 characters)
        let code = generateInvitationCode()
        
        // Step 4: Create invitation entity
        let invitation = Invitation(
            id: UUID(),
            deviceId: deviceId,
            code: code,
            permissions: permissions,
            createdAt: Date(),
            expiresAt: expiresAt,
            guestName: guestName,
            isRedeemed: false
        )
        
        // Step 5: Send invitation to device
        try await deviceRepository.createInvitation(invitation)
        
        // Step 6: Store invitation locally
        try await userRepository.saveInvitation(invitation)
        
        return invitation
    }
    
    // MARK: - Private Methods
    
    private func generateInvitationCode() -> String {
        let characters = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
        return String((0..<8).map { _ in characters.randomElement()! })
    }
}