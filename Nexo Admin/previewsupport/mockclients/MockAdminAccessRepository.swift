//
//  MockAdminAccessRepository.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import Foundation

final class MockAdminAccessRepository: AdminAccessRepository, @unchecked Sendable {
    private var users: [AdminAccessUser]
    private var roles: [AdminAccessRole]
    private var invitations: [AdminAccessInvitation]
    private let permissions: [AdminAccessPermission]
    private let capabilityGroups: [AdminHumanCapabilityGroup]
    private let delayNanoseconds: UInt64

    init(
        users: [AdminAccessUser] = MockAdminAccessData.users,
        roles: [AdminAccessRole] = MockAdminAccessData.roles,
        invitations: [AdminAccessInvitation] = MockAdminAccessData.invitations,
        permissions: [AdminAccessPermission] = MockAdminAccessData.permissions,
        capabilityGroups: [AdminHumanCapabilityGroup] = MockAdminAccessData.capabilityGroups,
        delayNanoseconds: UInt64 = 200_000_000
    ) {
        self.users = users
        self.roles = roles
        self.invitations = invitations
        self.permissions = permissions
        self.capabilityGroups = capabilityGroups
        self.delayNanoseconds = delayNanoseconds
    }

    func listUsers(query: String?, status: String?, limit: Int) async throws -> [AdminAccessUser] {
        try await delay()
        return users
            .filter { user in
                guard let query, !query.isEmpty else { return true }
                return user.email.localizedCaseInsensitiveContains(query) || user.displayName.localizedCaseInsensitiveContains(query)
            }
            .filter { user in
                guard let status, !status.isEmpty else { return true }
                return user.status.normalizedStatus == status.normalizedStatus || user.membershipStatus.normalizedStatus == status.normalizedStatus
            }
            .prefix(limit)
            .map { $0 }
    }

    func getUser(id: String) async throws -> AdminAccessUser {
        try await delay()
        guard let user = users.first(where: { $0.id == id }) else { throw AppError.notFound }
        return user
    }

    func createTemporaryUser(_ input: CreateTemporaryAdminUserInput) async throws -> AdminTemporaryUserResult {
        try await delay()
        let roleNames = roles.filter { input.roleIds.contains($0.id) }.map(\.name)
        let user = AdminAccessUser(
            id: "usr_\(UUID().uuidString.prefix(8))",
            email: input.email,
            displayName: input.displayName,
            phone: input.phone.isEmpty ? nil : input.phone,
            status: "active",
            membershipId: "mem_\(UUID().uuidString.prefix(8))",
            membershipStatus: "active",
            roleIds: input.roleIds,
            roleNames: roleNames,
            effectivePermissions: [],
            activeSessionCount: 0,
            invitedBy: "usr_owner",
            acceptedAt: nil,
            blockedAt: nil,
            blockedReason: nil,
            createdAt: "2026-05-21T12:00:00Z",
            updatedAt: "2026-05-21T12:00:00Z",
            version: 1
        )
        users.insert(user, at: 0)
        return AdminTemporaryUserResult(
            user: user,
            credentialId: "cred_demo",
            membershipId: user.membershipId,
            temporaryPassword: input.temporaryPassword.isEmpty ? "NexoTemp123!" : input.temporaryPassword,
            mustChangePassword: true,
            createdAt: user.createdAt
        )
    }

    func updateUser(id: String, input: UpdateAdminUserInput) async throws -> AdminAccessUser {
        try await delay()
        guard let index = users.firstIndex(where: { $0.id == id }) else { throw AppError.notFound }
        let roleNames = roles.filter { input.roleIds.contains($0.id) }.map(\.name)
        let current = users[index]
        let updated = AdminAccessUser(
            id: current.id,
            email: current.email,
            displayName: input.displayName,
            phone: input.clearPhone ? nil : input.phone,
            status: current.status,
            membershipId: current.membershipId,
            membershipStatus: current.membershipStatus,
            roleIds: input.roleIds,
            roleNames: roleNames,
            effectivePermissions: current.effectivePermissions,
            activeSessionCount: current.activeSessionCount,
            invitedBy: current.invitedBy,
            acceptedAt: current.acceptedAt,
            blockedAt: current.blockedAt,
            blockedReason: current.blockedReason,
            createdAt: current.createdAt,
            updatedAt: "2026-05-21T12:30:00Z",
            version: (current.version ?? 0) + 1
        )
        users[index] = updated
        return updated
    }

