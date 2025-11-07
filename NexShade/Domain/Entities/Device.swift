//
//  Device.swift
//  NexShade
//
//  Created by Ali Eren on 6.11.2025.
//

import Foundation

/// Device entity - represents a pergola control device
struct Device: Identifiable, Equatable, Hashable {
    
    // MARK: - Identity
    
    let id: UUID
    var name: String
    let macAddress: String
    
    // MARK: - Connection State
    
    var connectionState: ConnectionState
    var lastConnected: Date?
    var lastDisconnected: Date?
    
    // MARK: - Current Status
    
    var currentStatus: PergolaStatus?
    
    // MARK: - User's Relationship with Device
    
    /// The role this user has with this device (owner, guest, service tech)
    var userRole: UserRole
    
    /// The permissions this user has for this device
    var permissions: Permissions
    
    /// Whether the user is currently authenticated with this device
    var isAuthenticated: Bool
    
    // MARK: - Device Info
    
    var firmwareVersion: String?
    var hardwareVersion: String?
    var serialNumber: String?
    
    // MARK: - Metadata
    
    let createdAt: Date
    var updatedAt: Date
    
    // MARK: - Initialization
    
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
    
    // MARK: - Computed Properties
    
    /// Whether the device is currently connected
    var isConnected: Bool {
        connectionState == .ready
    }
    
    /// Whether the user is the owner of this device
    var isOwner: Bool {
        userRole == .owner
    }
    
    /// Whether the user is a service technician
    var isServiceTechnician: Bool {
        userRole == .serviceTechnician
    }
    
    /// Whether the user can control the device
    var canControl: Bool {
        isAuthenticated && permissions.contains(.basicControl)
    }
    
    /// Whether the user can manage other users
    var canManageUsers: Bool {
        isAuthenticated && permissions.contains(.userManagement)
    }
    
    /// Display name for the device
    var displayName: String {
        name.isEmpty ? "Pergola Device" : name
    }
}

