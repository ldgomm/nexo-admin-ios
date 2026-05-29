//
//  AdminFoundationAPI.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import Foundation

protocol AdminFoundationAPI: Sendable {
    func getBusinessContext(branchId: String?) async throws -> BusinessContextResponseDTO
    func listModules() async throws -> ModulesResponseDTO
    func getModuleReadiness() async throws -> ModuleReadinessResponseDTO
    func enableModule(code: String, reason: String) async throws -> ModulesResponseDTO
    func disableModule(code: String, reason: String) async throws -> ModulesResponseDTO
}

final class RemoteAdminFoundationAPI: AdminFoundationAPI, @unchecked Sendable {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func getBusinessContext(branchId: String?) async throws -> BusinessContextResponseDTO {
        try await apiClient.send(
            APIEndpoint(
                path: "/api/v1/business/context",
                method: .get,
                requiresAuth: true,
                requiresOrganization: true,
                branchId: branchId
            )
        )
    }

    func listModules() async throws -> ModulesResponseDTO {
        try await apiClient.send(adminEndpoint(path: "/api/v1/admin/modules", method: .get))
    }

    func getModuleReadiness() async throws -> ModuleReadinessResponseDTO {
        try await apiClient.send(adminEndpoint(path: "/api/v1/admin/modules/readiness", method: .get))
    }

    func enableModule(code: String, reason: String) async throws -> ModulesResponseDTO {
        try await apiClient.send(
            adminEndpoint(path: "/api/v1/admin/modules/\(encoded(code))/enable", method: .put),
            body: ModuleToggleRequestDTO(reason: reason)
        )
    }

    func disableModule(code: String, reason: String) async throws -> ModulesResponseDTO {
        try await apiClient.send(
            adminEndpoint(path: "/api/v1/admin/modules/\(encoded(code))/disable", method: .put),
            body: ModuleToggleRequestDTO(reason: reason)
        )
    }

    private func adminEndpoint(path: String, method: HTTPMethod) -> APIEndpoint {
        APIEndpoint(path: path, method: method, requiresAuth: true, requiresOrganization: true)
    }

    private func encoded(_ value: String) -> String {
        value.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? value
    }
}
