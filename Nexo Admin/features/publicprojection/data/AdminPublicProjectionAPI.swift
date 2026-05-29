//
//  AdminPublicProjectionAPI.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import Foundation

protocol AdminPublicProjectionAPI: Sendable {
    func getProjection() async throws -> AdminPublicProjectionResponseDTO
    func updateSettings(_ request: AdminPublicProjectionSettingsRequestDTO) async throws -> AdminPublicProjectionResponseDTO
    func publish(_ request: AdminPublicProjectionActionRequestDTO) async throws -> AdminPublicProjectionResponseDTO
    func hide(_ request: AdminPublicProjectionActionRequestDTO) async throws -> AdminPublicProjectionResponseDTO
    func suspend(_ request: AdminPublicProjectionActionRequestDTO) async throws -> AdminPublicProjectionResponseDTO
}

final class RemoteAdminPublicProjectionAPI: AdminPublicProjectionAPI, @unchecked Sendable {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func getProjection() async throws -> AdminPublicProjectionResponseDTO {
        try await apiClient.send(endpoint(path: "/api/v1/admin/public-projection", method: .get))
    }

    func updateSettings(_ request: AdminPublicProjectionSettingsRequestDTO) async throws -> AdminPublicProjectionResponseDTO {
        try await apiClient.send(endpoint(path: "/api/v1/admin/public-projection/settings", method: .put), body: request)
    }

    func publish(_ request: AdminPublicProjectionActionRequestDTO) async throws -> AdminPublicProjectionResponseDTO {
        try await apiClient.send(endpoint(path: "/api/v1/admin/public-projection/publish", method: .post), body: request)
    }

    func hide(_ request: AdminPublicProjectionActionRequestDTO) async throws -> AdminPublicProjectionResponseDTO {
        try await apiClient.send(endpoint(path: "/api/v1/admin/public-projection/hide", method: .post), body: request)
    }

    func suspend(_ request: AdminPublicProjectionActionRequestDTO) async throws -> AdminPublicProjectionResponseDTO {
        try await apiClient.send(endpoint(path: "/api/v1/admin/public-projection/suspend", method: .post), body: request)
    }

    private func endpoint(path: String, method: HTTPMethod) -> APIEndpoint {
        APIEndpoint(path: path, method: method, requiresAuth: true, requiresOrganization: true)
    }
}
