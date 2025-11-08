//
//  User.swift
//  NexShade
//
//  Created by Ali Eren on 6.11.2025.
//

import Foundation

struct User: Identifiable, Equatable, Hashable, Codable {
    let id: UUID
    var name: String
    let deviceId: UUID
    let role: UserRole
    var permissions: Permissions
    let createdAt: Date
    let expiresAt: Date?
    let publicKey: String
    var isActive: Bool
    var lastAccessed: Date?

    init(
        id: UUID = UUID(),
        name: String,
        deviceId: UUID,
        role: UserRole,
        permissions: Permissions,
        createdAt: Date = Date(),
        expiresAt: Date? = nil,
        publicKey: String,
        isActive: Bool = true,
        lastAccessed: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.deviceId = deviceId
        self.role = role
        self.permissions = permissions
        self.createdAt = createdAt
        self.expiresAt = expiresAt
        self.publicKey = publicKey
        self.isActive = isActive
        self.lastAccessed = lastAccessed
    }

    var isExpired: Bool {
        guard let expiresAt = expiresAt else { return false }
        return Date() > expiresAt
    }

    var isOwner: Bool { role == .owner }
}
