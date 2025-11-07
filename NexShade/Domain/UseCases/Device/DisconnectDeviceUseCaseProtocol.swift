//
//  DisconnectDeviceUseCaseProtocol.swift
//  NexShade
//
//  Created by Ali Eren on 6.11.2025.
//


// Domain/UseCases/Device/DisconnectDeviceUseCase.swift

import Foundation

/// Use case for disconnecting from a device
protocol DisconnectDeviceUseCaseProtocol {
    /// Disconnect from a device
    /// - Parameter deviceId: UUID of the device to disconnect from
    /// - Throws: DomainError if disconnection fails
    func execute(deviceId: UUID) async throws
}

final class DisconnectDeviceUseCase: DisconnectDeviceUseCaseProtocol {
    
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
    
    /// Disconnect from a device and clean up resources
    /// - Parameter deviceId: UUID of the device to disconnect from
    /// - Throws: DomainError if disconnection fails
    func execute(deviceId: UUID) async throws {
        // Step 1: Log the disconnection action
        await logDisconnectionAction(deviceId: deviceId)
        
        // Step 2: Clear authentication state
        try await authenticationRepository.clearAuthState(for: deviceId)
        
        // Step 3: Disconnect from BLE device
        try await deviceRepository.disconnect(from: deviceId)
        
        // Step 4: Update device state locally
        try await updateDeviceState(deviceId: deviceId)
    }
    
    // MARK: - Private Methods
    
    /// Log the disconnection action for audit trail
    private func logDisconnectionAction(deviceId: UUID) async {
        // This could call an audit log repository
        // For now, we'll keep it simple
        print("Disconnecting from device: \(deviceId)")
    }
    
    /// Update device state after disconnection
    private func updateDeviceState(deviceId: UUID) async throws {
        guard var device = try await deviceRepository.getDevice(id: deviceId) else {
            // Device not found locally, that's okay
            return
        }
        
        // Update connection state
        device.connectionState = .disconnected
        device.isAuthenticated = false
        device.lastDisconnected = Date()
        
        // Save updated device
        try await deviceRepository.saveDevice(device)
    }
}