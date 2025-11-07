//
//  PergolaStatus.swift
//  NexShade
//
//  Created by Ali Eren on 6.11.2025.
//

import Foundation

struct PergolaStatus {
    let position: Int           // 0-100%
    let isMoving: Bool
    let direction: Direction?
    let lastUpdated: Date
    
    enum Direction {
        case opening
        case closing
    }
}
