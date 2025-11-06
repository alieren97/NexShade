//
//  SettingsCoordinator.swift
//  NexShade
//
//  Created by Gedikoglu, Ali on 6.11.2025.
//

import SwiftUI
import Observation

@Observable
@MainActor
final class SettingsCoordinator: Coordinator {

    // MARK: - Coordinator Protocol Requirements

    var navigationPath = NavigationPath()
    var presentedSheet: PresentedSheet?
    var presentedFullScreenCover: PresentedSheet?

    // MARK: - Dependencies

    private let container: DependencyContainer
    private weak var parent: TabCoordinator?

    // MARK: - Initialization

    init(container: DependencyContainer, parent: TabCoordinator?) {
        self.container = container
        self.parent = parent
    }

    // MARK: - Coordinator Protocol - start()

    func start() -> some View {
        SettingsCoordinatorView(coordinator: self)
    }

    // MARK: - Protocol methods inherited

    // MARK: - Custom Navigation

    func showUserManagement(for deviceId: UUID) {
        navigate(to: .userManagement(deviceId))
    }

    func showInvitationCreation(for deviceId: UUID) {
        present(.invitationCreation(deviceId))
    }

    func showServiceSettings(for deviceId: UUID) {
        navigate(to: .serviceAccessSettings(deviceId))
    }
}

struct SettingsCoordinatorView: View {

    let coordinator: SettingsCoordinator

    var body: some View {
        @Bindable var coordinator = coordinator

        NavigationStack(path: $coordinator.navigationPath) {
            EmptyView()
//            SettingsView(
//                viewModel: coordinator.container.makeSettingsViewModel(),
//                coordinator: coordinator
//            )
            .navigationDestination(for: Route.self) { route in
                destinationView(for: route)
            }
        }
        .sheet(item: $coordinator.presentedSheet) { sheet in
            sheetView(for: sheet)
        }
    }

    @ViewBuilder
    private func destinationView(for route: Route) -> some View {
        switch route {
        case .userManagement(let deviceId):
            EmptyView()
//            UserManagementView(
//                deviceId: deviceId,
//                viewModel: coordinator.container.makeUserManagementViewModel(),
//                coordinator: coordinator
//            )

        case .serviceAccessSettings(let deviceId):
            EmptyView()
//            ServiceAccessSettingsView(
//                deviceId: deviceId,
//                viewModel: coordinator.container.makeServiceAccessViewModel()
//            )

        case .profile:
            EmptyView()
//            ProfileView(
//                viewModel: coordinator.container.makeProfileViewModel()
//            )

        case .security:
            EmptyView()
//            SecuritySettingsView(
//                viewModel: coordinator.container.makeSecurityViewModel()
//            )

        default:
            Text("Not implemented")
        }
    }

    @ViewBuilder
    private func sheetView(for sheet: PresentedSheet) -> some View {
        switch sheet {
        case .invitationCreation(let deviceId):
            EmptyView()
//            InvitationCreationFlow(
//                deviceId: deviceId,
//                viewModel: coordinator.container.makeInvitationViewModel()
//            ) { invitation in
//                coordinator.dismiss()
//            }

        default:
            EmptyView()
        }
    }
}
