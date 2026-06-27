//
//  AdminBusinessAPI.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import Foundation

protocol AdminBusinessAPI: Sendable {
    func getOverview() async throws -> AdminBusinessFoundationOverviewDTO
    func getBusiness() async throws -> AdminBusinessEnvelopeDTO
    func updateBusiness(_ request: UpdateAdminBusinessRequestDTO) async throws -> AdminBusinessEnvelopeDTO
    func getReadiness() async throws -> AdminBusinessReadinessResponseDTO
    func getRestaurantReadiness(branchId: String?) async throws -> AdminRestaurantReadinessResponseDTO

    func listActivities() async throws -> AdminActivitiesResponseDTO
    func createActivity(_ request: CreateAdminActivityRequestDTO) async throws -> AdminActivityEnvelopeDTO
    func updateActivity(id: String, request: UpdateAdminActivityRequestDTO) async throws -> AdminActivityEnvelopeDTO
    func activateActivity(id: String, request: AdminBusinessActionRequestDTO) async throws -> AdminActivityEnvelopeDTO
    func deactivateActivity(id: String, request: AdminBusinessActionRequestDTO) async throws -> AdminActivityEnvelopeDTO

    func listBranches() async throws -> AdminBranchesResponseDTO
    func createBranch(_ request: CreateAdminBranchRequestDTO) async throws -> AdminBranchEnvelopeDTO
    func updateBranch(id: String, request: UpdateAdminBranchRequestDTO) async throws -> AdminBranchEnvelopeDTO
    func activateBranch(id: String, request: AdminBusinessActionRequestDTO) async throws -> AdminBranchEnvelopeDTO
    func deactivateBranch(id: String, request: AdminBusinessActionRequestDTO) async throws -> AdminBranchEnvelopeDTO

    func listEmissionPoints() async throws -> AdminEmissionPointsResponseDTO
    func createEmissionPoint(_ request: CreateAdminEmissionPointRequestDTO) async throws -> AdminEmissionPointEnvelopeDTO
    func updateEmissionPoint(id: String, request: UpdateAdminEmissionPointRequestDTO) async throws -> AdminEmissionPointEnvelopeDTO
    func activateEmissionPoint(id: String, request: AdminBusinessActionRequestDTO) async throws -> AdminEmissionPointEnvelopeDTO
    func deactivateEmissionPoint(id: String, request: AdminBusinessActionRequestDTO) async throws -> AdminEmissionPointEnvelopeDTO
}

final class RemoteAdminBusinessAPI: AdminBusinessAPI, @unchecked Sendable {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func getOverview() async throws -> AdminBusinessFoundationOverviewDTO {
        try await apiClient.send(adminEndpoint(path: "/api/v1/admin/business/overview", method: .get))
    }

    func getBusiness() async throws -> AdminBusinessEnvelopeDTO {
        try await apiClient.send(adminEndpoint(path: "/api/v1/admin/business", method: .get))
    }

    func updateBusiness(_ request: UpdateAdminBusinessRequestDTO) async throws -> AdminBusinessEnvelopeDTO {
        try await apiClient.send(adminEndpoint(path: "/api/v1/admin/business", method: .put), body: request)
    }

    func getReadiness() async throws -> AdminBusinessReadinessResponseDTO {
        try await apiClient.send(adminEndpoint(path: "/api/v1/admin/business/readiness", method: .get))
    }

    func getRestaurantReadiness(branchId: String?) async throws -> AdminRestaurantReadinessResponseDTO {
        var queryItems: [URLQueryItem] = []
        if let branchId = branchId?.trimmedOrNil {
            queryItems.append(URLQueryItem(name: "branchId", value: branchId))
        }
        return try await apiClient.send(
            adminEndpoint(
                path: "/api/v1/admin/restaurant/readiness",
                method: .get,
                queryItems: queryItems
            )
        )
    }

    func listActivities() async throws -> AdminActivitiesResponseDTO {
        try await apiClient.send(adminEndpoint(path: "/api/v1/admin/activities", method: .get))
    }

