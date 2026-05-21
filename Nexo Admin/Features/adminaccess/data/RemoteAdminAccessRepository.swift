//
//  RemoteAdminAccessRepository.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import Foundation

final class RemoteAdminAccessRepository: AdminAccessRepository, @unchecked Sendable {
    private let api: AdminAccessAPI

    init(api: AdminAccessAPI) {
        self.api = api
    }

    func listUsers(query: String?, status: String?, limit: Int) async throws -> [AdminAccessUser] {
        try await api.listUsers(query: query, status: status, limit: limit).users.map { $0.toDomain() }
    }

    func getUser(id: String) async throws -> AdminAccessUser {
        try await api.getUser(id: id).toDomain()
    }

    func createTemporaryUser(_ input: CreateTemporaryAdminUserInput) async throws -> AdminTemporaryUserResult {
        try await api.createTemporaryUser(input.toRequest()).toDomain()
    }

    func updateUser(id: String, input: UpdateAdminUserInput) async throws -> AdminAccessUser {
        try await api.updateUser(id: id, request: input.toRequest()).toDomain()
    }

    func blockUser(id: String, reason: String) async throws -> AdminAccessUser {
        try await api.blockUser(id: id, request: AdminUserActionRequestDTO(reason: reason)).toDomain()
    }

    func unblockUser(id: String, reason: String) async throws -> AdminAccessUser {
        try await api.unblockUser(id: id, request: AdminUserActionRequestDTO(reason: reason)).toDomain()
    }

    func resetPassword(userId: String, temporaryPassword: String?, revokeSessions: Bool, reason: String) async throws -> AdminResetPasswordResult {
        try await api.resetPassword(
            userId: userId,
            request: AdminResetUserPasswordRequestDTO(
                temporaryPassword: temporaryPassword,
                revokeSessions: revokeSessions,
                reason: reason
            )
        ).toDomain()
    }

    func revokeSessions(userId: String, reason: String) async throws -> AdminUserSessionRevocationResult {
        try await api.revokeSessions(userId: userId, request: AdminUserActionRequestDTO(reason: reason)).toDomain()
    }

    func listInvitations(status: String?, limit: Int) async throws -> [AdminAccessInvitation] {
        try await api.listInvitations(status: status, limit: limit).invitations.map { $0.toDomain() }
    }

    func getInvitation(id: String) async throws -> AdminAccessInvitation {
        try await api.getInvitation(id: id).toDomain()
    }

    func createInvitation(_ input: CreateAdminInvitationInput) async throws -> AdminInvitationCreatedResult {
        try await api.createInvitation(input.toRequest()).toDomain()
    }

    func resendInvitation(id: String, reason: String) async throws -> AdminInvitationResendResult {
        try await api.resendInvitation(id: id, request: AdminInvitationActionRequestDTO(reason: reason)).toDomain()
    }

    func revokeInvitation(id: String, reason: String) async throws -> AdminAccessInvitation {
        try await api.revokeInvitation(id: id, request: AdminInvitationActionRequestDTO(reason: reason)).toDomain()
    }

    func listRoles(includeSystemTemplates: Bool) async throws -> [AdminAccessRole] {
        try await api.listRoles(includeSystemTemplates: includeSystemTemplates).roles.map { $0.toDomain() }
    }

    func getRole(id: String) async throws -> AdminAccessRole {
        try await api.getRole(id: id).toDomain()
    }

    func createRole(_ input: CreateAdminRoleInput) async throws -> AdminAccessRole {
        try await api.createRole(input.toRequest()).toDomain()
    }

    func updateRole(id: String, input: UpdateAdminRoleInput) async throws -> AdminAccessRole {
        try await api.updateRole(id: id, request: input.toRequest()).toDomain()
    }

    func activateRole(id: String, reason: String) async throws -> AdminAccessRole {
        try await api.activateRole(id: id, request: AdminRoleActionRequestDTO(reason: reason)).toDomain()
    }

    func deactivateRole(id: String, reason: String) async throws -> AdminAccessRole {
        try await api.deactivateRole(id: id, request: AdminRoleActionRequestDTO(reason: reason)).toDomain()
    }

    func listPermissions(includeReserved: Bool) async throws -> [AdminAccessPermission] {
        try await api.listPermissions(includeReserved: includeReserved).permissions.map { $0.toDomain() }
    }
}
