//
//  PergolaCommand.swift
//  NexShade
//
//  Created by Ali Eren on 6.11.2025.
//


enum PergolaCommand {
    case open
    case close
    case stop
    case setPosition(Int)
    
    var stringValue: String {
        switch self {
        case .open:
            return "open"
        case .close:
            return "close"
        case .stop:
            return "stop"
        case .setPosition(let position):
            // Example: "set-position:50"
            return "set-position:\(position)"
        }
    }
}
