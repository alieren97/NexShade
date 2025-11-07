// Domain/UseCases/Device/ConnectToDeviceUseCase.swift

import Foundation

/// Use case for connecting to a device
protocol ConnectToDeviceUseCaseProtocol {
    func execute(deviceId: UUID) async throws -> Device
}

final class ConnectToDeviceUseCase: ConnectToDeviceUseCaseProtocol {
    
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
    
    /// Connect to a device and authenticate
    /// - Parameter deviceId: UUID of the device to connect to
    /// - Returns: Connected and authenticated device
    /// - Throws: DomainError if connection or authentication fails
    func execute(deviceId: UUID) async throws -> Device {
        // Step 1: Establish BLE connection
        try await deviceRepository.connect(to: deviceId)
        
        // Step 2: Discover services and characteristics
        try await deviceRepository.discoverServices(for: deviceId)
        
        // Step 3: Check if we have credentials for this device
        let hasCredentials = try await authenticationRepository.hasCredentials(for: deviceId)
        
        if hasCredentials {
            // Step 4: Authenticate with stored credentials
            let authResult = try await authenticationRepository.authenticate(deviceId: deviceId)
            
            // Step 5: Get device with updated state
            guard let device = try await deviceRepository.getDevice(id: deviceId) else {
                throw DomainError.deviceNotFound
            }
            
            // Update device with auth result
            var updatedDevice = device
            updatedDevice.isAuthenticated = true
            updatedDevice.userRole = authResult.role
            updatedDevice.permissions = authResult.permissions
            
            return updatedDevice
        } else {
            // Device is connected but not authenticated
            guard let device = try await deviceRepository.getDevice(id: deviceId) else {
                throw DomainError.deviceNotFound
            }
            
            return device
        }
    }
}