//
//  Device.swift
//  NexShade
//
//  Created by Ali Eren on 6.11.2025.
//

import Foundation

struct Device: Identifiable, Equatable, Hashable {
    let id: UUID
    var name: String
    let macAddress: String
    var connectionState: ConnectionState
    var lastConnected: Date?
    var lastDisconnected: Date?
    var currentStatus: PergolaStatus?
    var userRole: UserRole
    var permissions: Permissions
    var isAuthenticated: Bool
    var firmwareVersion: String?
    var hardwareVersion: String?
    var serialNumber: String?
    let createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        macAddress: String,
        connectionState: ConnectionState = .disconnected,
        lastConnected: Date? = nil,
        lastDisconnected: Date? = nil,
        currentStatus: PergolaStatus? = nil,
        userRole: UserRole = .guest,
        permissions: Permissions = [],
        isAuthenticated: Bool = false,
        firmwareVersion: String? = nil,
        hardwareVersion: String? = nil,
        serialNumber: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.macAddress = macAddress
        self.connectionState = connectionState
        self.lastConnected = lastConnected
        self.lastDisconnected = lastDisconnected
        self.currentStatus = currentStatus
        self.userRole = userRole
        self.permissions = permissions
        self.isAuthenticated = isAuthenticated
        self.firmwareVersion = firmwareVersion
        self.hardwareVersion = hardwareVersion
        self.serialNumber = serialNumber
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(name)
        hasher.combine(macAddress)
    }

    static func == (lhs: Device, rhs: Device) -> Bool {
        lhs.id == rhs.id &&
        lhs.name == rhs.name &&
        lhs.macAddress == rhs.macAddress &&
        lhs.connectionState == rhs.connectionState &&
        lhs.currentStatus == rhs.currentStatus &&
        lhs.userRole == rhs.userRole &&
        lhs.permissions == rhs.permissions &&
        lhs.isAuthenticated == rhs.isAuthenticated
    }

    var isConnected: Bool { connectionState == .ready }
    var isOwner: Bool { userRole == .owner }
    var canControl: Bool { isAuthenticated && permissions.contains(.basicControl) }
    var canManageUsers: Bool { isAuthenticated && permissions.contains(.userManagement) }
    var displayName: String { name.isEmpty ? "Pergola Device" : name }
}

//enum ConnectionState: String, Codable, Equatable, Hashable {
//    case disconnected, scanning, connecting
//    case discoveringServices, discoveringCharacteristics
//    case ready, disconnecting, error
//
//    var isConnected: Bool { self == .ready }
//    var description: String {
//        switch self {
//        case .disconnected: return "Disconnected"
//        case .scanning: return "Scanning..."
//        case .connecting: return "Connecting..."
//        case .discoveringServices: return "Discovering services..."
//        case .discoveringCharacteristics: return "Setting up..."
//        case .ready: return "Connected"
//        case .disconnecting: return "Disconnecting..."
//        case .error: return "Connection Error"
//        }
//    }
//}
