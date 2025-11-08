//
//  ScanForDevicesUseCaseProtocol.swift
//  NexShade
//
//  Created by Ali Eren on 6.11.2025.
//

import Foundation

/// Use case for scanning BLE devices
protocol ScanForDevicesUseCaseProtocol {
    func execute() -> AsyncStream<Device>
    func stopScanning()
    func isScanning() -> AsyncStream<Bool>
}

final class ScanForDevicesUseCase: ScanForDevicesUseCaseProtocol {
    
    // MARK: - Dependencies
    
    private let deviceRepositoryScanning: DeviceRepositoryScanning

    // MARK: - Initialization
    
    init(deviceRepositoryScanning: DeviceRepositoryScanning) {
        self.deviceRepositoryScanning = deviceRepositoryScanning
    }
    
    // MARK: - Execute
    
    /// Start scanning for nearby devices
    /// - Returns: AsyncStream of discovered devices
    func execute() -> AsyncStream<Device> {
        return deviceRepositoryScanning.scanForDevices()
    }
    
    /// Stop scanning
    func stopScanning() {
        deviceRepositoryScanning.stopScanning()
    }

    func isScanning() -> AsyncStream<Bool> {
        deviceRepositoryScanning.isScanning()
    }
}
