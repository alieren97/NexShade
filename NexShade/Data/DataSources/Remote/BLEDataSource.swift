//
//  BLEDataSource.swift
//  NexShade
//
//  Created by Ali Eren on 6.11.2025.
//

import Foundation

final class BLEDataSource {
    
    private let connectionManager: BLEConnectionManager
    private let characteristicManager: BLECharacteristicManager
    
    init(
        connectionManager: BLEConnectionManager,
        characteristicManager: BLECharacteristicManager
    ) {
        self.connectionManager = connectionManager
        self.characteristicManager = characteristicManager
    }
    
    func connect(to deviceId: UUID) async throws {
        try await connectionManager.connect(to: deviceId)
    }
    
    func writeCharacteristic(
        deviceId: UUID,
        characteristic: BLECharacteristic,
        value: Data
    ) async throws {
        try await characteristicManager.write(
            to: characteristic,
            value: value,
            for: deviceId
        )
    }
    
    func readCharacteristic(
        deviceId: UUID,
        characteristic: BLECharacteristic
    ) async throws -> Data {
        try await characteristicManager.read(
            from: characteristic,
            for: deviceId
        )
    }
    
    func observeNotifications(
        deviceId: UUID,
        characteristic: BLECharacteristic
    ) -> AsyncStream<Data> {
        characteristicManager.observeNotifications(
            for: characteristic,
            deviceId: deviceId
        )
    }
}
