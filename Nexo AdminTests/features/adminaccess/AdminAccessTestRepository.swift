//
//  AdminAccessTestRepository.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import Foundation
@testable import Nexo_Admin

final class AdminAccessTestRepository: AdminAccessRepository, @unchecked Sendable {
    private var users: [AdminAccessUser] = [
        AdminAccessUser(
            id: "usr_owner",
            email: "owner@nexo.test",
            displayName: "Dueño Demo",
            phone: nil,
            status: "active",
            membershipId: "mem_owner",
            membershipStatus: "active",
            roleIds: ["role_owner"],
            roleNames: ["Propietario"],
            effectivePermissions: [PermissionCatalog.all],
            activeSessionCount: 1,
            invitedBy: nil,
            acceptedAt: nil,
            blockedAt: nil,
            blockedReason: nil,
            createdAt: "2026-05-21T00:00:00Z",
            updatedAt: "2026-05-21T00:00:00Z",
            version: 1
        ),
        AdminAccessUser(
            id: "usr_cashier",
            email: "cashier@nexo.test",
            displayName: "Cajero Demo",
            phone: nil,
            status: "active",
            membershipId: "mem_cashier",
            membershipStatus: "active",
            roleIds: ["role_cashier"],
            roleNames: ["Cajero"],
            effectivePermissions: [PermissionCatalog.salesView],
            activeSessionCount: 0,
            invitedBy: "usr_owner",
            acceptedAt: nil,
            blockedAt: nil,
            blockedReason: nil,
            createdAt: "2026-05-21T00:00:00Z",
            updatedAt: "2026-05-21T00:00:00Z",
            version: 1
        )
    ]
    
    private var roles: [AdminAccessRole] = [
        AdminAccessRole(
            id: "role_owner",
            code: "owner",
            organizationId: nil,
            scope: "organization",
            type: "system",
            name: "Propietario",
            description: "Acceso completo",
            permissionKeys: [PermissionCatalog.all],
            systemRole: true,
            critical: true,
            editable: false,
            status: "active",
            schemaVersion: 1
        ),
        AdminAccessRole(
            id: "role_cashier",
            code: "cashier",
            organizationId: "org_1",
            scope: "organization",
            type: "custom",
            name: "Cajero",
            description: "Cajero local",
            permissionKeys: [PermissionCatalog.salesView],
            systemRole: false,
            critical: false,
            editable: true,
            status: "active",
            schemaVersion: 1
        )
    ]
    
    private let permissions: [AdminAccessPermission] = [
        AdminAccessPermission(
            code: PermissionCatalog.credentialsUsersView,
            name: "Ver usuarios",
            description: "Lista usuarios",
            category: "credentials",
            scope: "organization",
            riskLevel: "medium",
            status: "active",
            systemManaged: true,
            requiresAudit: false,
            requiresReason: false,
            requiresStepUp: false,
            featureFlag: nil
        ),
        AdminAccessPermission(
            code: PermissionCatalog.credentialsRolesView,
            name: "Ver roles",
            description: "Lista roles",
            category: "credentials",
            scope: "organization",
            riskLevel: "medium",
            status: "active",
            systemManaged: true,
            requiresAudit: false,
            requiresReason: false,
            requiresStepUp: false,
            featureFlag: nil
        ),
        AdminAccessPermission(
            code: PermissionCatalog.credentialsRolesManage,
            name: "Gestionar roles",
            description: "Edita roles",
            category: "credentials",
            scope: "organization",
            riskLevel: "high",
            status: "active",
            systemManaged: true,
            requiresAudit: true,
            requiresReason: true,
            requiresStepUp: false,
            featureFlag: nil
        )
    ]
    
    func listUsers(query: String?, status: String?, limit: Int) async throws -> [AdminAccessUser] { users }
    func getUser(id: String) async throws -> AdminAccessUser { users.first { $0.id == id }! }
    
    func createTemporaryUser(_ input: CreateTemporaryAdminUserInput) async throws -> AdminTemporaryUserResult {
        let user = AdminAccessUser(
            id: "usr_new",
            email: input.email,
            displayName: input.displayName,
            phone: nil,
            status: "active",
            membershipId: "mem_new",
            membershipStatus: "active",
            roleIds: input.roleIds,
            roleNames: ["Cajero"],
            effectivePermissions: [],
            activeSessionCount: 0,
            invitedBy: nil,
            acceptedAt: nil,
            blockedAt: nil,
            blockedReason: nil,
            createdAt: "2026-05-21T00:00:00Z",
            updatedAt: "2026-05-21T00:00:00Z",
            version: 1
        )
        users.append(user)
        return AdminTemporaryUserResult(user: user, credentialId: "cred_new", membershipId: "mem_new", temporaryPassword: "Temp123!Demo", mustChangePassword: true, createdAt: user.createdAt)
    }
    
    func updateUser(id: String, input: UpdateAdminUserInput) async throws -> AdminAccessUser { users.first { $0.id == id }! }
    func blockUser(id: String, reason: String) async throws -> AdminAccessUser { users.first { $0.id == id }! }
    func unblockUser(id: String, reason: String) async throws -> AdminAccessUser { users.first { $0.id == id }! }
    func resetPassword(userId: String, temporaryPassword: String?, revokeSessions: Bool, reason: String) async throws -> AdminResetPasswordResult {
        AdminResetPasswordResult(userId: userId, credentialId: "cred", temporaryPassword: "Reset123!Demo", mustChangePassword: true, revokedSessions: 1, revokedRefreshTokens: 1, changedAt: "2026-05-21T00:00:00Z")
    }
    func revokeSessions(userId: String, reason: String) async throws -> AdminUserSessionRevocationResult {
        AdminUserSessionRevocationResult(userId: userId, revokedSessions: 1, revokedRefreshTokens: 1, revokedAt: "2026-05-21T00:00:00Z", reason: reason)
    }
    
    func listInvitations(status: String?, limit: Int) async throws -> [AdminAccessInvitation] { [] }
    func getInvitation(id: String) async throws -> AdminAccessInvitation { throw AppError.notFound }
    func createInvitation(_ input: CreateAdminInvitationInput) async throws -> AdminInvitationCreatedResult { throw AppError.validation("not implemented") }
    func resendInvitation(id: String, reason: String) async throws -> AdminInvitationResendResult { throw AppError.validation("not implemented") }
    func revokeInvitation(id: String, reason: String) async throws -> AdminAccessInvitation { throw AppError.validation("not implemented") }
    
    func listRoles(includeSystemTemplates: Bool) async throws -> [AdminAccessRole] { roles }
    func getRole(id: String) async throws -> AdminAccessRole { roles.first { $0.id == id }! }
    func createRole(_ input: CreateAdminRoleInput) async throws -> AdminAccessRole {
        let role = AdminAccessRole(id: "role_new", code: input.code, organizationId: "org_1", scope: "organization", type: "custom", name: input.name, description: input.description, permissionKeys: input.permissionKeys, systemRole: false, critical: false, editable: true, status: "active", schemaVersion: 1)
        roles.append(role)
        return role
    }
    func updateRole(id: String, input: UpdateAdminRoleInput) async throws -> AdminAccessRole { roles.first { $0.id == id }! }
    func activateRole(id: String, reason: String) async throws -> AdminAccessRole { roles.first { $0.id == id }! }
    func deactivateRole(id: String, reason: String) async throws -> AdminAccessRole { roles.first { $0.id == id }! }
    
    func listPermissions(includeReserved: Bool) async throws -> [AdminAccessPermission] { permissions }
}
