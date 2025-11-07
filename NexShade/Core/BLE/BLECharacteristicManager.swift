import Foundation
import CoreBluetooth
import Observation
import OSLog

/// Manages BLE characteristic operations (read, write, notify)
@MainActor
final class BLECharacteristicManager: NSObject {
    
    // MARK: - Private Properties
    
    private let logger = Logger(subsystem: "com.pergola.ble", category: "CharacteristicManager")
    
    // Storage for discovered characteristics
    private var characteristicsByDevice: [UUID: [CBUUID: CBCharacteristic]] = [:]
    
    // Continuations for async operations
    private var readContinuations: [UUID: CheckedContinuation<Data, Error>] = [:]
    private var writeContinuations: [UUID: CheckedContinuation<Void, Error>] = [:]
    private var notificationContinuations: [UUID: AsyncStream<Data>.Continuation] = [:]
    
    // Discovery continuations
    private var serviceDiscoveryContinuations: [UUID: CheckedContinuation<Void, Error>] = [:]
    private var characteristicDiscoveryContinuations: [UUID: CheckedContinuation<Void, Error>] = [:]
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        logger.info("BLECharacteristicManager initialized")
    }
    
    // MARK: - Service Discovery
    
    /// Discover services for a peripheral
    /// - Parameters:
    ///   - peripheral: The peripheral to discover services on
    ///   - serviceUUIDs: Optional array of service UUIDs to discover (nil = all)
    /// - Throws: BLEError if discovery fails
    func discoverServices(
        for peripheral: CBPeripheral,
        serviceUUIDs: [CBUUID]? = nil
    ) async throws {
        logger.info("Discovering services for device: \(peripheral.identifier)")
        
        // Set delegate
        peripheral.delegate = self
        
        return try await withThrowingTaskGroup(of: Void.self) { group in
            // Add timeout
            group.addTask {
                try await Task.sleep(for: .seconds(BLEConfiguration.discoveryTimeout))
                throw BLEError.operationTimeout
            }
            
            // Add discovery task
            group.addTask {
                try await withCheckedThrowingContinuation { continuation in
                    self.serviceDiscoveryContinuations[peripheral.identifier] = continuation
                    peripheral.discoverServices(serviceUUIDs)
                }
            }
            
            // Wait for first to complete
            try await group.next()
            group.cancelAll()
        }
    }
    
    /// Discover characteristics for a service
    /// - Parameters:
    ///   - peripheral: The peripheral
    ///   - characteristicUUIDs: Optional array of characteristic UUIDs (nil = all)
    ///   - service: The service to discover characteristics for
    /// - Throws: BLEError if discovery fails
    func discoverCharacteristics(
        for peripheral: CBPeripheral,
        characteristicUUIDs: [CBUUID]? = nil,
        service: CBService
    ) async throws {
        logger.info("Discovering characteristics for service: \(service.uuid)")
        
        return try await withThrowingTaskGroup(of: Void.self) { group in
            // Add timeout
            group.addTask {
                try await Task.sleep(for: .seconds(BLEConfiguration.discoveryTimeout))
                throw BLEError.operationTimeout
            }
            
            // Add discovery task
            group.addTask {
                try await withCheckedThrowingContinuation { continuation in
                    self.characteristicDiscoveryContinuations[peripheral.identifier] = continuation
                    peripheral.discoverCharacteristics(characteristicUUIDs, for: service)
                }
            }
            
            // Wait for first to complete
            try await group.next()
            group.cancelAll()
        }
    }
    
    /// Discover all required characteristics for pergola service
    /// - Parameter peripheral: The peripheral
    /// - Throws: BLEError if discovery fails
    func discoverPergolaCharacteristics(for peripheral: CBPeripheral) async throws {
        logger.info("Discovering pergola characteristics for device: \(peripheral.identifier)")
        
        // First discover the pergola service
        try await discoverServices(
            for: peripheral,
            serviceUUIDs: [BLEConfiguration.pergolaServiceUUID]
        )
        
        // Find the pergola service
        guard let service = peripheral.services?.first(where: {
            $0.uuid == BLEConfiguration.pergolaServiceUUID
        }) else {
            throw BLEError.serviceNotFound(BLEConfiguration.pergolaServiceUUID)
        }
        
        // Discover all characteristics
        let allCharacteristics: [CBUUID] = [
            BLEConfiguration.Characteristic.authChallenge.uuid,
            BLEConfiguration.Characteristic.authResponse.uuid,
            BLEConfiguration.Characteristic.control.uuid,
            BLEConfiguration.Characteristic.status.uuid,
            BLEConfiguration.Characteristic.notification.uuid
        ]
        
        try await discoverCharacteristics(
            for: peripheral,
            characteristicUUIDs: allCharacteristics,
            service: service
        )
        
        // Store discovered characteristics
        if let characteristics = service.characteristics {
            var deviceCharacteristics: [CBUUID: CBCharacteristic] = [:]
            for characteristic in characteristics {
                deviceCharacteristics[characteristic.uuid] = characteristic
            }
            characteristicsByDevice[peripheral.identifier] = deviceCharacteristics
            
            logger.info("Discovered \(characteristics.count) characteristics")
        }
    }
    
    // MARK: - Read Operations
    
    /// Read value from a characteristic
    /// - Parameters:
    ///   - characteristicUUID: UUID of the characteristic to read
    ///   - deviceId: UUID of the device
    ///   - peripheral: The peripheral
    /// - Returns: Data read from the characteristic
    /// - Throws: BLEError if read fails
    func read(
        characteristic characteristicUUID: CBUUID,
        from deviceId: UUID,
        peripheral: CBPeripheral
    ) async throws -> Data {
        logger.info("Reading characteristic: \(characteristicUUID)")
        
        // Find the characteristic
        guard let characteristic = characteristicsByDevice[deviceId]?[characteristicUUID] else {
            throw BLEError.characteristicNotFound(characteristicUUID)
        }
        
        // Check if readable
        guard characteristic.properties.contains(.read) else {
            throw BLEError.readFailed("Characteristic not readable")
        }
        
        return try await withThrowingTaskGroup(of: Data.self) { group in
            // Add timeout
            group.addTask {
                try await Task.sleep(for: .seconds(BLEConfiguration.operationTimeout))
                throw BLEError.operationTimeout
            }
            
            // Add read task
            group.addTask {
                try await withCheckedThrowingContinuation { continuation in
                    self.readContinuations[deviceId] = continuation
                    peripheral.readValue(for: characteristic)
                }
            }
            
            // Wait for first to complete
            guard let result = try await group.next() else {
                throw BLEError.readFailed("No result")
            }
            
            group.cancelAll()
            return result
        }
    }
    
    // MARK: - Write Operations
    
    /// Write value to a characteristic
    /// - Parameters:
    ///   - data: Data to write
    ///   - characteristicUUID: UUID of the characteristic
    ///   - deviceId: UUID of the device
    ///   - peripheral: The peripheral
    ///   - withResponse: Whether to wait for write response
    /// - Throws: BLEError if write fails
    func write(
        _ data: Data,
        to characteristicUUID: CBUUID,
        device deviceId: UUID,
        peripheral: CBPeripheral,
        withResponse: Bool = true
    ) async throws {
        logger.info("Writing to characteristic: \(characteristicUUID), data length: \(data.count)")
        
        // Find the characteristic
        guard let characteristic = characteristicsByDevice[deviceId]?[characteristicUUID] else {
            throw BLEError.characteristicNotFound(characteristicUUID)
        }
        
        // Check if writable
        let requiredProperty: CBCharacteristicProperties = withResponse ? .write : .writeWithoutResponse
        guard characteristic.properties.contains(requiredProperty) else {
            throw BLEError.writeFailed("Characteristic not writable")
        }
        
        if withResponse {
            // Write with response - wait for callback
            return try await withThrowingTaskGroup(of: Void.self) { group in
                // Add timeout
                group.addTask {
                    try await Task.sleep(for: .seconds(BLEConfiguration.operationTimeout))
                    throw BLEError.operationTimeout
                }
                
                // Add write task
                group.addTask {
                    try await withCheckedThrowingContinuation { continuation in
                        self.writeContinuations[deviceId] = continuation
                        peripheral.writeValue(data, for: characteristic, type: .withResponse)
                    }
                }
                
                // Wait for first to complete
                try await group.next()
                group.cancelAll()
            }
        } else {
            // Write without response - no callback
            peripheral.writeValue(data, for: characteristic, type: .withoutResponse)
        }
    }
    
    // MARK: - Notification Operations
    
    /// Subscribe to characteristic notifications
    /// - Parameters:
    ///   - characteristicUUID: UUID of the characteristic
    ///   - deviceId: UUID of the device
    ///   - peripheral: The peripheral
    /// - Returns: AsyncStream of data updates
    /// - Throws: BLEError if subscription fails
    func subscribe(
        to characteristicUUID: CBUUID,
        device deviceId: UUID,
        peripheral: CBPeripheral
    ) async throws -> AsyncStream<Data> {
        logger.info("Subscribing to notifications: \(characteristicUUID)")
        
        // Find the characteristic
        guard let characteristic = characteristicsByDevice[deviceId]?[characteristicUUID] else {
            throw BLEError.characteristicNotFound(characteristicUUID)
        }
        
        // Check if notifiable
        guard characteristic.properties.contains(.notify) else {
            throw BLEError.notificationFailed("Characteristic does not support notifications")
        }
        
        // Set notify
        peripheral.setNotifyValue(true, for: characteristic)
        
        // Return stream
        return AsyncStream { continuation in
            self.notificationContinuations[deviceId] = continuation
            
            continuation.onTermination = { @Sendable [weak self] _ in
                Task { @MainActor in
                    // Unsubscribe when stream is terminated
                    peripheral.setNotifyValue(false, for: characteristic)
                    self?.notificationContinuations.removeValue(forKey: deviceId)
                }
            }
        }
    }
    
    /// Unsubscribe from characteristic notifications
    /// - Parameters:
    ///   - characteristicUUID: UUID of the characteristic
    ///   - deviceId: UUID of the device
    ///   - peripheral: The peripheral
    func unsubscribe(
        from characteristicUUID: CBUUID,
        device deviceId: UUID,
        peripheral: CBPeripheral
    ) {
        logger.info("Unsubscribing from notifications: \(characteristicUUID)")
        
        guard let characteristic = characteristicsByDevice[deviceId]?[characteristicUUID] else {
            return
        }
        
        peripheral.setNotifyValue(false, for: characteristic)
        notificationContinuations[deviceId]?.finish()
        notificationContinuations.removeValue(forKey: deviceId)
    }
    
    // MARK: - Utility
    
    /// Check if a characteristic is available
    /// - Parameters:
    ///   - characteristicUUID: UUID of the characteristic
    ///   - deviceId: UUID of the device
    /// - Returns: True if characteristic is discovered and available
    func hasCharacteristic(_ characteristicUUID: CBUUID, for deviceId: UUID) -> Bool {
        return characteristicsByDevice[deviceId]?[characteristicUUID] != nil
    }
    
    /// Clear cached characteristics for a device
    /// - Parameter deviceId: UUID of the device
    func clearCharacteristics(for deviceId: UUID) {
        characteristicsByDevice.removeValue(forKey: deviceId)
        logger.info("Cleared characteristics for device: \(deviceId)")
    }
}

