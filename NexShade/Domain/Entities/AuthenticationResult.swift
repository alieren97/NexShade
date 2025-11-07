//
//  AuthenticationResult.swift
//  NexShade
//
//  Created by Ali Eren on 6.11.2025.
//

import Foundation

struct AuthenticationResult {
    let success: Bool
    let error: AuthenticationError?
    let role: UserRole
    let permissions: Permissions
    
    enum AuthenticationError: Error {
        case invalidSignature
        case userNotFound
        case userExpired
        case rateLimited
        case connectionLost
    }
}
