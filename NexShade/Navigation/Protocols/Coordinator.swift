//
//  Coordinator.swift
//  NexShade
//
//  Created by Gedikoglu, Ali on 6.11.2025.
//

import SwiftUI

protocol Coordinator: AnyObject {
    associatedtype ContentView: View

    var navigationPath: NavigationPath { get set }
    var presentedSheet: PresentedSheet? { get set }
    var presentedFullScreenCover: PresentedSheet? { get set }

    /// Start the coordinator and return its root view
    @MainActor func start() -> ContentView

    /// Navigate to a route
    @MainActor func navigate(to route: Route)

    /// Navigate back one step
    @MainActor func navigateBack()

    /// Navigate to root
    @MainActor func navigateToRoot()

    /// Present a sheet
    @MainActor func present(_ sheet: PresentedSheet)

    /// Dismiss presented sheet/cover
    @MainActor func dismiss()
}

// Default implementations
extension Coordinator {

    func navigate(to route: Route) {
        navigationPath.append(route)
    }

    func navigateBack() {
        guard !navigationPath.isEmpty else { return }
        navigationPath.removeLast()
    }

    func navigateToRoot() {
        navigationPath = NavigationPath()
    }

    func present(_ sheet: PresentedSheet) {
        presentedSheet = sheet
    }

    func dismiss() {
        presentedSheet = nil
        presentedFullScreenCover = nil
    }
}

// Modern sheet presentation
enum PresentedSheet: Identifiable, Hashable {
    case deviceProvisioning(UUID)
    case invitationCreation(UUID)
    case userManagement(UUID)
    case serviceReport(UUID)
    case qrScanner

    var id: String {
        switch self {
        case .deviceProvisioning(let id): return "provisioning-\(id)"
        case .invitationCreation(let id): return "invitation-\(id)"
        case .userManagement(let id): return "users-\(id)"
        case .serviceReport(let id): return "report-\(id)"
        case .qrScanner: return "qr-scanner"
        }
    }
}
