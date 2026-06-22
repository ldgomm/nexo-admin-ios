//
//  RemoteAdminBusinessPackagesRepository.swift
//  Nexo Admin
//
//  Created by Nexo on 22/6/26.
//

import Foundation

final class RemoteAdminBusinessPackagesRepository: AdminBusinessPackagesRepository, @unchecked Sendable {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func loadBusinessPackages() async throws -> AdminBusinessPackageCatalogResponse {
        let response: AdminBusinessPackageCatalogResponseDTO = try await apiClient.send(
            APIEndpoint(
                path: "/api/v1/admin/business/packages",
                method: .get,
                requiresAuth: true,
                requiresOrganization: true
            )
        )
        return response.toDomain()
    }
}
