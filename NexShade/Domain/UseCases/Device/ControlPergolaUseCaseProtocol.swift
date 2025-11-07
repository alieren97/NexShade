//
//  ControlPergolaUseCaseProtocol.swift
//  NexShade
//
//  Created by Ali Eren on 6.11.2025.
//


protocol ControlPergolaUseCaseProtocol {
    func execute(deviceId: UUID, command: PergolaCommand) async throws -> PergolaStatus
}