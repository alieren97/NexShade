//
//  Invitation.swift
//  NexShade
//
//  Created by Ali Eren on 7.11.2025.
//

import Foundation

struct Invitation: Identifiable, Equatable, Hashable, Codable {
    let id: UUID
    let deviceId: UUID
    let code: String
    let permissions: Permissions
    var guestName: String?
    var guestPublicKey: String?
    let createdAt: Date
    let expiresAt: Date?
    var redeemedAt: Date?
    var isRedeemed: Bool

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

    var isExpired: Bool {
        guard let expiresAt = expiresAt else { return false }
        return Date() > expiresAt
    }

    var isValid: Bool { !isRedeemed && !isExpired }

    var formattedCode: String {
        let index = code.index(code.startIndex, offsetBy: 4)
        return "\(code[..<index])-\(code[index...])"
    }
}
