//
//  ControlPergolaUseCaseProtocol.swift
//  NexShade
//
//  Created by Ali Eren on 6.11.2025.
//

import Foundation

/// Use case for controlling pergola operations
protocol ControlPergolaUseCaseProtocol {
    func execute(deviceId: UUID, command: PergolaCommand) async throws -> PergolaStatus
}

final class ControlPergolaUseCase: ControlPergolaUseCaseProtocol {
    
    // MARK: - Dependencies
    
    private let deviceRepository: DeviceRepositoryProtocol
    private let authenticationRepository: AuthenticationRepositoryProtocol
    
    // MARK: - Initialization
    
    init(
        deviceRepository: DeviceRepositoryProtocol,
        authenticationRepository: AuthenticationRepositoryProtocol
    ) {
        self.deviceRepository = deviceRepository
        self.authenticationRepository = authenticationRepository
    }
    
    // MARK: - Execute
    
    /// Send control command to pergola
    /// - Parameters:
    ///   - deviceId: UUID of the device
    ///   - command: Command to execute
    /// - Returns: Updated pergola status after command
    /// - Throws: DomainError if command fails or permission denied
    func execute(deviceId: UUID, command: PergolaCommand) async throws -> PergolaStatus {
        // Step 1: Verify user has permission for this command
        let permissions = try await authenticationRepository.getPermissions(for: deviceId)
        
        guard canExecute(command: command, with: permissions) else {
            throw DomainError.permissionDenied(
                "You don't have permission to execute this command"
            )
        }
        
        // Step 2: Send command to device
        let status = try await deviceRepository.sendCommand(
            deviceId: deviceId,
            command: command
        )
        
        // Step 3: Log action for audit trail
        try await logAction(deviceId: deviceId, command: command)
        
        return status
    }
    
    // MARK: - Private Methods
    
    private func canExecute(command: PergolaCommand, with permissions: Permissions) -> Bool {
        switch command {
        case .open, .close, .stop:
            // Basic control requires at least basicControl permission
            return permissions.contains(.basicControl)
            
        case .setPosition:
            // Position control requires advanced permission
            return permissions.contains(.advancedControl)
        }
    }
    
    private func logAction(deviceId: UUID, command: PergolaCommand) async throws {
        // Log to audit repository
        // This could be another use case or repository call
        // For now, we'll keep it simple
    }
}
