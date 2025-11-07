//
//  ScanViewModel.swift
//  NexShade
//
//  Created by Ali Eren on 6.11.2025.
//

import Foundation
import Observation

@Observable
@MainActor
final class ScanViewModel {
    
    // MARK: - State
    
    var discoveredDevices: [Device] = []
    var isScanning = false
    var error: String?
    
    // MARK: - Dependencies (Use Cases ONLY!)
    
    private let scanUseCase: ScanForDevicesUseCaseProtocol
    private let connectUseCase: ConnectToDeviceUseCaseProtocol
    
    // MARK: - Initialization
    
    init(
        scanUseCase: ScanForDevicesUseCaseProtocol,
        connectUseCase: ConnectToDeviceUseCaseProtocol
    ) {
        self.scanUseCase = scanUseCase
        self.connectUseCase = connectUseCase
    }
    
    // MARK: - Public Methods
    
    func startScanning() {
        discoveredDevices.removeAll()
        isScanning = true
        error = nil
        
        Task {
            // Use case returns AsyncStream
            for await device in scanUseCase.execute() {
                if !discoveredDevices.contains(where: { $0.id == device.id }) {
                    discoveredDevices.append(device)
                }
            }
            isScanning = false
        }
    }
    
    func stopScanning() {
        scanUseCase.stopScanning()
        isScanning = false
    }
    
    func connect(to device: Device) async -> Bool {
        do {
            _ = try await connectUseCase.execute(deviceId: device.id)
            return true
        } catch {
            self.error = error.localizedDescription
            return false
        }
    }
}
