//
//  AdminVerticalsAPI.swift
//  Nexo Admin
//
//  Created by Nexo on 26/6/26.
//

import Foundation

protocol AdminVerticalsAPI: Sendable {
    func listPackages() async throws -> AdminVerticalPackagesResponseDTO
    func listActivations() async throws -> AdminVerticalActivationsResponseDTO
    func activate(verticalCode: String, request: AdminVerticalActivateRequestDTO) async throws -> AdminVerticalActivationDTO
    func deactivate(verticalCode: String, request: AdminVerticalDeactivateRequestDTO) async throws -> AdminVerticalActivationDTO
    func readiness(verticalCode: String) async throws -> AdminVerticalReadinessResponseDTO
}

final class RemoteAdminVerticalsAPI: AdminVerticalsAPI, @unchecked Sendable {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func listPackages() async throws -> AdminVerticalPackagesResponseDTO {
        try await apiClient.send(adminEndpoint(path: "/api/v1/admin/verticals/packages", method: .get))
    }

    func listActivations() async throws -> AdminVerticalActivationsResponseDTO {
        try await apiClient.send(adminEndpoint(path: "/api/v1/admin/verticals/activations", method: .get))
    }

    func activate(verticalCode: String, request: AdminVerticalActivateRequestDTO) async throws -> AdminVerticalActivationDTO {
        try await apiClient.send(
            adminEndpoint(path: "/api/v1/admin/verticals/\(encoded(verticalCode))/activate", method: .put),
            body: request
        )
    }

    func deactivate(verticalCode: String, request: AdminVerticalDeactivateRequestDTO) async throws -> AdminVerticalActivationDTO {
        try await apiClient.send(
            adminEndpoint(path: "/api/v1/admin/verticals/\(encoded(verticalCode))/deactivate", method: .put),
            body: request
        )
    }

    func readiness(verticalCode: String) async throws -> AdminVerticalReadinessResponseDTO {
        try await apiClient.send(adminEndpoint(path: "/api/v1/admin/verticals/\(encoded(verticalCode))/readiness", method: .get))
    }

    private func adminEndpoint(path: String, method: HTTPMethod) -> APIEndpoint {
        APIEndpoint(path: path, method: method, requiresAuth: true, requiresOrganization: true)
    }

    private func encoded(_ value: String) -> String {
        value.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? value
    }
}