    func blockUser(id: String, reason: String) async throws -> AdminAccessUser {
        try await patchUser(id: id, status: "blocked", membershipStatus: "suspended", blockedReason: reason)
    }

    func unblockUser(id: String, reason: String) async throws -> AdminAccessUser {
        try await patchUser(id: id, status: "active", membershipStatus: "active", blockedReason: nil)
    }

    func resetPassword(userId: String, temporaryPassword: String?, revokeSessions: Bool, reason: String) async throws -> AdminResetPasswordResult {
        try await delay()
        return AdminResetPasswordResult(
            userId: userId,
            credentialId: "cred_demo",
            temporaryPassword: temporaryPassword?.isEmpty == false ? temporaryPassword! : "NexoReset123!",
            mustChangePassword: true,
            revokedSessions: revokeSessions ? 1 : 0,
            revokedRefreshTokens: revokeSessions ? 1 : 0,
            changedAt: "2026-05-21T13:00:00Z"
        )
    }

    func revokeSessions(userId: String, reason: String) async throws -> AdminUserSessionRevocationResult {
        try await delay()
        return AdminUserSessionRevocationResult(userId: userId, revokedSessions: 1, revokedRefreshTokens: 1, revokedAt: "2026-05-21T13:00:00Z", reason: reason)
    }

    func listUserSessions(userId: String) async throws -> [AdminUserSession] {
        try await delay()
        guard users.contains(where: { $0.id == userId }) else { throw AppError.notFound }
        return [
            AdminUserSession(
                id: "ses_admin_demo",
                userId: userId,
                status: "active",
                createdAt: "2026-06-24T10:00:00Z",
                expiresAt: "2026-07-24T10:00:00Z",
                lastSeenAt: "2026-06-24T10:48:00Z",
                revokedAt: nil,
                deviceId: "ios-admin-preview",
                appType: "admin_ios",
                appVersion: "0.14.0",
                appBuild: "debug",
                platform: "ios",
                userAgent: "Nexo Admin Preview",
                ipAddress: "127.0.0.1"
            )
        ]
    }

    func listInvitations(status: String?, limit: Int) async throws -> [AdminAccessInvitation] {
        try await delay()
        return invitations
            .filter { invitation in
                guard let status, !status.isEmpty else { return true }
                return invitation.status.normalizedStatus == status.normalizedStatus
            }
            .prefix(limit)
            .map { $0 }
    }

    func getInvitation(id: String) async throws -> AdminAccessInvitation {
        try await delay()
        guard let invitation = invitations.first(where: { $0.id == id }) else { throw AppError.notFound }
        return invitation
    }

    func createInvitation(_ input: CreateAdminInvitationInput) async throws -> AdminInvitationCreatedResult {
        try await delay()
        let roleNames = roles.filter { input.roleIds.contains($0.id) }.map(\.name)
        let invitation = AdminAccessInvitation(
            id: "inv_\(UUID().uuidString.prefix(8))",
            organizationId: "org_1",
            email: input.email,
            invitedByUserId: "usr_owner",
            roleIds: input.roleIds,
            roleNames: roleNames,
            status: "pending",
            createdAt: "2026-05-21T14:00:00Z",
            expiresAt: "2026-05-28T14:00:00Z",
            acceptedAt: nil,
            revokedAt: nil,
            acceptedUserId: nil,
            version: 1
        )
        invitations.insert(invitation, at: 0)
        let user = MockAdminAccessData.users[1]
        return AdminInvitationCreatedResult(invitation: invitation, user: user, membershipId: user.membershipId, rawInvitationToken: "invitation-token-demo", invitationUrl: "https://nexo.test/invitations/demo", createdAt: invitation.createdAt)
    }

    func resendInvitation(id: String, reason: String) async throws -> AdminInvitationResendResult {
        try await delay()
        guard let invitation = invitations.first(where: { $0.id == id }) else { throw AppError.notFound }
        return AdminInvitationResendResult(invitation: invitation, rawInvitationToken: "resent-token-demo", invitationUrl: "https://nexo.test/invitations/resent")
    }

    func revokeInvitation(id: String, reason: String) async throws -> AdminAccessInvitation {
        try await delay()
        guard let index = invitations.firstIndex(where: { $0.id == id }) else { throw AppError.notFound }
        let current = invitations[index]
        let revoked = AdminAccessInvitation(
            id: current.id,
            organizationId: current.organizationId,
            email: current.email,
            invitedByUserId: current.invitedByUserId,
            roleIds: current.roleIds,
            roleNames: current.roleNames,
            status: "revoked",
            createdAt: current.createdAt,
            expiresAt: current.expiresAt,
            acceptedAt: current.acceptedAt,
            revokedAt: "2026-05-21T15:00:00Z",
            acceptedUserId: current.acceptedUserId,
            version: current.version + 1
        )
        invitations[index] = revoked
        return revoked
    }

