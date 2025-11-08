//
//  AuthenticationResult.swift
//  NexShade
//
//  Created by Ali Eren on 6.11.2025.
//

import Foundation

//struct AuthenticationResult {
//    let success: Bool
//    let error: AuthenticationError?
//    let role: UserRole
//    let permissions: Permissions
//    let authenticatedAt: Date?
//    let expiresAt: Date?
//    
//    enum AuthenticationError: Error {
//        case invalidSignature
//        case userNotFound
//        case userExpired
//        case rateLimited
//        case connectionLost
//    }
//    
//    init(
//        success: Bool,
//        error: AuthenticationError? = nil,
//        role: UserRole,
//        permissions: Permissions,
//        authenticatedAt: Date? = nil,
//        expiresAt: Date? = nil
//    ) {
//        self.success = success
//        self.error = error
//        self.role = role
//        self.permissions = permissions
//        self.authenticatedAt = authenticatedAt
//        self.expiresAt = expiresAt
//    }
//}

// Domain/Entities/AuthenticationResult.swift

import Foundation

struct AuthenticationResult: Equatable, Codable {
    let role: UserRole
    let permissions: Permissions
    let authenticatedAt: Date
    let expiresAt: Date?

    init(
        role: UserRole,
        permissions: Permissions,
        authenticatedAt: Date = Date(),
        expiresAt: Date? = nil
    ) {
        self.role = role
        self.permissions = permissions
        self.authenticatedAt = authenticatedAt
        self.expiresAt = expiresAt
    }

    var isExpired: Bool {
        guard let expiresAt = expiresAt else { return false }
        return Date() > expiresAt
    }

    var isValid: Bool { !isExpired }
}
