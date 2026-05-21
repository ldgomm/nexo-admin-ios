//
//  AuthAPI.swift
//  Nexo Admin
//
//  Created by José Ruiz on 20/5/26.
//

import Combine

protocol AuthAPI: Sendable {
    func login(email: String, password: String) async throws -> AuthTokenResponseDTO
    func me(organizationId: String?) async throws -> MeResponseDTO
    func logout(sessionId: String?, reason: String) async throws -> RevokeSessionResponseDTO
}

final class RemoteAuthAPI: AuthAPI, @unchecked Sendable {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func login(email: String, password: String) async throws -> AuthTokenResponseDTO {
        try await apiClient.send(
            APIEndpoint(path: "/auth/login", method: .post, requiresAuth: false),
            body: LoginRequestDTO(email: email, password: password)
        )
    }

    func me(organizationId: String?) async throws -> MeResponseDTO {
        var headers: [String: String] = [:]
        if let organizationId, !organizationId.isEmpty {
            headers["X-Organization-Id"] = organizationId
        }

        return try await apiClient.send(
            APIEndpoint(path: "/me", method: .get, headers: headers, requiresAuth: true)
        )
    }

    func logout(sessionId: String?, reason: String) async throws -> RevokeSessionResponseDTO {
        try await apiClient.send(
            APIEndpoint(path: "/auth/sessions/revoke", method: .post, requiresAuth: true),
            body: RevokeSessionRequestDTO(sessionId: sessionId, reason: reason)
        )
    }
}
