//
//  AuthModels.swift
//  Nexo Admin
//
//  Created by José Ruiz on 20/5/26.
//

import Foundation

struct SessionTokens: Codable, Equatable, Sendable {
    let accessToken: String
    let accessTokenExpiresAt: String
    let refreshToken: String
    let refreshTokenExpiresAt: String
    let sessionId: String
    let userId: String
    let mustChangePassword: Bool
}

struct AdminUser: Identifiable, Equatable, Sendable {
    let id: String
    let email: String
    let displayName: String
    let status: String
    let phone: String?
}

struct CurrentSession: Identifiable, Equatable, Sendable {
    let id: String
    let userId: String
    let status: String
    let createdAt: String
    let expiresAt: String
    let lastSeenAt: String?
}

struct AdminOrganization: Identifiable, Equatable, Sendable {
    let id: String
    let countryCode: String
    let taxId: String
    let legalName: String
    let commercialName: String
    let status: String
    let ownerUserId: String
}

struct AdminMembership: Identifiable, Equatable, Sendable {
    let id: String
    let organizationId: String
    let userId: String
    let roleIds: Set<String>
    let status: String
}

struct AdminRole: Identifiable, Equatable, Sendable {
    let id: String
    let code: String
    let scope: String
    let type: String
    let name: String
    let permissionKeys: Set<String>
    let systemRole: Bool
    let critical: Bool
}

struct OrganizationChoice: Identifiable, Equatable, Sendable {
    let organization: AdminOrganization
    let membership: AdminMembership
    let roles: [AdminRole]

    var id: String { organization.id }
    var title: String { organization.commercialName.isEmpty ? organization.legalName : organization.commercialName }
    var subtitle: String { "RUC \(organization.taxId) • \(membership.status)" }
}

struct MeContext: Equatable, Sendable {
    let user: AdminUser
    let currentSession: CurrentSession
    let memberships: [OrganizationChoice]
    let activeOrganization: AdminOrganization?
    let activeMembership: AdminMembership?
    let roles: [AdminRole]
    let effectivePermissions: Set<String>
}
