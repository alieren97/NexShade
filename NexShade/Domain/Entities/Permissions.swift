//
//  Permissions.swift
//  NexShade
//
//  Created by Ali Eren on 7.11.2025.
//


import Foundation

struct Permissions: OptionSet, Codable, Hashable {
    let rawValue: Int

    static let viewOnly = Permissions(rawValue: 1 << 0)
    static let basicControl = Permissions(rawValue: 1 << 1)
    static let advancedControl = Permissions(rawValue: 1 << 2)
    static let userManagement = Permissions(rawValue: 1 << 3)
    static let diagnostics = Permissions(rawValue: 1 << 4)
    static let serviceSettings = Permissions(rawValue: 1 << 5)

    static let owner: Permissions = [.viewOnly, .basicControl, .advancedControl, .userManagement]
    static let basicGuest: Permissions = [.viewOnly, .basicControl]
    static let advancedGuest: Permissions = [.viewOnly, .basicControl, .advancedControl]
    static let serviceTechnician: Permissions = [.viewOnly, .basicControl, .advancedControl, .diagnostics, .serviceSettings]

    var description: String {
        var perms: [String] = []
        if contains(.viewOnly) { perms.append("View Status") }
        if contains(.basicControl) { perms.append("Basic Control") }
        if contains(.advancedControl) { perms.append("Position Control") }
        if contains(.userManagement) { perms.append("User Management") }
        if contains(.diagnostics) { perms.append("Diagnostics") }
        if contains(.serviceSettings) { perms.append("Service Settings") }
        return perms.isEmpty ? "No Permissions" : perms.joined(separator: ", ")
    }
}
