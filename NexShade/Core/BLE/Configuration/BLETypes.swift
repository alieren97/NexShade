//
//  BLEDevice.swift
//  NexShade
//
//  Created by Ali Eren on 6.11.2025.
//

import Foundation
import CoreBluetooth

// MARK: - BLE Device

struct BLEDevice: Identifiable, Hashable, Equatable {
    let id: UUID
    let peripheral: CBPeripheral
    let name: String?
    let rssi: Int
    let advertisementData: [String: Any]
    let discoveredAt: Date
    
    init(peripheral: CBPeripheral, rssi: NSNumber, advertisementData: [String: Any]) {
        self.id = peripheral.identifier
        self.peripheral = peripheral
        self.name = peripheral.name ?? advertisementData[CBAdvertisementDataLocalNameKey] as? String
        self.rssi = rssi.intValue
        self.advertisementData = advertisementData
        self.discoveredAt = Date()
    }
    
    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: BLEDevice, rhs: BLEDevice) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Signal Strength

enum SignalStrength {
    case excellent  // > -50 dBm
    case good       // -50 to -70 dBm
    case fair       // -70 to -85 dBm
    case poor       // < -85 dBm
    
    init(rssi: Int) {
        switch rssi {
        case let x where x > -50: self = .excellent
        case let x where x > -70: self = .good
        case let x where x > -85: self = .fair
        default: self = .poor
        }
    }
    
    var color: String {
        switch self {
        case .excellent: return "green"
        case .good: return "yellow"
        case .fair: return "orange"
        case .poor: return "red"
        }
    }
    
    var barCount: Int {
        switch self {
        case .excellent: return 4
        case .good: return 3
        case .fair: return 2
        case .poor: return 1
        }
    }
}
