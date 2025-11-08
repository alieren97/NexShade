//
//  ConnectionState.swift
//  NexShade
//
//  Created by Ali Eren on 7.11.2025.
//

import Foundation

enum ConnectionState: Hashable {
    case disconnected
    case scanning
    case connecting
    case discoveringServices
    case discoveringCharacteristics
    case ready
    case disconnecting
    case connected
    // For runtime, store the specific BLEError if present.
    case error(BLEError)
    
    // For runtime, store the specific BLEError if present.
    var bleError: BLEError? {
        if case .error(let error) = self {
            return error
        }
        return nil
    }

    var isConnected: Bool {
        self == .ready
    }
    
    var description: String {
        switch self {
        case .connected: return "Connected"
        case .disconnected: return "Disconnected"
        case .scanning: return "Scanning..."
        case .connecting: return "Connecting..."
        case .discoveringServices: return "Discovering services..."
        case .discoveringCharacteristics: return "Setting up..."
        case .ready: return "Connected"
        case .disconnecting: return "Disconnecting..."
        case .error(let bleError):
            return bleError.errorDescription ?? "Connection Error"
        }
    }
    
    // MARK: - Raw Value Mapping for Persistence
    
    /// Persists only the enum case, not the BLEError detail in .error(_).
    var rawValue: String {
        switch self {
        case .connected: return "connected"
        case .disconnected: return "disconnected"
        case .scanning: return "scanning"
        case .connecting: return "connecting"
        case .discoveringServices: return "discoveringServices"
        case .discoveringCharacteristics: return "discoveringCharacteristics"
        case .ready: return "ready"
        case .disconnecting: return "disconnecting"
        case .error: return "error"
        }
    }

    init(rawValue: String) {
        switch rawValue {
        case "connected": self = .connected
        case "disconnected": self = .disconnected
        case "scanning": self = .scanning
        case "connecting": self = .connecting
        case "discoveringServices": self = .discoveringServices
        case "discoveringCharacteristics": self = .discoveringCharacteristics
        case "ready": self = .ready
        case "disconnecting": self = .disconnecting
        case "error": self = .error(.unknown("Unknown error"))
        default: self = .disconnected
        }
    }
}
