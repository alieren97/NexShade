//
//  PergolaCommand.swift
//  NexShade
//
//  Created by Ali Eren on 6.11.2025.
//

enum PergolaCommand: Equatable {
    case open
    case close
    case stop
    case setPosition(Int)

    var description: String {
        switch self {
        case .open: return "Open"
        case .close: return "Close"
        case .stop: return "Stop"
        case .setPosition(let pos): return "Set Position to \(pos)%"
        }
    }
}
