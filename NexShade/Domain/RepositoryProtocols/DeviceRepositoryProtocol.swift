//
//  DeviceRepositoryProtocol.swift
//  NexShade
//
//  Created by Ali Eren on 6.11.2025.
//

import Foundation


/// Minimal device repository protocol - core device operations only
/// Authentication, users, and invitations are handled by separate repositories
protocol DeviceRepositoryProtocol {
    
    // MARK: - Local Storage
    
    func getDevices() async throws -> [Device]
    func getDevice(id: UUID) async throws -> Device?
    func saveDevice(_ device: Device) async throws
    func deleteDevice(id: UUID) async throws
        
    // MARK: - Connection
    
    func connect(to deviceId: UUID) async throws
    func disconnect(from deviceId: UUID) async throws
    func discoverServices(for deviceId: UUID) async throws
    
    // MARK: - Control
    
    func sendCommand(deviceId: UUID, command: PergolaCommand) async throws -> PergolaStatus
    
    // MARK: - Status
    
    func getStatus(for deviceId: UUID) async throws -> PergolaStatus
    func observeStatus(for deviceId: UUID) -> AsyncStream<PergolaStatus>
    
    func readChallenge(from deviceId: UUID) async throws -> Data
    func sendAuthResponse(deviceId: UUID, signature: Data) async throws -> AuthenticationResult
}