    func createActivity(_ request: CreateAdminActivityRequestDTO) async throws -> AdminActivityEnvelopeDTO {
        try await apiClient.send(adminEndpoint(path: "/api/v1/admin/activities", method: .post), body: request)
    }

    func updateActivity(id: String, request: UpdateAdminActivityRequestDTO) async throws -> AdminActivityEnvelopeDTO {
        try await apiClient.send(adminEndpoint(path: "/api/v1/admin/activities/\(id)", method: .put), body: request)
    }

    func activateActivity(id: String, request: AdminBusinessActionRequestDTO) async throws -> AdminActivityEnvelopeDTO {
        try await apiClient.send(adminEndpoint(path: "/api/v1/admin/activities/\(id)/activate", method: .post), body: request)
    }

    func deactivateActivity(id: String, request: AdminBusinessActionRequestDTO) async throws -> AdminActivityEnvelopeDTO {
        try await apiClient.send(adminEndpoint(path: "/api/v1/admin/activities/\(id)/deactivate", method: .post), body: request)
    }

    func listBranches() async throws -> AdminBranchesResponseDTO {
        try await apiClient.send(adminEndpoint(path: "/api/v1/admin/branches", method: .get))
    }

    func createBranch(_ request: CreateAdminBranchRequestDTO) async throws -> AdminBranchEnvelopeDTO {
        try await apiClient.send(adminEndpoint(path: "/api/v1/admin/branches", method: .post), body: request)
    }

    func updateBranch(id: String, request: UpdateAdminBranchRequestDTO) async throws -> AdminBranchEnvelopeDTO {
        try await apiClient.send(adminEndpoint(path: "/api/v1/admin/branches/\(id)", method: .put), body: request)
    }

    func activateBranch(id: String, request: AdminBusinessActionRequestDTO) async throws -> AdminBranchEnvelopeDTO {
        try await apiClient.send(adminEndpoint(path: "/api/v1/admin/branches/\(id)/activate", method: .post), body: request)
    }

    func deactivateBranch(id: String, request: AdminBusinessActionRequestDTO) async throws -> AdminBranchEnvelopeDTO {
        try await apiClient.send(adminEndpoint(path: "/api/v1/admin/branches/\(id)/deactivate", method: .post), body: request)
    }

    func listEmissionPoints() async throws -> AdminEmissionPointsResponseDTO {
        try await apiClient.send(adminEndpoint(path: "/api/v1/admin/emission-points", method: .get))
    }

    func createEmissionPoint(_ request: CreateAdminEmissionPointRequestDTO) async throws -> AdminEmissionPointEnvelopeDTO {
        try await apiClient.send(adminEndpoint(path: "/api/v1/admin/emission-points", method: .post), body: request)
    }

    func updateEmissionPoint(id: String, request: UpdateAdminEmissionPointRequestDTO) async throws -> AdminEmissionPointEnvelopeDTO {
        try await apiClient.send(adminEndpoint(path: "/api/v1/admin/emission-points/\(id)", method: .put), body: request)
    }

    func activateEmissionPoint(id: String, request: AdminBusinessActionRequestDTO) async throws -> AdminEmissionPointEnvelopeDTO {
        try await apiClient.send(adminEndpoint(path: "/api/v1/admin/emission-points/\(id)/activate", method: .post), body: request)
    }

    func deactivateEmissionPoint(id: String, request: AdminBusinessActionRequestDTO) async throws -> AdminEmissionPointEnvelopeDTO {
        try await apiClient.send(adminEndpoint(path: "/api/v1/admin/emission-points/\(id)/deactivate", method: .post), body: request)
    }

    private func adminEndpoint(path: String, method: HTTPMethod, queryItems: [URLQueryItem] = []) -> APIEndpoint {
        APIEndpoint(path: path, method: method, queryItems: queryItems, requiresAuth: true, requiresOrganization: true)
    }
}
