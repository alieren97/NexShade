//
//  BLEDataSource.swift
//  NexShade
//
//  Created by Ali Eren on 6.11.2025.
//

import Foundation
import CoreBluetooth
import OSLog

/// Protocol for BLE data source (enables testing and swapping implementations)
protocol BLEDataSourceProtocol {
    // Connection
    func connect(to deviceId: UUID) async throws
    func disconnect(from deviceId: UUID) async throws
    func discoverServices(for deviceId: UUID) async throws
    
    // Authentication
    func readChallenge(from deviceId: UUID) async throws -> Data
    func sendAuthResponse(deviceId: UUID, signature: Data) async throws -> AuthenticationResult
    
    // Control
    func sendCommand(deviceId: UUID, command: PergolaCommand) async throws
    
    // Status
    func readStatus(from deviceId: UUID) async throws -> PergolaStatus
    func observeStatusUpdates(for deviceId: UUID) -> AsyncStream<PergolaStatus>
    
    // Invitations (for owner)
    func createInvitation(deviceId: UUID, invitation: Invitation) async throws
    
    // Service (for technician)
    func startServiceSession(deviceId: UUID) async throws
    func endServiceSession(deviceId: UUID) async throws

    func startScanning() -> AsyncStream<BLEDevice>
    func stopScan()
    func isScanning() -> AsyncStream<Bool>
}

/// BLE data source - translates domain operations to BLE characteristic operations
final class BLEDataSource: BLEDataSourceProtocol {
    
    // MARK: - Dependencies
    
    private let connectionManager: BLEConnectionManager
    private let characteristicManager: BLECharacteristicManager
    private let logger = Logger(subsystem: "com.pergola.data", category: "BLEDataSource")
    
    // MARK: - Initialization
    
    init(
        connectionManager: BLEConnectionManager,
        characteristicManager: BLECharacteristicManager
    ) {
        self.connectionManager = connectionManager
        self.characteristicManager = characteristicManager
        logger.info("BLEDataSource initialized")
    }
    
    // MARK: - Connection
    
    func connect(to deviceId: UUID) async throws {
        logger.info("Connecting to device: \(deviceId)")
        try await connectionManager.connect(to: deviceId)
    }
    
    func disconnect(from deviceId: UUID) async throws {
        logger.info("Disconnecting from device: \(deviceId)")
        try await connectionManager.disconnect(from: deviceId)
    }
    
    func discoverServices(for deviceId: UUID) async throws {
        logger.info("Discovering services for device: \(deviceId)")
        
        guard let peripheral = connectionManager.getPeripheral(for: deviceId) else {
            throw DataSourceError.deviceNotConnected
        }
        
        // Discover all pergola characteristics
        try await characteristicManager.discoverPergolaCharacteristics(for: peripheral)
    }
    
    // MARK: - Authentication
    
    func readChallenge(from deviceId: UUID) async throws -> Data {
        logger.info("Reading authentication challenge from device: \(deviceId)")
        
        guard let peripheral = connectionManager.getPeripheral(for: deviceId) else {
            throw DataSourceError.deviceNotConnected
        }
        
        let challengeData = try await characteristicManager.read(
            characteristic: BLEConfiguration.Characteristic.authChallenge.uuid,
            from: deviceId,
            peripheral: peripheral
        )
        
        logger.info("Challenge read successfully (\(challengeData.count) bytes)")
        return challengeData
    }
    
    func sendAuthResponse(deviceId: UUID, signature: Data) async throws -> AuthenticationResult {
        logger.info("Sending authentication response to device: \(deviceId)")
        
        guard let peripheral = connectionManager.getPeripheral(for: deviceId) else {
            throw DataSourceError.deviceNotConnected
        }
        
        // Send signature
        try await characteristicManager.write(
            signature,
            to: BLEConfiguration.Characteristic.authResponse.uuid,
            device: deviceId,
            peripheral: peripheral,
            withResponse: true
        )
        
        // Read response (role and permissions)
        // Assuming the device sends back role and permissions in status characteristic
        let responseData = try await characteristicManager.read(
            characteristic: BLEConfiguration.Characteristic.status.uuid,
            from: deviceId,
            peripheral: peripheral
        )
        
        // Parse authentication result
        let result = try parseAuthenticationResult(from: responseData)
        
        logger.info("Authentication successful - Role: \(result.role.rawValue)")
        return result
    }
    
