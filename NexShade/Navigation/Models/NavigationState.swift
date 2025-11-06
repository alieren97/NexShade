//
//  NavigationState.swift
//  NexShade
//
//  Created by Gedikoglu, Ali on 6.11.2025.
//

import SwiftUI

struct NavigationState: Codable {
    let selectedTab: TabItem.RawValue
    let controlPath: [RouteData]?
    let scanPath: [RouteData]?
    let settingsPath: [RouteData]?
    
    init(
        selectedTab: TabItem,
        controlPath: NavigationPath?,
        scanPath: NavigationPath?,
        settingsPath: NavigationPath?
    ) {
        self.selectedTab = selectedTab.rawValue
        self.controlPath = controlPath?.codableRepresentation()
        self.scanPath = scanPath?.codableRepresentation()
        self.settingsPath = settingsPath?.codableRepresentation()
    }
}

// Extension to convert NavigationPath to Codable
extension NavigationPath {
    func codableRepresentation() -> [RouteData]? {
        // Convert path to codable format
        // Implementation depends on Route structure
        nil
    }
    
    static func from(_ routes: [RouteData]) -> NavigationPath {
        let path = NavigationPath()
        // Reconstruct path from routes
        return path
    }
}

struct RouteData: Codable {
    let type: String
    let data: [String: String]
}