// MARK: - CBPeripheralDelegate

extension BLECharacteristicManager: CBPeripheralDelegate {
    
    nonisolated func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverServices error: Error?
    ) {
        Task { @MainActor in
            let deviceId = peripheral.identifier
            
            if let error = error {
                self.logger.error("Service discovery failed: \(error.localizedDescription)")
                let bleError = BLEError.unknown(error.localizedDescription)
                self.serviceDiscoveryContinuations[deviceId]?.resume(throwing: bleError)
            } else {
                self.logger.info("Discovered services: \(peripheral.services?.count ?? 0)")
                self.serviceDiscoveryContinuations[deviceId]?.resume()
            }
            
            self.serviceDiscoveryContinuations.removeValue(forKey: deviceId)
        }
    }
    
    nonisolated func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverCharacteristicsFor service: CBService,
        error: Error?
    ) {
        Task { @MainActor in
            let deviceId = peripheral.identifier
            
            if let error = error {
                self.logger.error("Characteristic discovery failed: \(error.localizedDescription)")
                let bleError = BLEError.unknown(error.localizedDescription)
                self.characteristicDiscoveryContinuations[deviceId]?.resume(throwing: bleError)
            } else {
                self.logger.info("Discovered characteristics: \(service.characteristics?.count ?? 0)")
                self.characteristicDiscoveryContinuations[deviceId]?.resume()
            }
            
            self.characteristicDiscoveryContinuations.removeValue(forKey: deviceId)
        }
    }
    
    nonisolated func peripheral(
        _ peripheral: CBPeripheral,
        didUpdateValueFor characteristic: CBCharacteristic,
        error: Error?
    ) {
        Task { @MainActor in
            let deviceId = peripheral.identifier
            
            if let error = error {
                self.logger.error("Read/notification failed: \(error.localizedDescription)")
                let bleError = BLEError.readFailed(error.localizedDescription)
                self.readContinuations[deviceId]?.resume(throwing: bleError)
                self.readContinuations.removeValue(forKey: deviceId)
                return
            }
            
            guard let data = characteristic.value else {
                self.logger.error("No data in characteristic value")
                let bleError = BLEError.invalidData
                self.readContinuations[deviceId]?.resume(throwing: bleError)
                self.readContinuations.removeValue(forKey: deviceId)
                return
            }
            
            self.logger.info("Received data: \(data.count) bytes")
            
            // Check if this is a read response or notification
            if let continuation = self.readContinuations[deviceId] {
                // This was a read operation
                continuation.resume(returning: data)
                self.readContinuations.removeValue(forKey: deviceId)
            } else if let continuation = self.notificationContinuations[deviceId] {
                // This is a notification
                continuation.yield(data)
            }
        }
    }
    
    nonisolated func peripheral(
        _ peripheral: CBPeripheral,
        didWriteValueFor characteristic: CBCharacteristic,
        error: Error?
    ) {
        Task { @MainActor in
            let deviceId = peripheral.identifier
            
            if let error = error {
                self.logger.error("Write failed: \(error.localizedDescription)")
                let bleError = BLEError.writeFailed(error.localizedDescription)
                self.writeContinuations[deviceId]?.resume(throwing: bleError)
            } else {
                self.logger.info("Write successful")
                self.writeContinuations[deviceId]?.resume()
            }
            
            self.writeContinuations.removeValue(forKey: deviceId)
        }
    }
    
    nonisolated func peripheral(
        _ peripheral: CBPeripheral,
        didUpdateNotificationStateFor characteristic: CBCharacteristic,
        error: Error?
    ) {
        Task { @MainActor in
            if let error = error {
                self.logger.error("Notification state update failed: \(error.localizedDescription)")
            } else {
                let state = characteristic.isNotifying ? "enabled" : "disabled"
                self.logger.info("Notifications \(state) for characteristic: \(characteristic.uuid)")
            }
        }
    }
    
    nonisolated func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        Task { @MainActor in
            if let error = error {
                self.logger.error("RSSI read failed: \(error.localizedDescription)")
            } else {
                self.logger.info("RSSI: \(RSSI) dBm")
            }
        }
    }
}