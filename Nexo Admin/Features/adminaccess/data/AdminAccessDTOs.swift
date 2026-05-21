//
//  AdminAccessDTOs.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import Foundation

struct AdminUsersResponseDTO: Decodable, Sendable {
    let users: [AdminAccessUserDTO]
}

struct AdminAccessUserDTO: Decodable, Sendable {
    let id: String
    let email: String
    let displayName: String
    let phone: String?
    let status: String
    let membershipId: String
    let membershipStatus: String
    let roleIds: Set<String>
    let roleNames: [String]
    let effectivePermissions: Set<String>
    let activeSessionCount: Int
    let invitedBy: String?
    let acceptedAt: String?
    let blockedAt: String?
    let blockedReason: String?
    let createdAt: String
    let updatedAt: String
    let version: Int?
}

struct CreateTemporaryAdminUserRequestDTO: Encodable, Sendable {
    let email: String
    let displayName: String
    let roleIds: Set<String>
    let temporaryPassword: String?
    let phone: String?
    let reason: String
}

struct AdminTemporaryUserResponseDTO: Decodable, Sendable {
    let user: AdminAccessUserDTO
    let credentialId: String
    let membershipId: String
    let temporaryPassword: String
    let mustChangePassword: Bool
    let createdAt: String
}

struct UpdateAdminUserRequestDTO: Encodable, Sendable {
    let displayName: String?
    let phone: String?
    let clearPhone: Bool
    let roleIds: Set<String>?
    let reason: String
}

struct AdminUserActionRequestDTO: Encodable, Sendable {
    let reason: String
}

struct AdminResetUserPasswordRequestDTO: Encodable, Sendable {
    let temporaryPassword: String?
    let revokeSessions: Bool
    let reason: String
}

struct AdminResetUserPasswordResponseDTO: Decodable, Sendable {
    let userId: String
    let credentialId: String
    let temporaryPassword: String
    let mustChangePassword: Bool
    let revokedSessions: Int
    let revokedRefreshTokens: Int
    let changedAt: String
}

struct AdminUserSessionRevocationResponseDTO: Decodable, Sendable {
    let userId: String
    let revokedSessions: Int
    let revokedRefreshTokens: Int
    let revokedAt: String
    let reason: String
}

struct AdminInvitationsResponseDTO: Decodable, Sendable {
    let invitations: [AdminInvitationDTO]
}

struct AdminInvitationDTO: Decodable, Sendable {
    let id: String
    let organizationId: String
    let email: String
    let invitedByUserId: String
    let roleIds: Set<String>
    let roleNames: [String]
    let status: String
    let createdAt: String
    let expiresAt: String
    let acceptedAt: String?
    let revokedAt: String?
    let acceptedUserId: String?
    let version: Int
}

struct CreateAdminInvitationRequestDTO: Encodable, Sendable {
    let email: String
    let displayName: String
    let roleIds: Set<String>
    let reason: String
}

struct AdminInvitationCreatedResponseDTO: Decodable, Sendable {
    let invitation: AdminInvitationDTO
    let user: AdminAccessUserDTO
    let membershipId: String
    let rawInvitationToken: String
    let invitationUrl: String?
    let createdAt: String
}

struct AdminInvitationActionRequestDTO: Encodable, Sendable {
    let reason: String
}

struct AdminInvitationResendResponseDTO: Decodable, Sendable {
    let invitation: AdminInvitationDTO
    let rawInvitationToken: String
    let invitationUrl: String?
}

struct AdminRolesResponseDTO: Decodable, Sendable {
    let roles: [AdminRoleDTO]
}

struct AdminRoleDTO: Decodable, Sendable {
    let id: String
    let code: String
    let organizationId: String?
    let scope: String
    let type: String
    let name: String
    let description: String
    let permissionKeys: Set<String>
    let systemRole: Bool
    let critical: Bool
    let editable: Bool
    let status: String
    let schemaVersion: Int
}

struct CreateAdminRoleRequestDTO: Encodable, Sendable {
    let code: String
    let name: String
    let description: String
    let permissionKeys: Set<String>
    let reason: String
}

struct UpdateAdminRoleRequestDTO: Encodable, Sendable {
    let name: String?
    let description: String?
    let permissionKeys: Set<String>?
    let reason: String
}

struct AdminRoleActionRequestDTO: Encodable, Sendable {
    let reason: String
}

struct AdminPermissionsResponseDTO: Decodable, Sendable {
    let permissions: [AdminPermissionDTO]
}

struct AdminPermissionDTO: Decodable, Sendable {
    let code: String
    let name: String
    let description: String
    let category: String
    let scope: String
    let riskLevel: String
    let status: String
    let systemManaged: Bool
    let requiresAudit: Bool
    let requiresReason: Bool
    let requiresStepUp: Bool
    let featureFlag: String?
}
