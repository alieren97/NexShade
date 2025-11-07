// Domain/UseCases/Device/ScanForDevicesUseCase.swift

import Foundation

/// Use case for scanning BLE devices
protocol ScanForDevicesUseCaseProtocol {
    func execute() -> AsyncStream<Device>
    func stopScanning()
}

final class ScanForDevicesUseCase: ScanForDevicesUseCaseProtocol {
    
    // MARK: - Dependencies
    
    private let deviceRepository: DeviceRepositoryProtocol
    
    // MARK: - Initialization
    
    init(deviceRepository: DeviceRepositoryProtocol) {
        self.deviceRepository = deviceRepository
    }
    
    // MARK: - Execute
    
    /// Start scanning for nearby devices
    /// - Returns: AsyncStream of discovered devices
    func execute() -> AsyncStream<Device> {
        return deviceRepository.scanForDevices()
    }
    
    /// Stop scanning
    func stopScanning() {
        deviceRepository.stopScanning()
    }
}