//
//  SetupCoordinator.swift
//  NexShade
//
//  Created by Gedikoglu, Ali on 6.11.2025.
//

import SwiftUI
import Observation

@Observable
@MainActor
final class SetupCoordinator: Coordinator {

    // MARK: - Coordinator Protocol Requirements

    var navigationPath = NavigationPath()
    var presentedSheet: PresentedSheet?
    var presentedFullScreenCover: PresentedSheet?

    // MARK: - Additional Properties

    var setupInProgress = false
    var currentDeviceId: UUID?

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
        SetupCoordinatorView(coordinator: self)
    }

    // MARK: - Protocol methods inherited

    // MARK: - Setup Flow Methods

    func startSetupWizard() {
        setupInProgress = true
        presentedFullScreenCover = .deviceProvisioning(UUID())
    }

    func handleSetupComplete(deviceId: UUID, success: Bool) {
        setupInProgress = false
        currentDeviceId = nil
        navigateToRoot()

        if success {
            parent?.navigateToDevice(deviceId)
        }
    }

    func showServiceReport(for deviceId: UUID) {
        present(.serviceReport(deviceId))
    }

    func presentFullScreen(_ sheet: PresentedSheet) {
        presentedFullScreenCover = sheet
    }
}

struct SetupCoordinatorView: View {

    let coordinator: SetupCoordinator

    var body: some View {
        @Bindable var coordinator = coordinator

        NavigationStack(path: $coordinator.navigationPath) {
            EmptyView()
//            SetupHomeView(
//                viewModel: coordinator.container.makeSetupViewModel(),
//                coordinator: coordinator
//            )
            .navigationDestination(for: Route.self) { route in
                destinationView(for: route)
            }
        }
        .sheet(item: $coordinator.presentedSheet) { sheet in
            sheetView(for: sheet)
        }
        .fullScreenCover(item: $coordinator.presentedFullScreenCover) { sheet in
            fullScreenView(for: sheet)
        }
    }

    @ViewBuilder
    private func destinationView(for route: Route) -> some View {
        switch route {
        case .calibration(let deviceId):
            EmptyView()
//            CalibrationView(
//                deviceId: deviceId,
//                viewModel: coordinator.container.makeCalibrationViewModel(),
//                coordinator: coordinator
//            )

        case .setupCompletion(let result):
            EmptyView()
//            SetupCompletionView(
//                result: result,
//                coordinator: coordinator
//            )

        default:
            EmptyView()
        }
    }

    @ViewBuilder
    private func sheetView(for sheet: PresentedSheet) -> some View {
        switch sheet {
        case .serviceReport(let deviceId):
            EmptyView()
//            ServiceReportView(
//                deviceId: deviceId,
//                viewModel: coordinator.container.makeServiceReportViewModel()
//            )

        default:
            EmptyView()
        }
    }

    @ViewBuilder
    private func fullScreenView(for sheet: PresentedSheet) -> some View {
        switch sheet {
        case .deviceProvisioning:
            EmptyView()
//            SetupWizardFlow(
//                viewModel: coordinator.container.makeSetupWizardViewModel(),
//                coordinator: coordinator
//            )

        default:
            EmptyView()
        }
    }
}
