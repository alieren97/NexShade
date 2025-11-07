//
//  PergolaStatus.swift
//  NexShade
//
//  Created by Ali Eren on 6.11.2025.
//

import Foundation

/// Pergola status entity - represents current state of the pergola
struct PergolaStatus: Equatable, Codable, Hashable {
    
    // MARK: - Position
    
    /// Current position (0-100%)
    var position: Int
    
    // MARK: - Movement
    
    /// Whether the pergola is currently moving
    var isMoving: Bool
    
    /// Direction of movement (if moving)
    var direction: Direction?
    
    // MARK: - Metadata
    
    var lastUpdated: Date
    
    // MARK: - Initialization
    
    init(
        position: Int,
        isMoving: Bool = false,
        direction: Direction? = nil,
        lastUpdated: Date = Date()
    ) {
        self.position = min(max(position, 0), 100) // Clamp 0-100
        self.isMoving = isMoving
        self.direction = direction
        self.lastUpdated = lastUpdated
    }
    
    // MARK: - Computed Properties
    
    /// Whether the pergola is fully open
    var isFullyOpen: Bool {
        position == 100
    }
    
    /// Whether the pergola is fully closed
    var isFullyClosed: Bool {
        position == 0
    }
    
    /// Display text for current state
    var stateDescription: String {
        if isMoving {
            if let direction = direction {
                return "Moving (\(direction.rawValue))"
            }
            return "Moving"
        }
        
        if isFullyOpen {
            return "Fully Open"
        }
        
        if isFullyClosed {
            return "Fully Closed"
        }
        
        return "Stopped at \(position)%"
    }
}

// MARK: - Direction

enum Direction: String, Codable, Equatable {
    case opening = "Opening"
    case closing = "Closing"
}
