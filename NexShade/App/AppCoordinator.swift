//
//  AppCoordinator.swift
//  NexShade
//
//  Created by Gedikoglu, Ali on 6.11.2025.
//

import SwiftUI
import Observation

@Observable
@MainActor
final class AppCoordinator {

    var currentUserRole: UserRole = .serviceTechnician
    var tabCoordinator: TabCoordinator?

    // Dependencies
    private let container: DependencyContainer

    init(container: DependencyContainer) {
        self.container = container
    }

    func start() -> some View {
        let coordinator = TabCoordinator(
            container: container,
            userRole: currentUserRole
        )
        self.tabCoordinator = coordinator
        return coordinator.start()
    }

    func updateUserRole(_ role: UserRole) {
        currentUserRole = role
        // Recreate tab coordinator
        tabCoordinator = TabCoordinator(
            container: container,
            userRole: role
        )
    }

//    func handle(deepLink: DeepLink) {
//        switch deepLink {
//        case .device(let id):
//            tabCoordinator?.navigateToDevice(id)
//        case .invitation(let code):
//            tabCoordinator?.navigateToInvitation(code: code)
//        case .settings:
//            tabCoordinator?.selectedTab = .settings
//        }
//    }
}
