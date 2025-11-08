//
//  ScanViewModel.swift
//  NexShade
//
//  Created by Gedikoglu, Ali on 8.11.2025.
//

import Foundation
import SwiftUI

@MainActor
@Observable
final class ScanViewModel {

    // MARK: - Published State

    // Tracks the current scanning state, directly updated by the stream.
    var isScanning: Bool = false

    // The list of devices found during the current scan.
    var discoveredDevices: [Device] = []

    // MARK: - Private Properties

    private let scanningUseCase: ScanForDevicesUseCaseProtocol // Use the protocol for better mocking
    private let connectionUseCase: ConnectToDeviceUseCaseProtocol

    // Tasks to hold the async stream consumers so they can be cancelled.
    private var scanTask: Task<Void, Never>?
    private var isScanningTask: Task<Void, Never>?

    // MARK: - Initialization

    init(scanningUseCase: ScanForDevicesUseCaseProtocol,
         connectionUseCase: ConnectToDeviceUseCaseProtocol) {
        self.scanningUseCase = scanningUseCase
        self.connectionUseCase = connectionUseCase
        // Start observing the isScanning state immediately upon initialization
        startObservingScanningState()
    }

    // MARK: - Public Actions

    /// Starts the device scanning process and begins listening to the device stream.
    func startScan() {
        // 1. Clear previous list
        discoveredDevices = []

        // 2. Cancel any existing scan task to avoid leaks/duplicates
        scanTask?.cancel()

        // 3. Create a new task to consume the device stream
        scanTask = Task {
            // The execute() function implicitly starts the scan in the lower layers
            for await device in scanningUseCase.execute() {
                // Check for task cancellation
                guard !Task.isCancelled else { return }

                // 4. Update the device list, merging or appending new devices
                if let index = discoveredDevices.firstIndex(where: { $0.id == device.id }) {
                    // Update existing device (e.g., if RSSI changed)
                    discoveredDevices[index] = device
                } else {
                    // Add new device
                    discoveredDevices.append(device)
                }
            }
        }
    }

    /// Stops both the device stream consumption and the underlying BLE scan.
    func stopScan() {
        scanningUseCase.stopScanning()
        scanTask?.cancel()
        scanTask = nil
    }

    // MARK: - Private Stream Consumers

    /// Establishes the connection to the isScanning stream and updates the ViewModel's state.
    private func startObservingScanningState() {
        // Cancel any existing task
        isScanningTask?.cancel()

        // Task to consume the isScanning stream
        isScanningTask = Task {
            for await scanningState in scanningUseCase.isScanning() {
                // Check for task cancellation
                guard !Task.isCancelled else { return }

                // Update the ViewModel's state property
                self.isScanning = scanningState
            }
        }
    }

    func connectToDevice() async throws {
        try await connectionUseCase.execute(deviceId: .init())
    }

    // MARK: - Cleanup

    deinit {
        // Ensure all active tasks are cancelled when the ViewModel is destroyed
//        isScanningTask?.cancel()
//        scanTask?.cancel()
//        scanningUseCase.stopScanning() // Ensure the underlying BLE hardware stops scanning
    }
}
