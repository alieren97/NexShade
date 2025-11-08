//
//  BLEConnectionManager.swift
//  NexShade
//
//  Created by Ali Eren on 6.11.2025.
//

import Foundation
import CoreBluetooth
import Combine
import Observation
import OSLog

protocol BLEScanning {
    func startScanning() -> AsyncStream<BLEDevice>
    func stopScanning()
    func observeIsScanning() -> AsyncStream<Bool>

}

/// Manages BLE scanning, connection, and peripheral lifecycle
@Observable
@MainActor
final class BLEConnectionManager: NSObject {
    
    // MARK: - Observable Properties
    
    private(set) var isScanning = false

    private var discoveredDevices: [UUID: BLEDevice] = [:]
    private var connectedPeripherals: [UUID: CBPeripheral] = [:]
    private var connectionStates: [UUID: ConnectionState] = [:]
    private var activeConnectionAttempts: Set<UUID> = []
    private(set) var bluetoothState: CBManagerState = .unknown
    
    // MARK: - Private Properties
    
    private var centralManager: CBCentralManager!
    private let logger = Logger(subsystem: "com.pergola.ble", category: "ConnectionManager")
    
    // Continuations for async operations
    private var scanContinuation: AsyncStream<BLEDevice>.Continuation?
    private var connectionContinuations: [UUID: CheckedContinuation<Void, Error>] = [:]
    private var disconnectionContinuations: [UUID: CheckedContinuation<Void, Never>] = [:]
    
    // State restoration
    private var shouldRestoreState = false
    private var restoredPeripherals: [CBPeripheral] = []

    // MARK: - State Publishers

    /// Publishes connection state changes for each device
    private let connectionStateSubject = PassthroughSubject<(UUID, ConnectionState), Never>()

    /// Observable connection state stream
    var connectionStatePublisher: AnyPublisher<(UUID, ConnectionState), Never> {
        connectionStateSubject.eraseToAnyPublisher()
    }

    // MARK: - Limits

     private let maxConcurrentConnections = 5

    // MARK: - Initialization
    
    override init() {
        super.init()
        
        // Initialize CBCentralManager on main queue
        let queue = DispatchQueue.main
        centralManager = CBCentralManager(
            delegate: self,
            queue: queue,
            options: [
                CBCentralManagerOptionShowPowerAlertKey: true,
                CBCentralManagerOptionRestoreIdentifierKey: "com.pergola.central"
            ]
        )
        
        logger.info("BLEConnectionManager initialized")
    }
    
    // MARK: - Public Methods - Connection

    func connect(to deviceId: UUID) async throws {
        logger.info("🔵 Connecting to device: \(deviceId)")

        // 1. ✅ Check if already connected
        if let state = connectionStates[deviceId], state == .connected {
            logger.info("✅ Already connected to \(deviceId)")
            return
        }

        // 2. ✅ Check if connection already in progress
        if activeConnectionAttempts.contains(deviceId) {
            logger.warning("⚠️ Connection already in progress for \(deviceId)")
            throw BLEError.connectionInProgress(deviceId)
        }

        // 3. ✅ Check concurrent connection limit
        if activeConnectionAttempts.count >= maxConcurrentConnections {
            logger.warning("⚠️ Maximum concurrent connections reached")
            throw BLEError.tooManyConcurrentConnections
        }

        // 4. Find peripheral
        guard let peripheral = findPeripheral(for: deviceId) else {
            logger.error("❌ Device not found: \(deviceId)")
            throw BLEError.deviceNotFound(deviceId)
        }

        // 5. Mark as active attempt
        activeConnectionAttempts.insert(deviceId)

        // 6. Set connecting state
        updateConnectionState(deviceId: deviceId, state: .connecting)

        // 7. Connect with timeout
        do {
            try await connectWithTimeout(to: peripheral, timeout: 10.0)
            logger.info("✅ Connected to \(deviceId)")
        } catch {
            logger.error("❌ Failed to connect to \(deviceId): \(error)")
            // Clean up on failure
            activeConnectionAttempts.remove(deviceId)
            updateConnectionState(deviceId: deviceId, state: .error(.connectionFailed("")))
            throw error
        }

        // 8. Remove from active attempts (success)
        activeConnectionAttempts.remove(deviceId)
    }

    func disconnect(from deviceId: UUID) async throws {
        logger.info("🔴 Disconnecting from device: \(deviceId)")

        guard let peripheral = connectedPeripherals[deviceId] else {
            throw BLEError.disconnected
        }

        updateConnectionState(deviceId: deviceId, state: .disconnecting)
        centralManager.cancelPeripheralConnection(peripheral)
    }

    // MARK: - Concurrent Connection Helper

