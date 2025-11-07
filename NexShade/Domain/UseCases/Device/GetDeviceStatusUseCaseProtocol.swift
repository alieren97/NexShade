// Domain/UseCases/Control/GetDeviceStatusUseCase.swift

import Foundation

/// Use case for getting real-time device status
protocol GetDeviceStatusUseCaseProtocol {
    func execute(deviceId: UUID) async throws -> PergolaStatus
    func observeStatus(deviceId: UUID) -> AsyncStream<PergolaStatus>
}

final class GetDeviceStatusUseCase: GetDeviceStatusUseCaseProtocol {
    
    // MARK: - Dependencies
    
    private let deviceRepository: DeviceRepositoryProtocol
    
    // MARK: - Initialization
    
    init(deviceRepository: DeviceRepositoryProtocol) {
        self.deviceRepository = deviceRepository
    }
    
    // MARK: - Execute
    
    /// Get current device status (one-time read)
    /// - Parameter deviceId: UUID of the device
    /// - Returns: Current pergola status
    /// - Throws: DomainError if read fails
    func execute(deviceId: UUID) async throws -> PergolaStatus {
        return try await deviceRepository.getStatus(for: deviceId)
    }
    
    /// Observe real-time status updates
    /// - Parameter deviceId: UUID of the device
    /// - Returns: AsyncStream of status updates
    func observeStatus(deviceId: UUID) -> AsyncStream<PergolaStatus> {
        return deviceRepository.observeStatus(for: deviceId)
    }
}