    func listCapabilityGroups() async throws -> [AdminHumanCapabilityGroup] {
        try await delay()
        return capabilityGroups
    }

    func listRoles(includeSystemTemplates: Bool) async throws -> [AdminAccessRole] {
        try await delay()
        return includeSystemTemplates ? roles : roles.filter { !$0.systemRole }
    }

    func getRole(id: String) async throws -> AdminAccessRole {
        try await delay()
        guard let role = roles.first(where: { $0.id == id }) else { throw AppError.notFound }
        return role
    }

    func createRole(_ input: CreateAdminRoleInput) async throws -> AdminAccessRole {
        try await delay()
        let role = AdminAccessRole(
            id: "role_\(UUID().uuidString.prefix(8))",
            code: input.code,
            organizationId: "org_1",
            scope: "organization",
            type: "custom",
            name: input.name,
            description: input.description,
            permissionKeys: input.permissionKeys,
            systemRole: false,
            critical: false,
            editable: true,
            status: "active",
            schemaVersion: 1
        )
        roles.append(role)
        return role
    }

    func updateRole(id: String, input: UpdateAdminRoleInput) async throws -> AdminAccessRole {
        try await delay()
        guard let index = roles.firstIndex(where: { $0.id == id }) else { throw AppError.notFound }
        let current = roles[index]
        let updated = AdminAccessRole(
            id: current.id,
            code: current.code,
            organizationId: current.organizationId,
            scope: current.scope,
            type: current.type,
            name: input.name,
            description: input.description,
            permissionKeys: input.permissionKeys,
            systemRole: current.systemRole,
            critical: current.critical,
            editable: current.editable,
            status: current.status,
            schemaVersion: current.schemaVersion + 1
        )
        roles[index] = updated
        return updated
    }

    func activateRole(id: String, reason: String) async throws -> AdminAccessRole {
        try await patchRole(id: id, status: "active")
    }

    func deactivateRole(id: String, reason: String) async throws -> AdminAccessRole {
        try await patchRole(id: id, status: "inactive")
    }

    func listPermissions(includeReserved: Bool) async throws -> [AdminAccessPermission] {
        try await delay()
        return includeReserved ? permissions : permissions.filter { $0.status.normalizedStatus == "active" }
    }

    private func patchUser(id: String, status: String, membershipStatus: String, blockedReason: String?) async throws -> AdminAccessUser {
        try await delay()
        guard let index = users.firstIndex(where: { $0.id == id }) else { throw AppError.notFound }
        let current = users[index]
        let updated = AdminAccessUser(
            id: current.id,
            email: current.email,
            displayName: current.displayName,
            phone: current.phone,
            status: status,
            membershipId: current.membershipId,
            membershipStatus: membershipStatus,
            roleIds: current.roleIds,
            roleNames: current.roleNames,
            effectivePermissions: current.effectivePermissions,
            activeSessionCount: blockedReason == nil ? current.activeSessionCount : 0,
            invitedBy: current.invitedBy,
            acceptedAt: current.acceptedAt,
            blockedAt: blockedReason == nil ? nil : "2026-05-21T14:00:00Z",
            blockedReason: blockedReason,
            createdAt: current.createdAt,
            updatedAt: "2026-05-21T14:00:00Z",
            version: (current.version ?? 0) + 1
        )
        users[index] = updated
        return updated
    }

    private func patchRole(id: String, status: String) async throws -> AdminAccessRole {
        try await delay()
        guard let index = roles.firstIndex(where: { $0.id == id }) else { throw AppError.notFound }
        let current = roles[index]
        let updated = AdminAccessRole(
            id: current.id,
            code: current.code,
            organizationId: current.organizationId,
            scope: current.scope,
            type: current.type,
            name: current.name,
            description: current.description,
            permissionKeys: current.permissionKeys,
            systemRole: current.systemRole,
            critical: current.critical,
            editable: current.editable,
            status: status,
            schemaVersion: current.schemaVersion + 1
        )
        roles[index] = updated
        return updated
    }

    private func delay() async throws {
        try await Task.sleep(nanoseconds: delayNanoseconds)
    }
}
