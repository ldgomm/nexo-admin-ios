//
//  AdminSupportAPI.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import Foundation

protocol AdminSupportAPI: Sendable {
    func getHealth() async throws -> AdminHealthResponseDTO
    func listDevices() async throws -> AdminDevicesResponseDTO
}

final class RemoteAdminSupportAPI: AdminSupportAPI, @unchecked Sendable {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func getHealth() async throws -> AdminHealthResponseDTO {
        try await apiClient.send(APIEndpoint(path: "/api/v1/admin/health", method: .get, requiresAuth: true, requiresOrganization: false))
    }

    func listDevices() async throws -> AdminDevicesResponseDTO {
        try await apiClient.send(APIEndpoint(path: "/api/v1/admin/devices", method: .get, requiresAuth: true, requiresOrganization: true))
    }
}
