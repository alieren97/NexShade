//
//  enum.swift
//  NexShade
//
//  Created by Ali Eren on 7.11.2025.
//


// Domain/Entities/UserRole.swift

import Foundation

/// User role enum
enum UserRole: String, Codable, Equatable, CaseIterable {
    case owner
    case guest
    case serviceTechnician
    
    /// Default permissions for this role
    var defaultPermissions: Permissions {
        switch self {
        case .owner:
            return .owner
        case .guest:
            return .basicGuest
        case .serviceTechnician:
            return .serviceTechnician
        }
    }
    
    /// Display name
    var displayName: String {
        switch self {
        case .owner:
            return "Owner"
        case .guest:
            return "Guest"
        case .serviceTechnician:
            return "Service Technician"
        }
    }
    
    /// Icon name
    var iconName: String {
        switch self {
        case .owner:
            return "crown.fill"
        case .guest:
            return "person.fill"
        case .serviceTechnician:
            return "wrench.and.screwdriver.fill"
        }
    }
}