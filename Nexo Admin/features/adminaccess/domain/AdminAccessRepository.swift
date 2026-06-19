//
//  AdminAccessRepository.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import Foundation

protocol AdminAccessRepository: Sendable {
    func listUsers(query: String?, status: String?, limit: Int) async throws -> [AdminAccessUser]
    func getUser(id: String) async throws -> AdminAccessUser
    func createTemporaryUser(_ input: CreateTemporaryAdminUserInput) async throws -> AdminTemporaryUserResult
    func updateUser(id: String, input: UpdateAdminUserInput) async throws -> AdminAccessUser
    func blockUser(id: String, reason: String) async throws -> AdminAccessUser
    func unblockUser(id: String, reason: String) async throws -> AdminAccessUser
    func resetPassword(userId: String, temporaryPassword: String?, revokeSessions: Bool, reason: String) async throws -> AdminResetPasswordResult
    func revokeSessions(userId: String, reason: String) async throws -> AdminUserSessionRevocationResult

    func listInvitations(status: String?, limit: Int) async throws -> [AdminAccessInvitation]
    func getInvitation(id: String) async throws -> AdminAccessInvitation
    func createInvitation(_ input: CreateAdminInvitationInput) async throws -> AdminInvitationCreatedResult
    func resendInvitation(id: String, reason: String) async throws -> AdminInvitationResendResult
    func revokeInvitation(id: String, reason: String) async throws -> AdminAccessInvitation

    func listCapabilityGroups() async throws -> [AdminHumanCapabilityGroup]
    func listRoles(includeSystemTemplates: Bool) async throws -> [AdminAccessRole]
    func getRole(id: String) async throws -> AdminAccessRole
    func createRole(_ input: CreateAdminRoleInput) async throws -> AdminAccessRole
    func updateRole(id: String, input: UpdateAdminRoleInput) async throws -> AdminAccessRole
    func activateRole(id: String, reason: String) async throws -> AdminAccessRole
    func deactivateRole(id: String, reason: String) async throws -> AdminAccessRole

    func listPermissions(includeReserved: Bool) async throws -> [AdminAccessPermission]
}
