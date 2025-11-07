//
//  Permissions.swift
//  NexShade
//
//  Created by Ali Eren on 7.11.2025.
//


import Foundation

/// Permissions that can be granted to users
struct Permissions: OptionSet, Codable, Hashable {
    let rawValue: Int
    
    // MARK: - Permission Levels
    
    /// Can view device status
    static let viewOnly = Permissions(rawValue: 1 << 0)
    
    /// Can perform basic control (open, close, stop)
    static let basicControl = Permissions(rawValue: 1 << 1)
    
    /// Can perform advanced control (position control)
    static let advancedControl = Permissions(rawValue: 1 << 2)
    
    /// Can manage other users (invite, remove)
    static let userManagement = Permissions(rawValue: 1 << 3)
    
    /// Can access diagnostic features
    static let diagnostics = Permissions(rawValue: 1 << 4)
    
    /// Can access service settings
    static let serviceSettings = Permissions(rawValue: 1 << 5)
    
    // MARK: - Preset Permission Sets
    
    /// Owner permissions (all except service)
    static let owner: Permissions = [
        .viewOnly,
        .basicControl,
        .advancedControl,
        .userManagement
    ]
    
    /// Basic guest permissions
    static let basicGuest: Permissions = [
        .viewOnly,
        .basicControl
    ]
    
    /// Advanced guest permissions
    static let advancedGuest: Permissions = [
        .viewOnly,
        .basicControl,
        .advancedControl
    ]
    
    /// Service technician permissions
    static let serviceTechnician: Permissions = [
        .viewOnly,
        .basicControl,
        .advancedControl,
        .diagnostics,
        .serviceSettings
    ]
    
    // MARK: - Computed Properties
    
    /// User-friendly description
    var description: String {
        var permissions: [String] = []
        
        if contains(.viewOnly) {
            permissions.append("View Status")
        }
        if contains(.basicControl) {
            permissions.append("Basic Control")
        }
        if contains(.advancedControl) {
            permissions.append("Position Control")
        }
        if contains(.userManagement) {
            permissions.append("User Management")
        }
        if contains(.diagnostics) {
            permissions.append("Diagnostics")
        }
        if contains(.serviceSettings) {
            permissions.append("Service Settings")
        }
        
        return permissions.isEmpty ? "No Permissions" : permissions.joined(separator: ", ")
    }
    
    /// Permission level name
    var levelName: String {
        if self == .owner {
            return "Owner"
        } else if self == .serviceTechnician {
            return "Service Technician"
        } else if self == .advancedGuest {
            return "Advanced Guest"
        } else if self == .basicGuest {
            return "Basic Guest"
        } else if contains(.userManagement) {
            return "Administrator"
        } else if contains(.advancedControl) {
            return "Advanced User"
        } else if contains(.basicControl) {
            return "Basic User"
        } else if contains(.viewOnly) {
            return "Viewer"
        } else {
            return "No Access"
        }
    }
}
