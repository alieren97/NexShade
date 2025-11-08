//
//  PergolaStatus.swift
//  NexShade
//
//  Created by Ali Eren on 6.11.2025.
//

import Foundation

struct PergolaStatus: Equatable, Codable, Hashable {
    var position: Int
    var isMoving: Bool
    var direction: Direction?
    var lastUpdated: Date

    init(
        position: Int,
        isMoving: Bool = false,
        direction: Direction? = nil,
        lastUpdated: Date = Date()
    ) {
        self.position = min(max(position, 0), 100)
        self.isMoving = isMoving
        self.direction = direction
        self.lastUpdated = lastUpdated
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(position)
        hasher.combine(isMoving)
        hasher.combine(direction)
    }

    var isFullyOpen: Bool { position == 100 }
    var isFullyClosed: Bool { position == 0 }

    var stateDescription: String {
        if isMoving {
            if let direction = direction {
                return "Moving (\(direction.rawValue))"
            }
            return "Moving"
        }
        if isFullyOpen { return "Fully Open" }
        if isFullyClosed { return "Fully Closed" }
        return "Stopped at \(position)%"
    }
}

enum Direction: String, Codable, Equatable, Hashable {
    case opening = "Opening"
    case closing = "Closing"
}
