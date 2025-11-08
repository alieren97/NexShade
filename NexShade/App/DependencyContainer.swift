//
//  DependencyContainer.swift
//  NexShade
//
//  Created by Gedikoglu, Ali on 6.11.2025.
//

import Foundation
import SwiftData

final class DependencyContainer {
    
    // MARK: - Singletons (Infrastructure)
    
    private lazy var bleConnectionManager = BLEConnectionManager()
    private lazy var bleCharacteristicManager = BLECharacteristicManager()
    private lazy var cryptoManager = CryptoManager()

    private lazy var modelContainer: ModelContainer = {
        let schema = Schema([
            DeviceModel.self,
//            UserModel.self,
//            AuditLogModel.self,
            AuthenticationResultModel.self
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        return try! ModelContainer(for: schema, configurations: [config])
    }()
    
    
    // MARK: - Data Sources
    
    private func makeBLEDataSource() -> BLEDataSource {
        BLEDataSource(
            connectionManager: bleConnectionManager,
            characteristicManager: bleCharacteristicManager
        )
    }
    
    private func makeLocalDataSource() -> LocalDataSource {
        LocalDataSource(modelContainer: modelContainer)
    }

    private func makeKeychainDataSource() -> KeychainDataSource {
        KeychainDataSource()
    }

    // MARK: - Repositories
    
    func makeDeviceRepository() -> DeviceRepositoryProtocol & DeviceRepositoryScanning {
        DeviceRepository(
            bleDataSource: makeBLEDataSource(),
            localDataSource: makeLocalDataSource(),
            mapper: DeviceMapper()
        )
    }
    
    func makeAuthenticationRepository() -> AuthenticationRepositoryProtocol {
        AuthenticationRepository(
            bleDataSource: makeBLEDataSource(),
            keychainDataSource: makeKeychainDataSource(),
            localDataSource: makeLocalDataSource(),
            cryptoManager: cryptoManager
        )
    }
    
    func makeUserRepository() -> UserRepositoryProtocol {
        UserRepository(
            localDataSource: makeLocalDataSource()
        )
    }
    
    // MARK: - Use Cases
    
    func makeScanForDevicesUseCase() -> ScanForDevicesUseCaseProtocol {
        ScanForDevicesUseCase(deviceRepositoryScanning: makeDeviceRepository())
    }
    
    func makeConnectToDeviceUseCase() -> ConnectToDeviceUseCaseProtocol {
        ConnectToDeviceUseCase(
            deviceRepository: makeDeviceRepository(),
            authenticationRepository: makeAuthenticationRepository()
        )
    }
    
    func makeControlPergolaUseCase() -> ControlPergolaUseCaseProtocol {
        ControlPergolaUseCase(
            deviceRepository: makeDeviceRepository(),
            authenticationRepository: makeAuthenticationRepository()
        )
    }
    
    func makeGetDeviceStatusUseCase() -> GetDeviceStatusUseCaseProtocol {
        GetDeviceStatusUseCase(
            deviceRepository: makeDeviceRepository()
        )
    }
    
    func makeDisconnectDeviceUseCase() -> DisconnectDeviceUseCaseProtocol {
        DisconnectDeviceUseCase(
            deviceRepository: makeDeviceRepository(),
            authenticationRepository: makeAuthenticationRepository()
        )
    }
    
    func makeAuthenticateUserUseCase() -> AuthenticateUserUseCaseProtocol {
        AuthenticateUserUseCase(
            authenticationRepository: makeAuthenticationRepository(),
            deviceRepository: makeDeviceRepository()
        )
    }
    
    func makeCreateInvitationUseCase() -> CreateInvitationUseCaseProtocol {
        CreateInvitationUseCase(
            userRepository: makeUserRepository(),
            deviceRepository: makeDeviceRepository(),
            authenticationRepository: makeAuthenticationRepository()
        )
    }
    
    // MARK: - View Models
    
//    func makeControlViewModel() -> ControlViewModel {
//        ControlViewModel(
//            connectUseCase: makeConnectToDeviceUseCase(),
//            controlUseCase: makeControlPergolaUseCase(),
//            getStatusUseCase: makeGetDeviceStatusUseCase(),
//            disconnectUseCase: makeDisconnectDeviceUseCase()
//        )
//    }
//    
    func makeScanViewModel() -> ScanViewModel {
        ScanViewModel(
            scanningUseCase: makeScanForDevicesUseCase(),
            connectionUseCase: makeConnectToDeviceUseCase()
        )
    }
}
