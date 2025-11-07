// Domain/Entities/Invitation.swift

import Foundation

/// Invitation entity - represents an invitation for guest access
struct Invitation: Identifiable, Equatable, Hashable, Codable {
    
    // MARK: - Identity
    
    let id: UUID
    let deviceId: UUID
    
    // MARK: - Invitation Details
    
    let code: String // 8-character alphanumeric code
    let permissions: Permissions
    
    // MARK: - Guest Info
    
    var guestName: String?
    var guestPublicKey: String? // Set when redeemed
    
    // MARK: - Dates
    
    let createdAt: Date
    let expiresAt: Date?
    var redeemedAt: Date?
    
    // MARK: - Status
    
    var isRedeemed: Bool
    
    // MARK: - Initialization
    
    init(
        id: UUID = UUID(),
        deviceId: UUID,
        code: String,
        permissions: Permissions,
        guestName: String? = nil,
        guestPublicKey: String? = nil,
        createdAt: Date = Date(),
        expiresAt: Date? = nil,
        redeemedAt: Date? = nil,
        isRedeemed: Bool = false
    ) {
        self.id = id
        self.deviceId = deviceId
        self.code = code
        self.permissions = permissions
        self.guestName = guestName
        self.guestPublicKey = guestPublicKey
        self.createdAt = createdAt
        self.expiresAt = expiresAt
        self.redeemedAt = redeemedAt
        self.isRedeemed = isRedeemed
    }
    
    // MARK: - Computed Properties
    
    /// Whether the invitation has expired
    var isExpired: Bool {
        guard let expiresAt = expiresAt else {
            return false // No expiration
        }
        return Date() > expiresAt
    }
    
    /// Whether the invitation is still valid (not redeemed and not expired)
    var isValid: Bool {
        !isRedeemed && !isExpired
    }
    
    /// Days until expiration
    var daysUntilExpiration: Int? {
        guard let expiresAt = expiresAt else {
            return nil
        }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: expiresAt)
        return components.day
    }
    
    /// Formatted code for display (e.g., "ABCD-1234")
    var formattedCode: String {
        let index = code.index(code.startIndex, offsetBy: 4)
        let firstPart = code[..<index]
        let secondPart = code[index...]
        return "\(firstPart)-\(secondPart)"
    }
}