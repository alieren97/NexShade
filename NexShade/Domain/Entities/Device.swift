//
//  Device.swift
//  NexShade
//
//  Created by Ali Eren on 6.11.2025.
//


struct Device {
    let id: UUID
    let name: String
    let macAddress: String
    var status: DeviceStatus
    var connectionState: ConnectionState
    let role: UserRole
    let permissions: Permissions
    
    enum DeviceStatus {
        case online
        case offline
        case connecting
    }
    
    enum ConnectionState {
        case disconnected
        case connecting
        case authenticating
        case connected
        case error(Error)
    }
}
