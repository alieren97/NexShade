protocol DeviceRepositoryProtocol {
    func getDevices() async throws -> [Device]
    func getDevice(id: UUID) async throws -> Device?
    func saveDevice(_ device: Device) async throws
    func deleteDevice(id: UUID) async throws
    
    func connect(to deviceId: UUID) async throws
    func disconnect(from deviceId: UUID) async throws
    
    func sendCommand(deviceId: UUID, command: PergolaCommand) async throws -> PergolaStatus
    func getStatus(deviceId: UUID) async throws -> PergolaStatus
    
    func observeStatus(deviceId: UUID) -> AsyncStream<PergolaStatus>
    
    func logAction(deviceId: UUID, command: PergolaCommand, success: Bool) async throws
}