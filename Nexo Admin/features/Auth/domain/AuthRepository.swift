//
//  AuthRepository.swift
//  Nexo Admin
//
//  Created by José Ruiz on 20/5/26.
//

import Foundation

protocol AuthRepository: Sendable {
    func login(email: String, password: String) async throws -> SessionTokens
    func loadMe(organizationId: String?) async throws -> MeContext
    func logout(sessionId: String?, reason: String) async throws -> RevokeSessionResponseDTO
}

final class RemoteAuthRepository: AuthRepository, @unchecked Sendable {
    private let authAPI: AuthAPI

    init(authAPI: AuthAPI) {
        self.authAPI = authAPI
    }

    func login(email: String, password: String) async throws -> SessionTokens {
        try await authAPI.login(email: email, password: password).toTokens()
    }

    func loadMe(organizationId: String?) async throws -> MeContext {
        try await authAPI.me(organizationId: organizationId).toDomain()
    }

    func logout(sessionId: String?, reason: String) async throws -> RevokeSessionResponseDTO {
        try await authAPI.logout(sessionId: sessionId, reason: reason)
    }
}
