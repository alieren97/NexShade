//
//  enum.swift
//  NexShade
//
//  Created by Ali Eren on 7.11.2025.
//

import Foundation

enum UserRole: String, Codable, Equatable, CaseIterable {
    case owner, guest, serviceTechnician

    var defaultPermissions: Permissions {
        switch self {
        case .owner: return .owner
        case .guest: return .basicGuest
        case .serviceTechnician: return .serviceTechnician
        }
    }

    var displayName: String {
        switch self {
        case .owner: return "Owner"
        case .guest: return "Guest"
        case .serviceTechnician: return "Service Technician"
        }
    }

    var iconName: String {
        switch self {
        case .owner: return "crown.fill"
        case .guest: return "person.fill"
        case .serviceTechnician: return "wrench.and.screwdriver.fill"
        }
    }
}
