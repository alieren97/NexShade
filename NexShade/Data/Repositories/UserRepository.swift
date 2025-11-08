//
//  UserRepository.swift
//  NexShade
//
//  Created by Ali Eren on 6.11.2025.
//

import Foundation

final class UserRepository: UserRepositoryProtocol {


    private let localDataSource: LocalDataSource
    
    init(localDataSource: LocalDataSource) {
        self.localDataSource = localDataSource
    }

    func getUsers(for deviceId: UUID) async throws -> [User] {
        return []
    }

    func getUser(id: UUID) async throws -> User? {
        return nil
    }

    func addUser(_ user: User) async throws {

    }

    func updateUser(_ user: User) async throws {

    }

    func removeUser(id: UUID) async throws {

    }

}
