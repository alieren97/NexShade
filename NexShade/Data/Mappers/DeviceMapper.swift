//
//  DeviceMapper.swift
//  NexShade
//
//  Created by Ali Eren on 6.11.2025.
//

import Foundation

struct DeviceMapper {
    
    // MARK: - BLEDevice → Device (for use in UI/business logic)
    func toDomain(_ bleDevice: BLEDevice) -> Device {
        Device(
            id: bleDevice.id,
            name: bleDevice.name ?? "Pergola Device",
            macAddress: bleDevice.id.uuidString, // Use UUID as fallback for MAC
            connectionState: .disconnected,
            lastConnected: nil,
            lastDisconnected: nil,
            currentStatus: nil,
            userRole: .guest,
            permissions: [],
            isAuthenticated: false,
            firmwareVersion: nil,
            hardwareVersion: nil,
            serialNumber: nil,
            createdAt: bleDevice.discoveredAt,
            updatedAt: bleDevice.discoveredAt
        )
    }
    
    // MARK: - DeviceModel → Device (for loading from database)
    func toDomain(_ model: DeviceModel) -> Device {
        Device(
            id: model.id,
            name: model.name,
            macAddress: model.macAddress,
            connectionState: ConnectionState(rawValue: model.connectionStateRaw) ?? .disconnected,
            lastConnected: model.lastConnected,
            lastDisconnected: nil,
            currentStatus: nil,
            userRole: UserRole(rawValue: model.userRoleRaw) ?? .guest,
            permissions: Permissions(rawValue: model.permissionRawValue),
            isAuthenticated: model.isAuthenticated,
            firmwareVersion: nil,
            hardwareVersion: nil,
            serialNumber: nil,
            createdAt: model.createdAt,
            updatedAt: model.updatedAt
        )
    }
    
    // MARK: - Device → DeviceModel (for saving to database)
    func toModel(_ domain: Device) -> DeviceModel {
        DeviceModel(
            id: domain.id,
            name: domain.name,
            macAddress: domain.macAddress,
            connectionStateRaw: domain.connectionState.rawValue,
            userRoleRaw: domain.userRole.rawValue,
            permissionRawValue: domain.permissions.rawValue,
            isAuthenticated: domain.isAuthenticated,
            lastConnected: domain.lastConnected,
            createdAt: domain.createdAt,
            updatedAt: domain.updatedAt
        )
    }
    
    // MARK: - BLE Status Data → PergolaStatus (for status parsing)
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
