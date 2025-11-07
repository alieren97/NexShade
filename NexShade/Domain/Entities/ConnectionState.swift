// MARK: - Connection State
//
//enum ConnectionState: String, Codable, Equatable {
//    case disconnected
//    case scanning
//    case connecting
//    case discoveringServices
//    case discoveringCharacteristics
//    case ready
//    case disconnecting
//    case error
//    
//    var isConnected: Bool {
//        self == .ready
//    }
//    
//    var description: String {
//        switch self {
//        case .disconnected: return "Disconnected"
//        case .scanning: return "Scanning..."
//        case .connecting: return "Connecting..."
//        case .discoveringServices: return "Discovering services..."
//        case .discoveringCharacteristics: return "Setting up..."
//        case .ready: return "Connected"
//        case .disconnecting: return "Disconnecting..."
//        case .error: return "Connection Error"
//        }
//    }
//}
