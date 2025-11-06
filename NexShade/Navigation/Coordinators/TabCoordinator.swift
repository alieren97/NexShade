//
//  TabCoordinator.swift
//  NexShade
//
//  Created by Gedikoglu, Ali on 6.11.2025.
//

import SwiftUI
import Observation

@Observable
@MainActor
final class TabCoordinator {

    // Tab state
    var selectedTab: TabItem = .control
    var savedNavigationState: NavigationState?

    // Child coordinators - ALL conform to Coordinator protocol
    var controlCoordinator: ControlCoordinator?
    var scanCoordinator: ScanCoordinator?
    var settingsCoordinator: SettingsCoordinator?
    var setupCoordinator: SetupCoordinator?

    private let container: DependencyContainer
    private let userRole: UserRole

    init(container: DependencyContainer, userRole: UserRole) {
        self.container = container
        self.userRole = userRole
        setupCoordinators()
    }

    private func setupCoordinators() {
        // All coordinators conform to Coordinator protocol
        controlCoordinator = ControlCoordinator(
            container: container,
            parent: self
        )

        scanCoordinator = ScanCoordinator(
            container: container,
            parent: self
        )

        settingsCoordinator = SettingsCoordinator(
            container: container,
            parent: self
        )

        if userRole == .serviceTechnician {
            setupCoordinator = SetupCoordinator(
                container: container,
                parent: self
            )
        }
    }

    func start() -> some View {
        TabCoordinatorView(coordinator: self)
    }

    // MARK: - Navigation

    func navigateToDevice(_ deviceId: UUID) {
        selectedTab = .control
        controlCoordinator?.selectDevice(deviceId)
    }

    func navigateToInvitation(code: String) {
        selectedTab = .scan
        scanCoordinator?.showInvitationEntry(code: code)
    }

    func switchToTab(_ tab: TabItem) {
        selectedTab = tab
    }

    var visibleTabs: [TabItem] {
        TabItem.allCases.filter { $0.isVisible(for: userRole) }
    }
}

struct TabCoordinatorView: View {

    let coordinator: TabCoordinator

    var body: some View {
        @Bindable var coordinator = coordinator

        TabView(selection: $coordinator.selectedTab) {
            ForEach(coordinator.visibleTabs, id: \.self) { tab in
                tabContent(for: tab)
                    .tabItem {
                        Label(
                            tab.title,
                            systemImage: coordinator.selectedTab == tab
                                ? tab.iconFilled
                                : tab.icon
                        )
                    }
                    .tag(tab)
            }
        }
        .tint(.blue)
    }

    @ViewBuilder
    private func tabContent(for tab: TabItem) -> some View {
        switch tab {
        case .control:
            if let coordinator = coordinator.controlCoordinator {
                coordinator.start()
            }
        case .scan:
            if let coordinator = coordinator.scanCoordinator {
                coordinator.start()
            }
        case .settings:
            if let coordinator = coordinator.settingsCoordinator {
                coordinator.start()
            }
        case .setup:
            if let coordinator = coordinator.setupCoordinator {
                coordinator.start()
            }
        }
    }
}
