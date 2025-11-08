//
//  UserRepositoryProtocol.swift
//  NexShade
//
//  Created by Ali Eren on 6.11.2025.
//

import Foundation

protocol UserRepositoryProtocol {
    func getUsers(for deviceId: UUID) async throws -> [User]
    func getUser(id: UUID) async throws -> User?
    func addUser(_ user: User) async throws
    func updateUser(_ user: User) async throws
    func removeUser(id: UUID) async throws
}
