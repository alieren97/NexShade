struct User {
    let id: UUID
    let name: String
    let role: UserRole
    let permissions: Permissions
    let addedDate: Date
    let expiresAt: Date?
    let isActive: Bool
}

enum UserRole {
    case owner
    case guest
    case serviceTechnician
}

struct Permissions: OptionSet {
    let rawValue: Int
    
    static let viewOnly      = Permissions(rawValue: 1 << 0)
    static let basicControl  = Permissions(rawValue: 1 << 1)
    static let advancedControl = Permissions(rawValue: 1 << 2)
    static let userManagement = Permissions(rawValue: 1 << 3)
    static let diagnostics   = Permissions(rawValue: 1 << 4)
    
    static let owner: Permissions = [.viewOnly, .basicControl, .advancedControl, .userManagement]
    static let service: Permissions = [.viewOnly, .basicControl, .advancedControl, .diagnostics]
}