//
//  User.swift
//  NexShade
//
//  Created by Ali Eren on 6.11.2025.
//

import Foundation

struct User {
    let id: UUID
    let name: String
    let role: UserRole
    let permissions: Permissions
    let addedDate: Date
    let expiresAt: Date?
    let isActive: Bool
}
