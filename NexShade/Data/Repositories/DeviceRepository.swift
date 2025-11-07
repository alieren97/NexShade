//
//  DeviceRepository.swift
//  NexShade
//
//  Created by Ali Eren on 6.11.2025.
//

import Foundation
import OSLog

final class DeviceRepository: DeviceRepositoryProtocol {
    
    // MARK: - Dependencies (CORRECTED!)
    
    private let bleDataSource: BLEDataSourceProtocol
    private let localDataSource: LocalDataSource
    private let mapper: DeviceMapper
    private let logger = Logger(subsystem: "com.pergola", category: "DeviceRepository")
    
    // MARK: - Initialization
    
    init(
        bleDataSource: BLEDataSourceProtocol,
        localDataSource: LocalDataSource,
        mapper: DeviceMapper = DeviceMapper()
    ) {
        self.bleDataSource = bleDataSource
        self.localDataSource = localDataSource
        self.mapper = mapper
    }
    
    // MARK: - Device Management
    
    func getDevices() async throws -> [Device] {
        // Fetch from SwiftData
        let models = try await localDataSource.fetch(DeviceModel.self)
        return models.map { mapper.toDomain($0) }
    }
    
    func getDevice(id: UUID) async throws -> Device? {
        let predicate = #Predicate<DeviceModel> { $0.id == id }
        let models = try await localDataSource.fetch(DeviceModel.self, predicate: predicate)
        return models.first.map { mapper.toDomain($0) }
    }
    
    func saveDevice(_ device: Device) async throws {
        let model = mapper.toModel(device)
        try await localDataSource.save(model)
    }
    
    func deleteDevice(id: UUID) async throws {
        let predicate = #Predicate<DeviceModel> { $0.id == id }
        try await localDataSource.delete(DeviceModel.self, where: predicate)
    }
    
    // MARK: - Connection
    
    func connect(to deviceId: UUID) async throws {
        try await bleDataSource.connect(to: deviceId)
    }
    
    func disconnect(from deviceId: UUID) async throws {
        try await bleDataSource.disconnect(from: deviceId)
    }
    
    func discoverServices(for deviceId: UUID) async throws {
        try await bleDataSource.discoverServices(for: deviceId)
    }
    
    // MARK: - Control
    
    func sendCommand(deviceId: UUID, command: PergolaCommand) async throws -> PergolaStatus {
        try await bleDataSource.sendCommand(deviceId: deviceId, command: command)
        return try await bleDataSource.readStatus(from: deviceId)
    }
    
    // MARK: - Status
    
    func getStatus(for deviceId: UUID) async throws -> PergolaStatus {
        return try await bleDataSource.readStatus(from: deviceId)
    }
    
    func observeStatus(for deviceId: UUID) -> AsyncStream<PergolaStatus> {
        return bleDataSource.observeStatusUpdates(for: deviceId)
    }
    
    func readChallenge(from deviceId: UUID) async throws -> Data {
        return try await bleDataSource.readChallenge(from: deviceId)
    }
    
    func sendAuthResponse(deviceId: UUID, signature: Data) async throws -> AuthenticationResult {
        return try await bleDataSource.sendAuthResponse(deviceId: deviceId, signature: signature)
    }
}
