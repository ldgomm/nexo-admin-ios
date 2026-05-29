//
//  AuthDTOs.swift
//  Nexo Admin
//
//  Created by José Ruiz on 20/5/26.
//

import Foundation

struct LoginRequestDTO: Encodable, Sendable {
    let email: String
    let password: String
}

struct RefreshTokenRequestDTO: Encodable, Sendable {
    let refreshToken: String
}

struct RevokeSessionRequestDTO: Encodable, Sendable {
    let sessionId: String?
    let reason: String
}

struct AuthTokenResponseDTO: Decodable, Sendable {
    let accessToken: String
    let accessTokenExpiresAt: String
    let refreshToken: String
    let refreshTokenExpiresAt: String
    let sessionId: String
    let userId: String
    let mustChangePassword: Bool
}

struct RefreshSessionResponseDTO: Decodable, Sendable {
    let accessToken: String
    let accessTokenExpiresAt: String
    let refreshToken: String
    let refreshTokenExpiresAt: String
    let sessionId: String
    let userId: String
}

struct RevokeSessionResponseDTO: Decodable, Sendable, Equatable {
    let revokedSessions: Int
    let revokedRefreshTokens: Int
}

struct UserResponseDTO: Decodable, Sendable {
    let id: String
    let email: String
    let displayName: String
    let status: String
    let phone: String?
    let createdAt: String
    let updatedAt: String
}

struct CurrentSessionResponseDTO: Decodable, Sendable {
    let id: String
    let userId: String
    let status: String
    let createdAt: String
    let expiresAt: String
    let lastSeenAt: String?
}

struct OrganizationResponseDTO: Decodable, Sendable {
    let id: String
    let countryCode: String
    let taxId: String
    let legalName: String
    let commercialName: String
    let status: String
    let ownerUserId: String
    let createdAt: String
    let updatedAt: String
}

struct OrganizationMembershipResponseDTO: Decodable, Sendable {
    let id: String
    let organizationId: String
    let userId: String
    let roleIds: Set<String>
    let status: String
    let createdAt: String
    let updatedAt: String
    let acceptedAt: String?
}

struct RoleSummaryResponseDTO: Decodable, Sendable {
    let id: String
    let code: String
    let scope: String
    let type: String
    let name: String
    let permissionKeys: Set<String>
    let systemRole: Bool
    let critical: Bool
}

struct MeMembershipResponseDTO: Decodable, Sendable {
    let membership: OrganizationMembershipResponseDTO
    let organization: OrganizationResponseDTO?
    let roles: [RoleSummaryResponseDTO]
}

struct MeResponseDTO: Decodable, Sendable {
    let user: UserResponseDTO
    let currentSession: CurrentSessionResponseDTO
    let memberships: [MeMembershipResponseDTO]
    let activeOrganization: OrganizationResponseDTO?
    let activeMembership: OrganizationMembershipResponseDTO?
    let roles: [RoleSummaryResponseDTO]
    let effectivePermissions: Set<String>
}

extension AuthTokenResponseDTO {
    func toTokens() -> SessionTokens {
        SessionTokens(
            accessToken: accessToken,
            accessTokenExpiresAt: accessTokenExpiresAt,
            refreshToken: refreshToken,
            refreshTokenExpiresAt: refreshTokenExpiresAt,
            sessionId: sessionId,
            userId: userId,
            mustChangePassword: mustChangePassword
        )
    }
}

extension MeResponseDTO {
    func toDomain() -> MeContext {
        MeContext(
            user: user.toDomain(),
            currentSession: currentSession.toDomain(),
            memberships: memberships.compactMap { $0.toDomain() },
            activeOrganization: activeOrganization?.toDomain(),
            activeMembership: activeMembership?.toDomain(),
            roles: roles.map { $0.toDomain() },
            effectivePermissions: effectivePermissions
        )
    }
}

private extension UserResponseDTO {
    func toDomain() -> AdminUser {
        AdminUser(id: id, email: email, displayName: displayName, status: status, phone: phone)
    }
}

private extension CurrentSessionResponseDTO {
    func toDomain() -> CurrentSession {
        CurrentSession(id: id, userId: userId, status: status, createdAt: createdAt, expiresAt: expiresAt, lastSeenAt: lastSeenAt)
    }
}

private extension OrganizationResponseDTO {
    func toDomain() -> AdminOrganization {
        AdminOrganization(id: id, countryCode: countryCode, taxId: taxId, legalName: legalName, commercialName: commercialName, status: status, ownerUserId: ownerUserId)
    }
}

private extension OrganizationMembershipResponseDTO {
    func toDomain() -> AdminMembership {
        AdminMembership(id: id, organizationId: organizationId, userId: userId, roleIds: roleIds, status: status)
    }
}

private extension RoleSummaryResponseDTO {
    func toDomain() -> AdminRole {
        AdminRole(id: id, code: code, scope: scope, type: type, name: name, permissionKeys: permissionKeys, systemRole: systemRole, critical: critical)
    }
}

private extension MeMembershipResponseDTO {
    func toDomain() -> OrganizationChoice? {
        guard let organization else { return nil }
        return OrganizationChoice(
            organization: organization.toDomain(),
            membership: membership.toDomain(),
            roles: roles.map { $0.toDomain() }
        )
    }
}
