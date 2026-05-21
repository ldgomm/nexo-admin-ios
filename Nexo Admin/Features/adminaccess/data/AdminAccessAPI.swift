//
//  AdminAccessAPI.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import Foundation

protocol AdminAccessAPI: Sendable {
    func listUsers(query: String?, status: String?, limit: Int) async throws -> AdminUsersResponseDTO
    func getUser(id: String) async throws -> AdminAccessUserDTO
    func createTemporaryUser(_ request: CreateTemporaryAdminUserRequestDTO) async throws -> AdminTemporaryUserResponseDTO
    func updateUser(id: String, request: UpdateAdminUserRequestDTO) async throws -> AdminAccessUserDTO
    func blockUser(id: String, request: AdminUserActionRequestDTO) async throws -> AdminAccessUserDTO
    func unblockUser(id: String, request: AdminUserActionRequestDTO) async throws -> AdminAccessUserDTO
    func resetPassword(userId: String, request: AdminResetUserPasswordRequestDTO) async throws -> AdminResetUserPasswordResponseDTO
    func revokeSessions(userId: String, request: AdminUserActionRequestDTO) async throws -> AdminUserSessionRevocationResponseDTO

    func listInvitations(status: String?, limit: Int) async throws -> AdminInvitationsResponseDTO
    func getInvitation(id: String) async throws -> AdminInvitationDTO
    func createInvitation(_ request: CreateAdminInvitationRequestDTO) async throws -> AdminInvitationCreatedResponseDTO
    func resendInvitation(id: String, request: AdminInvitationActionRequestDTO) async throws -> AdminInvitationResendResponseDTO
    func revokeInvitation(id: String, request: AdminInvitationActionRequestDTO) async throws -> AdminInvitationDTO

    func listRoles(includeSystemTemplates: Bool) async throws -> AdminRolesResponseDTO
    func getRole(id: String) async throws -> AdminRoleDTO
    func createRole(_ request: CreateAdminRoleRequestDTO) async throws -> AdminRoleDTO
    func updateRole(id: String, request: UpdateAdminRoleRequestDTO) async throws -> AdminRoleDTO
    func activateRole(id: String, request: AdminRoleActionRequestDTO) async throws -> AdminRoleDTO
    func deactivateRole(id: String, request: AdminRoleActionRequestDTO) async throws -> AdminRoleDTO

    func listPermissions(includeReserved: Bool) async throws -> AdminPermissionsResponseDTO
}

final class RemoteAdminAccessAPI: AdminAccessAPI, @unchecked Sendable {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func listUsers(query: String?, status: String?, limit: Int) async throws -> AdminUsersResponseDTO {
        var items = [URLQueryItem(name: "limit", value: "\(limit)")]
        if let query = query?.nilIfBlank { items.append(URLQueryItem(name: "q", value: query)) }
        if let status = status?.nilIfBlank { items.append(URLQueryItem(name: "status", value: status)) }
        return try await apiClient.send(adminEndpoint(path: "/api/v1/admin/users", method: .get, queryItems: items))
    }

    func getUser(id: String) async throws -> AdminAccessUserDTO {
        try await apiClient.send(adminEndpoint(path: "/api/v1/admin/users/\(id)", method: .get))
    }

    func createTemporaryUser(_ request: CreateTemporaryAdminUserRequestDTO) async throws -> AdminTemporaryUserResponseDTO {
        try await apiClient.send(adminEndpoint(path: "/api/v1/admin/users/temporary", method: .post), body: request)
    }

    func updateUser(id: String, request: UpdateAdminUserRequestDTO) async throws -> AdminAccessUserDTO {
        try await apiClient.send(adminEndpoint(path: "/api/v1/admin/users/\(id)", method: .put), body: request)
    }

    func blockUser(id: String, request: AdminUserActionRequestDTO) async throws -> AdminAccessUserDTO {
        try await apiClient.send(adminEndpoint(path: "/api/v1/admin/users/\(id)/block", method: .post), body: request)
    }

    func unblockUser(id: String, request: AdminUserActionRequestDTO) async throws -> AdminAccessUserDTO {
        try await apiClient.send(adminEndpoint(path: "/api/v1/admin/users/\(id)/unblock", method: .post), body: request)
    }

