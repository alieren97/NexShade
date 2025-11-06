//
//  TabItem.swift
//  NexShade
//
//  Created by Gedikoglu, Ali on 6.11.2025.
//

import SwiftUI

enum TabItem: Int, CaseIterable {
    case control
    case scan
    case settings
    case setup // Only visible for service techs
    
    var title: String {
        switch self {
        case .control: return "Control"
        case .scan: return "Scan"
        case .settings: return "Settings"
        case .setup: return "Setup"
        }
    }
    
    var icon: String {
        switch self {
        case .control: return "slider.horizontal.3"
        case .scan: return "antenna.radiowaves.left.and.right"
        case .settings: return "gearshape"
        case .setup: return "wrench.and.screwdriver"
        }
    }
    
    var iconFilled: String {
        switch self {
        case .control: return "slider.horizontal.3"
        case .scan: return "antenna.radiowaves.left.and.right"
        case .settings: return "gearshape.fill"
        case .setup: return "wrench.and.screwdriver.fill"
        }
    }
    
    // Role-based visibility
    func isVisible(for role: UserRole) -> Bool {
        switch self {
        case .setup:
            return role == .serviceTechnician
        default:
            return true
        }
    }
}
