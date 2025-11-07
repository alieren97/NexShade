//
//  DeviceMapper.swift
//  NexShade
//
//  Created by Ali Eren on 6.11.2025.
//



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
