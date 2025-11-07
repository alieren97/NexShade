//
//  ControlViewModel.swift
//  NexShade
//
//  Created by Ali Eren on 6.11.2025.
//


// Presentation/ViewModels/ControlViewModel.swift

import Foundation
import Observation

@Observable
@MainActor
final class ControlViewModel {
    
    // MARK: - State
    
    var device: Device?
    var status: PergolaStatus?
    var isLoading = false
    var error: String?
    var connectionState: ConnectionState = .disconnected
    
    // MARK: - Dependencies (Use Cases ONLY!)
    
    private let connectUseCase: ConnectToDeviceUseCaseProtocol
    private let controlUseCase: ControlPergolaUseCaseProtocol
    private let getStatusUseCase: GetDeviceStatusUseCaseProtocol
    private let disconnectUseCase: DisconnectDeviceUseCaseProtocol
    
    // MARK: - Initialization
    
    init(
        connectUseCase: ConnectToDeviceUseCaseProtocol,
        controlUseCase: ControlPergolaUseCaseProtocol,
        getStatusUseCase: GetDeviceStatusUseCaseProtocol,
        disconnectUseCase: DisconnectDeviceUseCaseProtocol
    ) {
        self.connectUseCase = connectUseCase
        self.controlUseCase = controlUseCase
        self.getStatusUseCase = getStatusUseCase
        self.disconnectUseCase = disconnectUseCase
    }
    
    // MARK: - Public Methods
    
    func connect(to deviceId: UUID) async {
        isLoading = true
        error = nil
        
        do {
            // Use case handles ALL the complexity!
            device = try await connectUseCase.execute(deviceId: deviceId)
            connectionState = .connected
            
            // Start observing status
            await observeStatus(deviceId: deviceId)
        } catch {
            self.error = error.localizedDescription
            connectionState = .error
        }
        
        isLoading = false
    }
    
    func open() async {
        guard let deviceId = device?.id else { return }
        await sendCommand(.open, to: deviceId)
    }
    
    func close() async {
        guard let deviceId = device?.id else { return }
        await sendCommand(.close, to: deviceId)
    }
    
    func stop() async {
        guard let deviceId = device?.id else { return }
        await sendCommand(.stop, to: deviceId)
    }
    
    func setPosition(_ position: Int) async {
        guard let deviceId = device?.id else { return }
        await sendCommand(.setPosition(position), to: deviceId)
    }
    
    func refresh() async {
        guard let deviceId = device?.id else { return }
        
        do {
            status = try await getStatusUseCase.execute(deviceId: deviceId)
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    func disconnect() async {
        guard let deviceId = device?.id else { return }
        
        do {
            try await disconnectUseCase.execute(deviceId: deviceId)
            device = nil
            status = nil
            connectionState = .disconnected
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    // MARK: - Private Methods
    
    private func sendCommand(_ command: PergolaCommand, to deviceId: UUID) async {
        isLoading = true
        error = nil
        
        do {
            // Use case handles permission checking, logging, etc.
            status = try await controlUseCase.execute(
                deviceId: deviceId,
                command: command
            )
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
    
    private func observeStatus(deviceId: UUID) async {
        // Subscribe to status updates
        for await newStatus in getStatusUseCase.observeStatus(deviceId: deviceId) {
            status = newStatus
        }
    }
}