    func resetPassword(userId: String, request: AdminResetUserPasswordRequestDTO) async throws -> AdminResetUserPasswordResponseDTO {
        try await apiClient.send(adminEndpoint(path: "/api/v1/admin/users/\(userId)/reset-password", method: .post), body: request)
    }

    func revokeSessions(userId: String, request: AdminUserActionRequestDTO) async throws -> AdminUserSessionRevocationResponseDTO {
        try await apiClient.send(adminEndpoint(path: "/api/v1/admin/users/\(userId)/revoke-sessions", method: .post), body: request)
    }

    func listInvitations(status: String?, limit: Int) async throws -> AdminInvitationsResponseDTO {
        var items = [URLQueryItem(name: "limit", value: "\(limit)")]
        if let status = status?.nilIfBlank { items.append(URLQueryItem(name: "status", value: status)) }
        return try await apiClient.send(adminEndpoint(path: "/api/v1/admin/invitations", method: .get, queryItems: items))
    }

    func getInvitation(id: String) async throws -> AdminInvitationDTO {
        try await apiClient.send(adminEndpoint(path: "/api/v1/admin/invitations/\(id)", method: .get))
    }

    func createInvitation(_ request: CreateAdminInvitationRequestDTO) async throws -> AdminInvitationCreatedResponseDTO {
        try await apiClient.send(adminEndpoint(path: "/api/v1/admin/invitations", method: .post), body: request)
    }

    func resendInvitation(id: String, request: AdminInvitationActionRequestDTO) async throws -> AdminInvitationResendResponseDTO {
        try await apiClient.send(adminEndpoint(path: "/api/v1/admin/invitations/\(id)/resend", method: .post), body: request)
    }

    func revokeInvitation(id: String, request: AdminInvitationActionRequestDTO) async throws -> AdminInvitationDTO {
        try await apiClient.send(adminEndpoint(path: "/api/v1/admin/invitations/\(id)/revoke", method: .post), body: request)
    }

    func listRoles(includeSystemTemplates: Bool) async throws -> AdminRolesResponseDTO {
        try await apiClient.send(
            adminEndpoint(
                path: "/api/v1/admin/roles",
                method: .get,
                queryItems: [URLQueryItem(name: "includeSystemTemplates", value: includeSystemTemplates ? "true" : "false")]
            )
        )
    }

    func getRole(id: String) async throws -> AdminRoleDTO {
        try await apiClient.send(adminEndpoint(path: "/api/v1/admin/roles/\(id)", method: .get))
    }

    func createRole(_ request: CreateAdminRoleRequestDTO) async throws -> AdminRoleDTO {
        try await apiClient.send(adminEndpoint(path: "/api/v1/admin/roles", method: .post), body: request)
    }

    func updateRole(id: String, request: UpdateAdminRoleRequestDTO) async throws -> AdminRoleDTO {
        try await apiClient.send(adminEndpoint(path: "/api/v1/admin/roles/\(id)", method: .put), body: request)
    }

    func activateRole(id: String, request: AdminRoleActionRequestDTO) async throws -> AdminRoleDTO {
        try await apiClient.send(adminEndpoint(path: "/api/v1/admin/roles/\(id)/activate", method: .post), body: request)
    }

    func deactivateRole(id: String, request: AdminRoleActionRequestDTO) async throws -> AdminRoleDTO {
        try await apiClient.send(adminEndpoint(path: "/api/v1/admin/roles/\(id)/deactivate", method: .post), body: request)
    }

    func listPermissions(includeReserved: Bool) async throws -> AdminPermissionsResponseDTO {
        try await apiClient.send(
            adminEndpoint(
                path: "/api/v1/admin/permissions",
                method: .get,
                queryItems: [URLQueryItem(name: "includeReserved", value: includeReserved ? "true" : "false")]
            )
        )
    }

    private func adminEndpoint(path: String, method: HTTPMethod, queryItems: [URLQueryItem] = []) -> APIEndpoint {
        APIEndpoint(path: path, method: method, queryItems: queryItems, requiresAuth: true, requiresOrganization: true)
    }
}
