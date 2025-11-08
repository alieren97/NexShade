//
//  ConnectToDeviceUseCaseProtocol.swift
//  NexShade
//
//  Created by Ali Eren on 6.11.2025.
//

import Foundation

protocol ConnectToDeviceUseCaseProtocol {
    func execute(deviceId: UUID) async throws -> Device
}

final class ConnectToDeviceUseCase: ConnectToDeviceUseCaseProtocol {

    private let deviceRepository: DeviceRepositoryProtocol
    private let authenticationRepository: AuthenticationRepositoryProtocol

    init(
        deviceRepository: DeviceRepositoryProtocol,
        authenticationRepository: AuthenticationRepositoryProtocol
    ) {
        self.deviceRepository = deviceRepository
        self.authenticationRepository = authenticationRepository
    }

    func execute(deviceId: UUID) async throws -> Device {
        // ✅ Just call connect - repository handles state transitions
        try await deviceRepository.connect(to: deviceId)

        // ✅ Get updated device (repository updated the state)
        guard var device = try await deviceRepository.getDevice(id: deviceId) else {
            throw DomainError.deviceNotFound
        }

        // ✅ Authenticate if we have credentials
        if try await authenticationRepository.hasCredentials(for: deviceId) {
            let authResult = try await authenticationRepository.authenticate(deviceId: deviceId)

            // Update auth state
            device.isAuthenticated = true
            device.userRole = authResult.role
            device.permissions = authResult.permissions
            device.updatedAt = Date()

            // Save updated device
            try await deviceRepository.saveDevice(device)
        }

        return device
    }
}