    private func connectWithTimeout(
        to peripheral: CBPeripheral,
        timeout: TimeInterval
    ) async throws {
        let deviceId = peripheral.identifier

        try await withThrowingTaskGroup(of: Void.self) { group in

            // Task 1: Actual connection
            group.addTask { @MainActor [weak self] in
                guard let self = self else { return }

                try await withCheckedThrowingContinuation { continuation in
                    // Store continuation for this device
                    self.connectionContinuations[deviceId] = continuation

                    // Initiate connection
                    self.centralManager.connect(peripheral, options: nil)
                }
            }

            // Task 2: Timeout
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                throw BLEError.connectionTimeout
            }

            // First to complete wins
            try await group.next()!

            // Cancel the other task
            group.cancelAll()

            // Clean up continuation on timeout
            if self.connectionContinuations[deviceId] != nil {
                self.connectionContinuations.removeValue(forKey: deviceId)
                // Also cancel the connection attempt
                self.centralManager.cancelPeripheralConnection(peripheral)
            }
        }
    }

    // MARK: - Helpers

    private func findPeripheral(for deviceId: UUID) -> CBPeripheral? {
        if let device = discoveredDevices[deviceId] {
            return device.peripheral
        }
        return connectedPeripherals[deviceId]
    }

    private func updateConnectionState(deviceId: UUID, state: ConnectionState) {
        connectionStates[deviceId] = state
        connectionStateSubject.send((deviceId, state))
        logger.info("📊 State[\(deviceId)]: \(state.rawValue)")
    }

    func getPeripheral(for deviceId: UUID) -> CBPeripheral? {
        return connectedPeripherals[deviceId]
    }

    func getConnectionState(for deviceId: UUID) -> ConnectionState {
        return connectionStates[deviceId] ?? .disconnected
    }

    func getAllConnectedDevices() -> [UUID] {
        return Array(connectedPeripherals.keys)
    }

    func observeConnectionState(for deviceId: UUID) -> AsyncStream<ConnectionState> {
        AsyncStream { continuation in
            let cancellable = connectionStatePublisher
                .filter { $0.0 == deviceId }
                .map { $0.1 }
                .sink { state in
                    continuation.yield(state)
                }

            continuation.onTermination = { _ in
                cancellable.cancel()
            }
        }
    }

    // MARK: - Public Methods - Signal Strength
    
    /// Read RSSI for connected peripheral
    /// - Parameter deviceId: UUID of the device
    /// - Returns: RSSI value in dBm
    func readRSSI(for deviceId: UUID) async throws -> Int {
        guard let peripheral = connectedPeripherals[deviceId] else {
            throw BLEError.deviceNotFound(deviceId)
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            // Store continuation for callback
            // TODO: Implement RSSI continuation storage
            peripheral.readRSSI()
        }
    }
}

// MARK: - CBCentralManagerDelegate

extension BLEConnectionManager: CBCentralManagerDelegate {
    
    nonisolated func centralManagerDidUpdateState(_ central: CBCentralManager) {
        Task { @MainActor in
            self.bluetoothState = central.state
            self.logger.info("Bluetooth state changed: \(String(describing: central.state.rawValue))")
            
            switch central.state {
            case .poweredOff:
                // Update all connection states
                for deviceId in self.connectedPeripherals.keys {
                    self.connectionStates[deviceId] = .error(.bluetoothPoweredOff)
                }
                
            case .unauthorized:
                for deviceId in self.connectedPeripherals.keys {
                    self.connectionStates[deviceId] = .error(.bluetoothUnauthorized)
                }
                
            case .unsupported:
                for deviceId in self.connectedPeripherals.keys {
                    self.connectionStates[deviceId] = .error(.bluetoothUnsupported)
                }
                
            case .poweredOn:
                self.logger.info("Bluetooth powered on and ready")
                
            default:
                break
            }
        }
    }
    
