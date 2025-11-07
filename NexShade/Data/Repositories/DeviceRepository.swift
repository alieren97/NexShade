//
//  DeviceRepository.swift
//  NexShade
//
//  Created by Ali Eren on 6.11.2025.
//


// Data/Repositories/DeviceRepository.swift

final class DeviceRepository: DeviceRepositoryProtocol {
    
    // DEPENDENCY INJECTION - Data Sources
    private let bleDataSource: BLEDataSource
    private let localDataSource: CoreDataDataSource
    private let mapper: DeviceMapper
    
    init(
        bleDataSource: BLEDataSource,
        localDataSource: CoreDataDataSource,
        mapper: DeviceMapper
    ) {
        self.bleDataSource = bleDataSource
        self.localDataSource = localDataSource
        self.mapper = mapper
    }
    
    func getDevices() async throws -> [Device] {
        // Get from local storage
        let dtos = try await localDataSource.fetchDevices()
        return dtos.map { mapper.toDomain($0) }
    }
    
    func connect(to deviceId: UUID) async throws {
        try await bleDataSource.connect(to: deviceId)
    }
    
    func sendCommand(deviceId: UUID, command: PergolaCommand) async throws -> PergolaStatus {
        // Convert to BLE command
        let bleCommand = mapToBLECommand(command)
        
        // Send via BLE
        try await bleDataSource.writeCharacteristic(
            deviceId: deviceId,
            characteristic: .control,
            value: bleCommand
        )
        
        // Read response
        let statusDTO = try await bleDataSource.readCharacteristic(
            deviceId: deviceId,
            characteristic: .status
        )
        
        // Map to domain
        return mapper.statusToDomain(statusDTO)
    }
    
    func observeStatus(deviceId: UUID) -> AsyncStream<PergolaStatus> {
        AsyncStream { continuation in
            let task = Task {
                // Subscribe to BLE notifications
                for await statusDTO in bleDataSource.observeNotifications(
                    deviceId: deviceId,
                    characteristic: .status
                ) {
                    let status = mapper.statusToDomain(statusDTO)
                    continuation.yield(status)
                }
            }
            
            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }
    
    private func mapToBLECommand(_ command: PergolaCommand) -> Data {
        switch command {
        case .open:
            return "OPEN".data(using: .utf8)!
        case .close:
            return "CLOSE".data(using: .utf8)!
        case .stop:
            return "STOP".data(using: .utf8)!
        case .setPosition(let position):
            return "POSITION:\(position)".data(using: .utf8)!
        }
    }
}

// Data/DataSources/Remote/BLEDataSource.swift

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

// Data/Mappers/DeviceMapper.swift

struct DeviceMapper {
    
    // DTO → Domain Entity
    func toDomain(_ dto: DeviceDTO) -> Device {
        Device(
            id: dto.id,
            name: dto.name,
            macAddress: dto.macAddress,
            status: mapStatus(dto.status),
            connectionState: .disconnected,
            role: mapRole(dto.role),
            permissions: mapPermissions(dto.permissionRawValue)
        )
    }
    
    // Domain Entity → DTO
    func toDTO(_ domain: Device) -> DeviceDTO {
        DeviceDTO(
            id: domain.id,
            name: domain.name,
            macAddress: domain.macAddress,
            status: domain.status == .online ? "online" : "offline",
            role: domain.role.rawValue,
            permissionRawValue: domain.permissions.rawValue
        )
    }
    
    func statusToDomain(_ data: Data) -> PergolaStatus {
        // Parse BLE status data
        // Format: "Position: 75% (Moving)"
        let string = String(data: data, encoding: .utf8) ?? ""
        let position = extractPosition(from: string)
        let isMoving = string.contains("Moving")
        
        return PergolaStatus(
            position: position,
            isMoving: isMoving,
            direction: isMoving ? .opening : nil,
            lastUpdated: Date()
        )
    }
    
    private func extractPosition(from string: String) -> Int {
        // Extract number from "Position: 75%"
        let components = string.components(separatedBy: " ")
        guard components.count > 1,
              let percentString = components[1].components(separatedBy: "%").first,
              let position = Int(percentString) else {
            return 0
        }
        return position
    }
}