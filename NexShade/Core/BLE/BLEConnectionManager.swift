// Core/BLE/BLEConnectionManager.swift

import Foundation
import CoreBluetooth
import Observation
import OSLog

/// Manages BLE scanning, connection, and peripheral lifecycle
@Observable
@MainActor
final class BLEConnectionManager: NSObject {
    
    // MARK: - Observable Properties
    
    private(set) var isScanning = false
    private(set) var discoveredDevices: [UUID: BLEDevice] = [:]
    private(set) var connectedPeripherals: [UUID: CBPeripheral] = [:]
    private(set) var connectionStates: [UUID: ConnectionState] = [:]
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
    
    // MARK: - Public Methods - Scanning
    
    /// Start scanning for BLE devices
    /// - Returns: AsyncStream of discovered devices
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
    
    // MARK: - Public Methods - Connection
    
    /// Connect to a peripheral
    /// - Parameter deviceId: UUID of the device to connect
    /// - Throws: BLEError if connection fails
    func connect(to deviceId: UUID) async throws {
        logger.info("Attempting to connect to device: \(deviceId)")
        
        // Check if already connected
        if let state = connectionStates[deviceId], state.isConnected {
            logger.info("Device already connected")
            return
        }
        
        // Find the peripheral
        guard let device = discoveredDevices[deviceId] ?? connectedPeripherals[deviceId] else {
            logger.error("Device not found: \(deviceId)")
            throw BLEError.deviceNotFound(deviceId)
        }
        
        let peripheral = device is BLEDevice ? (device as! BLEDevice).peripheral : device as! CBPeripheral
        
        // Set connecting state
        connectionStates[deviceId] = .connecting
        
        return try await withThrowingTaskGroup(of: Void.self) { group in
            // Add timeout task
            group.addTask {
                try await Task.sleep(for: .seconds(BLEConfiguration.connectionTimeout))
                throw BLEError.connectionTimeout
            }
            
            // Add connection task
            group.addTask {
                try await withCheckedThrowingContinuation { continuation in
                    self.connectionContinuations[deviceId] = continuation
                    self.centralManager.connect(peripheral, options: BLEConfiguration.connectionOptions)
                }
            }
            
            // Wait for first to complete (either timeout or connection)
            try await group.next()
            
            // Cancel remaining tasks
            group.cancelAll()
        }
    }
    
    /// Disconnect from a peripheral
    /// - Parameter deviceId: UUID of the device to disconnect
    func disconnect(from deviceId: UUID) async {
        logger.info("Disconnecting from device: \(deviceId)")
        
        guard let peripheral = connectedPeripherals[deviceId] else {
            logger.warning("Device not connected: \(deviceId)")
            return
        }
        
        connectionStates[deviceId] = .disconnecting
        
        await withCheckedContinuation { continuation in
            disconnectionContinuations[deviceId] = continuation
            centralManager.cancelPeripheralConnection(peripheral)
        }
    }
    
    /// Get connection state for a device
    /// - Parameter deviceId: UUID of the device
    /// - Returns: Current connection state
    func getConnectionState(for deviceId: UUID) -> ConnectionState {
        return connectionStates[deviceId] ?? .disconnected
    }
    
    /// Observe connection state changes
    /// - Parameter deviceId: UUID of the device
    /// - Returns: AsyncStream of connection states
    func observeConnectionState(for deviceId: UUID) -> AsyncStream<ConnectionState> {
        AsyncStream { continuation in
            // Emit current state
            if let currentState = connectionStates[deviceId] {
                continuation.yield(currentState)
            }
            
            // TODO: Implement state change observation
            // This would require adding a state observation mechanism
            
            continuation.onTermination = { @Sendable _ in
                // Cleanup if needed
            }
        }
    }
    
    /// Get connected peripheral
    /// - Parameter deviceId: UUID of the device
    /// - Returns: CBPeripheral if connected, nil otherwise
    func getPeripheral(for deviceId: UUID) -> CBPeripheral? {
        return connectedPeripherals[deviceId]
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
            
            // Update state to discovering services
            self.connectionStates[deviceId] = .discoveringServices
            
            // Resume connection continuation
            self.connectionContinuations[deviceId]?.resume()
            self.connectionContinuations.removeValue(forKey: deviceId)
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
            self.connectionStates[deviceId] = .error(bleError)
            
            // Resume with error
            self.connectionContinuations[deviceId]?.resume(throwing: bleError)
            self.connectionContinuations.removeValue(forKey: deviceId)
        }
    }
    
    nonisolated func centralManager(
        _ central: CBCentralManager,
        didDisconnectPeripheral peripheral: CBPeripheral,
        error: Error?
    ) {
        Task { @MainActor in
            let deviceId = peripheral.identifier
            self.logger.info("Disconnected from device: \(deviceId)")
            
            // Remove from connected peripherals
            self.connectedPeripherals.removeValue(forKey: deviceId)
            
            // Update state
            if let error = error {
                self.logger.error("Unexpected disconnection: \(error.localizedDescription)")
                self.connectionStates[deviceId] = .error(.disconnected)
            } else {
                self.connectionStates[deviceId] = .disconnected
            }
            
            // Resume disconnection continuation
            self.disconnectionContinuations[deviceId]?.resume()
            self.disconnectionContinuations.removeValue(forKey: deviceId)
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