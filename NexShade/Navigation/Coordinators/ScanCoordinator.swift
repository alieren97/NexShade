//
//  ScanCoordinator.swift
//  NexShade
//
//  Created by Gedikoglu, Ali on 6.11.2025.
//

import SwiftUI
import Observation

@Observable
@MainActor
final class ScanCoordinator: Coordinator {

    // MARK: - Coordinator Protocol Requirements

    var navigationPath = NavigationPath()
    var presentedSheet: PresentedSheet?
    var presentedFullScreenCover: PresentedSheet?

    // MARK: - Additional Properties

    var invitationCode: String?

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
        ScanCoordinatorView(coordinator: self)
    }

    // MARK: - Protocol methods inherited from extension

    // MARK: - Custom Methods

    func showInvitationEntry(code: String? = nil) {
        invitationCode = code
        navigate(to: .invitationEntry)
    }

    func showQRScanner() {
        presentedFullScreenCover = .qrScanner
    }

    func startProvisioning(deviceId: UUID) {
        presentedFullScreenCover = .deviceProvisioning(deviceId)
    }

    func handleSuccessfulConnection(deviceId: UUID) {
        dismiss()
        parent?.navigateToDevice(deviceId)
    }

    func presentFullScreen(_ sheet: PresentedSheet) {
        presentedFullScreenCover = sheet
    }
}

struct ScanCoordinatorView: View {

    let coordinator: ScanCoordinator

    var body: some View {
        @Bindable var coordinator = coordinator

        NavigationStack(path: $coordinator.navigationPath) {
//            EmptyView()
            VStack(content: {
                Text("Scan View")
            })
//            ScanView(
//                viewModel: coordinator.container.makeScanViewModel(),
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
        case .invitationEntry:
            EmptyView()
//            InvitationEntryView(
//                initialCode: coordinator.invitationCode,
//                viewModel: coordinator.container.makeInvitationViewModel(),
//                coordinator: coordinator
//            )
        default:
            EmptyView()
        }
    }

    @ViewBuilder
    private func sheetView(for sheet: PresentedSheet) -> some View {
        EmptyView()
    }

    @ViewBuilder
    private func fullScreenView(for sheet: PresentedSheet) -> some View {
        switch sheet {
        case .qrScanner:
            EmptyView()
//            QRScannerView { code in
//                coordinator.showInvitationEntry(code: code)
//                coordinator.dismiss()
//            }

        case .deviceProvisioning(let deviceId):
            EmptyView()
//            ProvisioningFlowView(
//                deviceId: deviceId,
//                viewModel: coordinator.container.makeProvisioningViewModel(),
//                coordinator: coordinator
//            )

        default:
            EmptyView()
        }
    }
}
