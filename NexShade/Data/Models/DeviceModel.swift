//
//  DeviceModel.swift
//  NexShade
//
//  Created by Ali Eren on 7.11.2025.
//

import Foundation
import SwiftData

@Model
final class DeviceModel {
    @Attribute(.unique) var id: UUID
    var name: String
    var macAddress: String
    var connectionStateRaw: String
    var userRoleRaw: String
    var permissionRawValue: Int
    var isAuthenticated: Bool
    var lastConnected: Date?
    var createdAt: Date
    var updatedAt: Date
    
    init(
        id: UUID,
        name: String,
        macAddress: String,
        connectionStateRaw: String,
        userRoleRaw: String,
        permissionRawValue: Int,
        isAuthenticated: Bool,
        lastConnected: Date? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.macAddress = macAddress
        self.connectionStateRaw = connectionStateRaw
        self.userRoleRaw = userRoleRaw
        self.permissionRawValue = permissionRawValue
        self.isAuthenticated = isAuthenticated
        self.lastConnected = lastConnected
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
