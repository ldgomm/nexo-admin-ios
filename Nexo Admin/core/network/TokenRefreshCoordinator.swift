//
//  TokenRefreshCoordinator.swift
//  Nexo Admin
//
//  Created by José Ruiz on 20/5/26.
//

import Foundation

protocol TokenRefreshCoordinating: Sendable {
    func refreshIfNeeded() async throws -> Bool
}

actor TokenRefreshCoordinator: TokenRefreshCoordinating {
    private let environment: AppEnvironment
    private let tokenStore: AuthTokenStorage
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    private var inFlightRefresh: Task<Bool, Error>?

    init(
        environment: AppEnvironment,
        tokenStore: AuthTokenStorage,
        session: URLSession = .shared,
        decoder: JSONDecoder = .nexo,
        encoder: JSONEncoder = .nexo
    ) {
        self.environment = environment
        self.tokenStore = tokenStore
        self.session = session
        self.decoder = decoder
        self.encoder = encoder
    }

    func refreshIfNeeded() async throws -> Bool {
        if let inFlightRefresh {
            return try await inFlightRefresh.value
        }

        let task = Task<Bool, Error> {
            guard let currentTokens = try tokenStore.readTokens() else { return false }

            let endpoint = environment.baseURL.appendingNexoPath("/auth/refresh")
            var request = URLRequest(url: endpoint)
            request.httpMethod = HTTPMethod.post.rawValue
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            let body = RefreshTokenRequestDTO(refreshToken: currentTokens.refreshToken)
            request.httpBody = try encoder.encode(body)

            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AppError.transport("Respuesta HTTP inválida al renovar sesión.")
            }

            guard (200..<300).contains(httpResponse.statusCode) else {
                try? tokenStore.clearTokens()
                return false
            }

            let refreshed = try decoder.decode(RefreshSessionResponseDTO.self, from: data)
            let newTokens = SessionTokens(
                accessToken: refreshed.accessToken,
                accessTokenExpiresAt: refreshed.accessTokenExpiresAt,
                refreshToken: refreshed.refreshToken,
                refreshTokenExpiresAt: refreshed.refreshTokenExpiresAt,
                sessionId: refreshed.sessionId,
                userId: refreshed.userId,
                mustChangePassword: currentTokens.mustChangePassword
            )
            try tokenStore.saveTokens(newTokens)
            return true
        }

        inFlightRefresh = task
        defer { inFlightRefresh = nil }
        return try await task.value
    }
}
