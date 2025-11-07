// Core/BLE/BLEError.swift

import Foundation
import CoreBluetooth

enum BLEError: LocalizedError, Equatable {
    case bluetoothPoweredOff
    case bluetoothUnauthorized
    case bluetoothUnsupported
    case deviceNotFound(UUID)
    case connectionFailed(String)
    case connectionTimeout
    case disconnected
    case serviceNotFound(CBUUID)
    case characteristicNotFound(CBUUID)
    case readFailed(String)
    case writeFailed(String)
    case notificationFailed(String)
    case invalidData
    case operationTimeout
    case peripheralNotReady
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .bluetoothPoweredOff:
            return "Bluetooth is turned off. Please enable Bluetooth in Settings."
        case .bluetoothUnauthorized:
            return "Bluetooth permission is required. Please enable in Settings."
        case .bluetoothUnsupported:
            return "This device does not support Bluetooth Low Energy."
        case .deviceNotFound(let id):
            return "Device \(id) not found. Make sure it's powered on and nearby."
        case .connectionFailed(let reason):
            return "Connection failed: \(reason)"
        case .connectionTimeout:
            return "Connection timed out. Please try again."
        case .disconnected:
            return "Device disconnected unexpectedly."
        case .serviceNotFound(let uuid):
            return "Required service not found: \(uuid.uuidString)"
        case .characteristicNotFound(let uuid):
            return "Required characteristic not found: \(uuid.uuidString)"
        case .readFailed(let reason):
            return "Failed to read data: \(reason)"
        case .writeFailed(let reason):
            return "Failed to write data: \(reason)"
        case .notificationFailed(let reason):
            return "Failed to setup notifications: \(reason)"
        case .invalidData:
            return "Received invalid data from device."
        case .operationTimeout:
            return "Operation timed out."
        case .peripheralNotReady:
            return "Device is not ready. Please wait."
        case .unknown(let message):
            return "An error occurred: \(message)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .bluetoothPoweredOff:
            return "Turn on Bluetooth in your device settings."
        case .bluetoothUnauthorized:
            return "Go to Settings → Pergola Control → Bluetooth and enable access."
        case .deviceNotFound:
            return "Move closer to the device and try scanning again."
        case .connectionTimeout, .connectionFailed:
            return "Make sure the device is powered on and try again."
        case .disconnected:
            return "Tap to reconnect."
        default:
            return "Try again or restart the app."
        }
    }
}