    nonisolated func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        Task { @MainActor in
            let device = BLEDevice(
                peripheral: peripheral,
                rssi: RSSI,
                advertisementData: advertisementData
            )
            
            self.logger.info("Discovered device: \(device.name ?? "Unknown") (\(device.id))")
            
            // Store discovered device
            self.discoveredDevices[device.id] = device
            
            // Emit to stream
            self.scanContinuation?.yield(device)
        }
    }
    
    nonisolated func centralManager(
        _ central: CBCentralManager,
        didConnect peripheral: CBPeripheral
    ) {
        Task { @MainActor in
            let deviceId = peripheral.identifier
            self.logger.info("Connected to device: \(deviceId)")
            
            // Store connected peripheral
            self.connectedPeripherals[deviceId] = peripheral
            
            updateConnectionState(deviceId: deviceId, state: .connected)

            if let continuation = connectionContinuations.removeValue(forKey: deviceId) {
                continuation.resume()
            }
        }
    }
    
    nonisolated func centralManager(
        _ central: CBCentralManager,
        didFailToConnect peripheral: CBPeripheral,
        error: Error?
    ) {
        Task { @MainActor in
            let deviceId = peripheral.identifier
            self.logger.error("Failed to connect to device: \(deviceId), error: \(String(describing: error))")
            
            let bleError = BLEError.connectionFailed(error?.localizedDescription ?? "Unknown error")
            updateConnectionState(deviceId: deviceId, state: .error(bleError))
            activeConnectionAttempts.remove(deviceId)

            if let continuation = connectionContinuations.removeValue(forKey: deviceId) {
                continuation.resume(throwing: error ?? BLEError.connectionFailed(bleError.localizedDescription))
            }
        }
    }
    
    nonisolated func centralManager(
        _ central: CBCentralManager,
        didDisconnectPeripheral peripheral: CBPeripheral,
        error: Error?
    ) {
        Task { @MainActor in
            let deviceId = peripheral.identifier
            logger.info("🔌 didDisconnect: \(deviceId)")

            connectedPeripherals.removeValue(forKey: deviceId)
            activeConnectionAttempts.remove(deviceId)

            if let error = error {
                logger.error("Unexpected disconnection: \(error.localizedDescription)")
                let bleError = BLEError.connectionFailed(error.localizedDescription)
                updateConnectionState(deviceId: deviceId, state: .error(bleError))
            } else {
                updateConnectionState(deviceId: deviceId, state: .disconnected)
            }
        }
    }
    
    nonisolated func centralManager(
        _ central: CBCentralManager,
        willRestoreState dict: [String: Any]
    ) {
        Task { @MainActor in
            self.logger.info("Restoring Central Manager state")
            
            if let peripherals = dict[CBCentralManagerRestoredStatePeripheralsKey] as? [CBPeripheral] {
                self.restoredPeripherals = peripherals
                self.shouldRestoreState = true
                
                for peripheral in peripherals {
                    self.logger.info("Restored peripheral: \(peripheral.identifier)")
                    self.connectedPeripherals[peripheral.identifier] = peripheral
                }
            }
        }
    }
}

extension BLEConnectionManager: BLEScanning {
    func startScanning() -> AsyncStream<BLEDevice> {
        logger.info("Starting BLE scan")
        
        return AsyncStream { continuation in
            self.scanContinuation = continuation
            
            Task { @MainActor in
                // Check if Bluetooth is ready
                guard self.bluetoothState == .poweredOn else {
                    self.logger.error("Bluetooth not powered on, state: \(String(describing: self.bluetoothState))")
                    continuation.finish()
                    return
                }
                
                // Clear previous discoveries
                self.discoveredDevices.removeAll()
                
                // Start scanning
                self.isScanning = true
                self.centralManager.scanForPeripherals(
                    withServices: [BLEConfiguration.pergolaServiceUUID],
                    options: BLEConfiguration.scanOptions
                )
                
                self.logger.info("Scan started")
                
                // Auto-stop after timeout
                Task {
                    try? await Task.sleep(for: .seconds(BLEConfiguration.scanTimeout))
                    if self.isScanning {
                        self.stopScanning()
                    }
                }
            }
            
            continuation.onTermination = { @Sendable _ in
                Task { @MainActor in
                    self.stopScanning()
                }
            }
        }
    }
    
    /// Stop scanning for devices
    func stopScanning() {
        guard isScanning else { return }
        
        logger.info("Stopping BLE scan")
        centralManager.stopScan()
        isScanning = false
        scanContinuation?.finish()
        scanContinuation = nil
    }

    func observeIsScanning() -> AsyncStream<Bool> {
        return observationTrackingStream(initialValue: self.isScanning) {
            // The closure tracks all accessed properties
            self.isScanning
        }
    }
}


// Utility to bridge Observation to AsyncStream
func observationTrackingStream<T>(
    initialValue: T,
    _ apply: @escaping () -> T
) -> AsyncStream<T> {

    return AsyncStream { continuation in
        // Yield the initial value immediately
        continuation.yield(initialValue)

        // Define the recursive observation function
        @Sendable func observe() {
            let result = withObservationTracking {
                apply() // This executes the closure and tracks dependencies (e.g., self.isScanning)
            } onChange: {
                // When a tracked dependency changes, schedule a new observation
                // Dispatching to the main queue ensures we read the new value after it has fully changed.
                // Since BLEConnectionManager is @MainActor, this is safe.
                Task { @MainActor in
                    observe()
                }
            }
            // Yield the *new* value after the change
            continuation.yield(result)
        }

        // Start the observation process
        observe()
    }
}
