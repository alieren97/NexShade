//
//  Route.swift
//  NexShade
//
//  Created by Gedikoglu, Ali on 6.11.2025.
//

import SwiftUI

enum Route: Hashable {
    // Control Routes
    case controlHome
    case deviceDetail(UUID)
    case activityLog(UUID)
    
    // Scan Routes
    case scanHome
    case deviceList
    case deviceProvisioning(DeviceProvisioningData)
    case invitationEntry
    
    // Settings Routes
    case settingsHome
    case userManagement(UUID) // device ID
    case invitationCreation(UUID)
    case serviceAccessSettings(UUID)
    case activityHistory(UUID)
    case profile
    case security
    case backupRestore
    
    // Setup Routes (Service Tech)
    case setupHome
    case setupWizard
    case deviceConfiguration(UUID)
    case calibration(UUID)
    case setupCompletion(SetupResult)
    
    // Common Routes
    case error(RouteError)
}

// Supporting models
struct DeviceProvisioningData: Hashable {
    let deviceId: UUID
    let deviceName: String
    let macAddress: String
}

struct InvitationData: Hashable {
    let deviceId: UUID
}

struct ServiceReportData: Hashable {
    let sessionId: UUID
    let deviceId: UUID
}

struct SetupResult: Hashable {
    let deviceId: UUID
    let success: Bool
}

enum RouteError: Error, Hashable {
    case network(code: Int)
    case unauthorized
    case generic(message: String)
}
