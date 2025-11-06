//
//  NexShadeApp.swift
//  NexShade
//
//  Created by Gedikoglu, Ali on 6.11.2025.
//

import SwiftUI
import SwiftData

@main
struct NexShadeApp: App {

    @State private var appCoordinator: AppCoordinator

    init() {
        let container = DependencyContainer()
        appCoordinator = AppCoordinator(container: container)
    }

    var body: some Scene {
        WindowGroup {
            AppCoordinatorView(coordinator: appCoordinator)
        }
    }
}

struct AppCoordinatorView: View {

    let coordinator: AppCoordinator

    var body: some View {
        coordinator.start()
    }
}
