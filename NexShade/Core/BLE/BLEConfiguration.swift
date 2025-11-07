// Core/BLE/BLEConfiguration.swift

import Foundation
import CoreBluetooth

struct BLEConfiguration {
    
    // MARK: - Service UUIDs
    
    static let pergolaServiceUUID = CBUUID(string: "4fafc201-1fb5-459e-8fcc-c5c9c331914b")
    
    // MARK: - Characteristic UUIDs
    
    enum Characteristic {
        case authChallenge
        case authResponse
        case control
        case status
        case notification
        
        var uuid: CBUUID {
            switch self {
            case .authChallenge:
                return CBUUID(string: "beb5483e-36e1-4688-b7f5-ea07361b26a8")
            case .authResponse:
                return CBUUID(string: "beb5483f-36e1-4688-b7f5-ea07361b26a8")
            case .control:
                return CBUUID(string: "beb54840-36e1-4688-b7f5-ea07361b26a8")
            case .status:
                return CBUUID(string: "beb54841-36e1-4688-b7f5-ea07361b26a8")
            case .notification:
                return CBUUID(string: "beb54842-36e1-4688-b7f5-ea07361b26a8")
            }
        }
        
        var properties: CBCharacteristicProperties {
            switch self {
            case .authChallenge:
                return .read
            case .authResponse:
                return .write
            case .control:
                return .write
            case .status:
                return [.read, .notify]
            case .notification:
                return .notify
            }
        }
    }
    
    // MARK: - Timeouts
    
    static let scanTimeout: TimeInterval = 10.0
    static let connectionTimeout: TimeInterval = 30.0
    static let discoveryTimeout: TimeInterval = 10.0
    static let operationTimeout: TimeInterval = 10.0
    
    // MARK: - Scanning Options
    
    static let scanOptions: [String: Any] = [
        CBCentralManagerScanOptionAllowDuplicatesKey: false
    ]
    
    // MARK: - Connection Options
    
    static let connectionOptions: [String: Any] = [
        CBConnectPeripheralOptionNotifyOnConnectionKey: true,
        CBConnectPeripheralOptionNotifyOnDisconnectionKey: true,
        CBConnectPeripheralOptionNotifyOnNotificationKey: true
    ]
}