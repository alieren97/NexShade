//
//  ControlCoordinator.swift
//  NexShade
//
//  Created by Gedikoglu, Ali on 6.11.2025.
//

import SwiftUI
import Observation

@Observable
@MainActor
final class ControlCoordinator: Coordinator {

    // MARK: - Coordinator Protocol Requirements

    var navigationPath = NavigationPath()
    var presentedSheet: PresentedSheet?
    var presentedFullScreenCover: PresentedSheet?

    // MARK: - Additional Properties

    var selectedDeviceId: UUID?
    var showAlert = false
    var alertConfig: AlertConfig?

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
        ControlCoordinatorView(coordinator: self)
    }

    // MARK: - Custom Navigation Methods

    func selectDevice(_ deviceId: UUID) {
        selectedDeviceId = deviceId
    }

    func showActivityLog(for deviceId: UUID) {
        navigate(to: .activityLog(deviceId))
    }

    func showError(title: String, message: String) {
        alertConfig = AlertConfig(
            title: title,
            message: message,
            primaryButton: nil
        )
        showAlert = true
    }

    func navigateToScanTab() {
        parent?.switchToTab(.scan)
    }

    func presentFullScreen(_ sheet: PresentedSheet) {
        presentedFullScreenCover = sheet
    }
}

// MARK: - Coordinator View

struct ControlCoordinatorView: View {

    let coordinator: ControlCoordinator

    var body: some View {
        @Bindable var coordinator = coordinator

        NavigationStack(path: $coordinator.navigationPath) {
            contentView
                .navigationDestination(for: Route.self) { route in
                    destinationView(for: route)
                }
        }
        .sheet(item: $coordinator.presentedSheet) { sheet in
            sheetView(for: sheet)
        }
        .fullScreenCover(item: $coordinator.presentedFullScreenCover) { sheet in
            sheetView(for: sheet)
        }
        .alert(
            coordinator.alertConfig?.title ?? "Alert",
            isPresented: $coordinator.showAlert,
            presenting: coordinator.alertConfig
        ) { config in
            if let button = config.primaryButton {
                Button(button.title, role: button.role) {
                    button.action()
                }
            }
            Button("OK", role: .cancel) {
                coordinator.showAlert = false
            }
        } message: { config in
            Text(config.message)
        }
    }

    @ViewBuilder
    private var contentView: some View {
        if let deviceId = coordinator.selectedDeviceId {
            EmptyView()
//            ControlView(
//                deviceId: deviceId,
//                viewModel: coordinator.container.makeControlViewModel(),
//                coordinator: coordinator
//            )
        } else {
            EmptyView()
//            ControlEmptyStateView(coordinator: coordinator)
        }
    }

    @ViewBuilder
    private func destinationView(for route: Route) -> some View {
        switch route {
        case .deviceDetail(let id):
            EmptyView()
//            DeviceDetailView(
//                deviceId: id,
//                viewModel: coordinator.container.makeDeviceDetailViewModel()
//            )

        case .activityLog(let id):
            EmptyView()
//            ActivityLogView(
//                deviceId: id,
//                viewModel: coordinator.container.makeActivityLogViewModel()
//            )

        default:
            Text("Not implemented")
        }
    }

    @ViewBuilder
    private func sheetView(for sheet: PresentedSheet) -> some View {
        switch sheet {
        case .userManagement(let deviceId):
            EmptyView()
//            UserManagementView(deviceId: deviceId)
        default:
            Text("Sheet")
        }
    }
}

// Alert configuration model
struct AlertConfig {
    let title: String
    let message: String
    let primaryButton: AlertButton?

    struct AlertButton {
        let title: String
        let role: ButtonRole?
        let action: () -> Void
    }
}