    // MARK: - Control
    
    func sendCommand(deviceId: UUID, command: PergolaCommand) async throws {
        logger.info("Sending command to device: \(deviceId) - \(command.description)")

        guard let peripheral = connectionManager.getPeripheral(for: deviceId) else {
            throw DataSourceError.deviceNotConnected
        }
        
        // Encode command
        guard let commandData = command.description.data(using: .utf8) else {
            throw DataSourceError.invalidData
        }
        
        // Send command
        try await characteristicManager.write(
            commandData,
            to: BLEConfiguration.Characteristic.control.uuid,
            device: deviceId,
            peripheral: peripheral,
            withResponse: true
        )
        
        logger.info("Command sent successfully")
    }
    
    // MARK: - Status
    
    func readStatus(from deviceId: UUID) async throws -> PergolaStatus {
        logger.info("Reading status from device: \(deviceId)")
        
        guard let peripheral = connectionManager.getPeripheral(for: deviceId) else {
            throw DataSourceError.deviceNotConnected
        }
        
        let statusData = try await characteristicManager.read(
            characteristic: BLEConfiguration.Characteristic.status.uuid,
            from: deviceId,
            peripheral: peripheral
        )
        
        // Parse status
        let status = try parseStatus(from: statusData)
        
        logger.info("Status read: position \(status.position)%")
        return status
    }
    
    func observeStatusUpdates(for deviceId: UUID) -> AsyncStream<PergolaStatus> {
        logger.info("Observing status updates for device: \(deviceId)")
        
        guard let peripheral = connectionManager.getPeripheral(for: deviceId) else {
            return AsyncStream { continuation in
                continuation.finish()
            }
        }
        
        return AsyncStream { continuation in
            Task {
                do {
                    // Subscribe to status notifications
                    let dataStream = try await characteristicManager.subscribe(
                        to: BLEConfiguration.Characteristic.status.uuid,
                        device: deviceId,
                        peripheral: peripheral
                    )
                    
                    // Parse and emit status updates
                    for await data in dataStream {
                        if let status = try? parseStatus(from: data) {
                            continuation.yield(status)
                        }
                    }
                    
                    continuation.finish()
                } catch {
                    logger.error("Failed to observe status: \(error.localizedDescription)")
                    continuation.finish()
                }
            }
        }
    }
    
    // MARK: - Invitations
    
    func createInvitation(deviceId: UUID, invitation: Invitation) async throws {
        logger.info("Creating invitation on device: \(deviceId)")
        
        guard let peripheral = connectionManager.getPeripheral(for: deviceId) else {
            throw DataSourceError.deviceNotConnected
        }
        
        // Encode invitation data
        let invitationData = try encodeInvitation(invitation)
        
        // Send to device (using control characteristic or dedicated invitation characteristic)
        try await characteristicManager.write(
            invitationData,
            to: BLEConfiguration.Characteristic.control.uuid,
            device: deviceId,
            peripheral: peripheral,
            withResponse: true
        )
        
        logger.info("Invitation created successfully")
    }
    
    // MARK: - Service Session
    
    func startServiceSession(deviceId: UUID) async throws {
        logger.info("Starting service session on device: \(deviceId)")
        
        guard let peripheral = connectionManager.getPeripheral(for: deviceId) else {
            throw DataSourceError.deviceNotConnected
        }
        
        let command = "START_SERVICE".data(using: .utf8)!
        
        try await characteristicManager.write(
            command,
            to: BLEConfiguration.Characteristic.control.uuid,
            device: deviceId,
            peripheral: peripheral,
            withResponse: true
        )
        
        logger.info("Service session started")
    }
    
