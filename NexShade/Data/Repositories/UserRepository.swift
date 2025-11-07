//
//  UserRepository.swift
//  NexShade
//
//  Created by Ali Eren on 6.11.2025.
//


final class UserRepository: UserRepositoryProtocol {
    
    private let localDataSource: LocalDataSource
    
    init(localDataSource: LocalDataSource) {
        self.localDataSource = localDataSource
    }
}
