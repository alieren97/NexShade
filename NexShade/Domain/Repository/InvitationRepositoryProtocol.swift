//
//  InvitationRepositoryProtocol.swift
//  NexShade
//
//  Created by Gedikoglu, Ali on 8.11.2025.
//

import Foundation

protocol InvitationRepositoryProtocol {
    func createInvitation(_ invitation: Invitation, on deviceId: UUID) async throws
    func getInvitations(for deviceId: UUID) async throws -> [Invitation]
    func getInvitation(code: String) async throws -> Invitation?
    func redeemInvitation(code: String, publicKey: String) async throws -> User
    func revokeInvitation(id: UUID) async throws
}