    func endServiceSession(deviceId: UUID) async throws {
        logger.info("Ending service session on device: \(deviceId)")
        
        guard let peripheral = connectionManager.getPeripheral(for: deviceId) else {
            throw DataSourceError.deviceNotConnected
        }
        
        let command = "END_SERVICE".data(using: .utf8)!
        
        try await characteristicManager.write(
            command,
            to: BLEConfiguration.Characteristic.control.uuid,
            device: deviceId,
            peripheral: peripheral,
            withResponse: true
        )
        
        logger.info("Service session ended")
    }
    
    // MARK: - Private Parsing Methods
    
    private func parseAuthenticationResult(from data: Data) throws -> AuthenticationResult {
        // Parse the data according to your protocol
        // Example: "ROLE:OWNER;PERMISSIONS:31"
        
        guard let string = String(data: data, encoding: .utf8) else {
            throw DataSourceError.invalidData
        }
        
        let components = string.components(separatedBy: ";")
        var role: UserRole = .guest
        var permissions: Permissions = []
        
        for component in components {
            let parts = component.components(separatedBy: ":")
            guard parts.count == 2 else { continue }
            
            switch parts[0] {
            case "ROLE":
                role = UserRole(rawValue: parts[1].lowercased()) ?? .guest
            case "PERMISSIONS":
                if let rawValue = Int(parts[1]) {
                    permissions = Permissions(rawValue: rawValue)
                }
            default:
                break
            }
        }
        
        return AuthenticationResult(role: role, permissions: permissions)
    }
    
    private func parseStatus(from data: Data) throws -> PergolaStatus {
        // Parse status according to your protocol
        // Example: "Position: 75% (Moving)"
        
        guard let string = String(data: data, encoding: .utf8) else {
            throw DataSourceError.invalidData
        }
        
        // Simple parsing - adjust to your actual protocol
        let components = string.components(separatedBy: " ")
        
        // Extract position
        var position = 0
        var isMoving = false
        
        if let positionString = components.first(where: { $0.hasSuffix("%") }) {
            let numString = positionString.replacingOccurrences(of: "%", with: "")
            position = Int(numString) ?? 0
        }
        
        if string.contains("Moving") {
            isMoving = true
        }
        
        return PergolaStatus(
            position: position,
            isMoving: isMoving,
            direction: nil,
            lastUpdated: Date()
        )
    }
    
    private func encodeInvitation(_ invitation: Invitation) throws -> Data {
        // Encode invitation according to your protocol
        // Example: "INVITE;CODE:\(code);PERMISSIONS:\(permissions);EXPIRES:\(date)"
        
        var string = "INVITE;CODE:\(invitation.code);PERMISSIONS:\(invitation.permissions.rawValue)"
        
        if let expiresAt = invitation.expiresAt {
            let timestamp = Int(expiresAt.timeIntervalSince1970)
            string += ";EXPIRES:\(timestamp)"
        }
        
        guard let data = string.data(using: .utf8) else {
            throw DataSourceError.encodingFailed
        }
        
        return data
    }

    func isScanning() -> AsyncStream<Bool> {
        return connectionManager.observeIsScanning()
    }
}

// MARK: - Scan
extension BLEDataSource {

    func startScanning() -> AsyncStream<BLEDevice> {
        return connectionManager.startScanning()
    }

    func stopScan() {
        connectionManager.stopScanning()
    }
}

// MARK: - Data Source Errors

enum DataSourceError: LocalizedError {
    case deviceNotConnected
    case invalidData
    case encodingFailed
    case decodingFailed
    case characteristicNotAvailable
    
    var errorDescription: String? {
        switch self {
        case .deviceNotConnected:
            return "Device is not connected"
        case .invalidData:
            return "Received invalid data from device"
        case .encodingFailed:
            return "Failed to encode data"
        case .decodingFailed:
            return "Failed to decode data"
        case .characteristicNotAvailable:
            return "Required characteristic not available"
        }
    }
}
