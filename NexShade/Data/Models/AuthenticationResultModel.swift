//
//  AuthenticationResultModel.swift
//  NexShade
//
//  Created by Ali Eren on 6.11.2025.
//


import Foundation
import SwiftData

@Model
final class AuthenticationResultModel {
    
    @Attribute(.unique) var id: UUID
    var deviceId: UUID
    var role: String
    var permissionRawValue: Int
    var authenticatedAt: Date
    var expiresAt: Date?
    
    init(
        id: UUID = UUID(),
        deviceId: UUID,
        role: String,
        permissionRawValue: Int,
        authenticatedAt: Date,
        expiresAt: Date? = nil
    ) {
        self.id = id
        self.deviceId = deviceId
        self.role = role
        self.permissionRawValue = permissionRawValue
        self.authenticatedAt = authenticatedAt
        self.expiresAt = expiresAt
    }
}