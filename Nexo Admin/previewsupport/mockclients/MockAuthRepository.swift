//
//  MockAuthRepository.swift
//  Nexo Admin
//
//  Created by José Ruiz on 20/5/26.
//

import Foundation

final class MockAuthRepository: AuthRepository, @unchecked Sendable {
    
    var loginResult: Result<SessionTokens, Error>
    var meResult: Result<MeContext, Error>
    var logoutResult: Result<RevokeSessionResponseDTO, Error>

    init(
        loginResult: Result<SessionTokens, Error> = .success(SessionTokens(
            accessToken: "access",
            accessTokenExpiresAt: "2026-05-20T01:00:00Z",
            refreshToken: "refresh",
            refreshTokenExpiresAt: "2026-06-20T01:00:00Z",
            sessionId: "ses_1",
            userId: "usr_owner",
            mustChangePassword: false
        )),
        meResult: Result<MeContext, Error> = .success(MockSessionData.me),
        logoutResult: Result<RevokeSessionResponseDTO, Error> = .success(RevokeSessionResponseDTO(revokedSessions: 1, revokedRefreshTokens: 1))
    ) {
        self.loginResult = loginResult
        self.meResult = meResult
        self.logoutResult = logoutResult
    }

    func login(email: String, password: String) async throws -> SessionTokens {
        try loginResult.get()
    }

    func loadMe(organizationId: String?) async throws -> MeContext {
        try meResult.get()
    }

    func logout(sessionId: String?, reason: String) async throws -> RevokeSessionResponseDTO {
        try logoutResult.get()
    }
    
    func recoverSessions(email: String, password: String, reason: String) async throws -> SessionTokens {
        try loginResult.get()
    }
}
