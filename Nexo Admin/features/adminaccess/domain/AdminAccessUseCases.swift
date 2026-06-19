//
//  AdminAccessUseCases.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import Foundation

struct ListAdminUsersUseCase: Sendable {
    let repository: any AdminAccessRepository

    func execute(query: String? = nil, status: String? = nil, limit: Int = 100) async throws -> [AdminAccessUser] {
        try await repository.listUsers(query: query?.nilIfBlank, status: status?.nilIfBlank, limit: limit)
    }
}

struct GetAdminUserUseCase: Sendable {
    let repository: any AdminAccessRepository

    func execute(id: String) async throws -> AdminAccessUser {
        try await repository.getUser(id: id)
    }
}

struct MutateAdminUserUseCase: Sendable {
    let repository: any AdminAccessRepository

    func createTemporary(_ input: CreateTemporaryAdminUserInput) async throws -> AdminTemporaryUserResult {
        try await repository.createTemporaryUser(input)
    }

    func update(id: String, input: UpdateAdminUserInput) async throws -> AdminAccessUser {
        try await repository.updateUser(id: id, input: input)
    }

    func block(id: String, reason: String) async throws -> AdminAccessUser {
        try await repository.blockUser(id: id, reason: reason)
    }

    func unblock(id: String, reason: String) async throws -> AdminAccessUser {
        try await repository.unblockUser(id: id, reason: reason)
    }

    func resetPassword(userId: String, temporaryPassword: String?, revokeSessions: Bool, reason: String) async throws -> AdminResetPasswordResult {
        try await repository.resetPassword(userId: userId, temporaryPassword: temporaryPassword?.nilIfBlank, revokeSessions: revokeSessions, reason: reason)
    }

    func revokeSessions(userId: String, reason: String) async throws -> AdminUserSessionRevocationResult {
        try await repository.revokeSessions(userId: userId, reason: reason)
    }
}

struct ListAdminCapabilityGroupsUseCase: Sendable {
    let repository: any AdminAccessRepository

    func execute() async throws -> [AdminHumanCapabilityGroup] {
        try await repository.listCapabilityGroups()
    }
}

struct ListAdminRolesUseCase: Sendable {
    let repository: any AdminAccessRepository

    func execute(includeSystemTemplates: Bool = true) async throws -> [AdminAccessRole] {
        try await repository.listRoles(includeSystemTemplates: includeSystemTemplates)
    }
}

struct GetAdminRoleUseCase: Sendable {
    let repository: any AdminAccessRepository

    func execute(id: String) async throws -> AdminAccessRole {
        try await repository.getRole(id: id)
    }
}

struct MutateAdminRoleUseCase: Sendable {
    let repository: any AdminAccessRepository

    func create(_ input: CreateAdminRoleInput) async throws -> AdminAccessRole {
        try await repository.createRole(input)
    }

    func update(id: String, input: UpdateAdminRoleInput) async throws -> AdminAccessRole {
        try await repository.updateRole(id: id, input: input)
    }

    func activate(id: String, reason: String) async throws -> AdminAccessRole {
        try await repository.activateRole(id: id, reason: reason)
    }

    func deactivate(id: String, reason: String) async throws -> AdminAccessRole {
        try await repository.deactivateRole(id: id, reason: reason)
    }
}

struct ListAdminPermissionsUseCase: Sendable {
    let repository: any AdminAccessRepository

    func execute(includeReserved: Bool = false) async throws -> [AdminAccessPermission] {
        try await repository.listPermissions(includeReserved: includeReserved)
    }
}

struct ListAdminInvitationsUseCase: Sendable {
    let repository: any AdminAccessRepository

    func execute(status: String? = nil, limit: Int = 100) async throws -> [AdminAccessInvitation] {
        try await repository.listInvitations(status: status?.nilIfBlank, limit: limit)
    }
}

struct MutateAdminInvitationUseCase: Sendable {
    let repository: any AdminAccessRepository

    func create(_ input: CreateAdminInvitationInput) async throws -> AdminInvitationCreatedResult {
        try await repository.createInvitation(input)
    }

    func resend(id: String, reason: String) async throws -> AdminInvitationResendResult {
        try await repository.resendInvitation(id: id, reason: reason)
    }

    func revoke(id: String, reason: String) async throws -> AdminAccessInvitation {
        try await repository.revokeInvitation(id: id, reason: reason)
    }
}
