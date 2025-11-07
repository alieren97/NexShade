//
//  ScanForDevicesUseCaseProtocol.swift
//  NexShade
//
//  Created by Ali Eren on 6.11.2025.
//


import Foundation

/// Use case for scanning BLE devices
protocol ScanForDevicesUseCaseProtocol {
    func execute() -> AsyncStream<BLEDevice>
    func stopScanning()
}

final class ScanForDevicesUseCase: ScanForDevicesUseCaseProtocol {
    
    // MARK: - Dependencies
    
    private let bleScanning: BLEScanning
    
    // MARK: - Initialization
    
    init(bleScanning: BLEScanning) {
        self.bleScanning = bleScanning
    }
    
    // MARK: - Execute
    
    /// Start scanning for nearby devices
    /// - Returns: AsyncStream of discovered devices
    func execute() -> AsyncStream<BLEDevice> {
        return bleScanning.startScanning()
    }
    
    /// Stop scanning
    func stopScanning() {
        bleScanning.stopScanning()
    }
}
