//
//  AdminTaxSriAPI.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import Foundation

protocol AdminTaxSriAPI: Sendable {
    func getTaxSettings() async throws -> AdminTaxSettingsResponseDTO
    func updateTaxSettings(_ request: UpdateAdminTaxSettingsRequestDTO) async throws -> AdminTaxSettingsResponseDTO
    func listTaxProfiles() async throws -> AdminTaxProfilesResponseDTO
    func getTaxProfile(id: String) async throws -> AdminTaxProfileEnvelopeDTO
    func listSignatures() async throws -> AdminElectronicSignaturesResponseDTO
    func uploadSignature(_ request: UploadAdminElectronicSignatureRequestDTO) async throws -> AdminElectronicSignatureEnvelopeDTO
    func validateSignature(id: String, request: AdminSignatureActionRequestDTO) async throws -> AdminElectronicSignatureEnvelopeDTO
    func activateSignature(id: String, request: AdminSignatureActionRequestDTO) async throws -> AdminElectronicSignatureEnvelopeDTO
    func revokeSignature(id: String, request: AdminSignatureActionRequestDTO) async throws -> AdminElectronicSignatureEnvelopeDTO
    func getSriSettings() async throws -> AdminSriSettingsResponseDTO
    func updateSriSettings(_ request: UpdateAdminSriSettingsRequestDTO) async throws -> AdminSriSettingsResponseDTO
    func getReadiness() async throws -> AdminSriReadinessResponseDTO
    func runReadiness() async throws -> AdminSriReadinessResponseDTO
    func startHomologation(_ request: AdminReasonRequestDTO) async throws -> AdminSriHomologationRunEnvelopeDTO
    func listHomologationRuns(limit: Int) async throws -> AdminSriHomologationRunsResponseDTO
    func requestProductionEnable(_ request: RequestProductionEnableRequestDTO) async throws -> AdminSriSettingsResponseDTO
}

final class RemoteAdminTaxSriAPI: AdminTaxSriAPI, @unchecked Sendable {
    private let apiClient: APIClient

    init(apiClient: APIClient) { self.apiClient = apiClient }

    func getTaxSettings() async throws -> AdminTaxSettingsResponseDTO {
        try await apiClient.send(endpoint("/api/v1/admin/tax/settings", .get))
    }

    func updateTaxSettings(_ request: UpdateAdminTaxSettingsRequestDTO) async throws -> AdminTaxSettingsResponseDTO {
        try await apiClient.send(endpoint("/api/v1/admin/tax/settings", .put), body: request)
    }

    func listTaxProfiles() async throws -> AdminTaxProfilesResponseDTO {
        try await apiClient.send(endpoint("/api/v1/admin/tax/profiles", .get))
    }

    func getTaxProfile(id: String) async throws -> AdminTaxProfileEnvelopeDTO {
        try await apiClient.send(endpoint("/api/v1/admin/tax/profiles/\(id)", .get))
    }

    func listSignatures() async throws -> AdminElectronicSignaturesResponseDTO {
        try await apiClient.send(endpoint("/api/v1/admin/electronic-signatures", .get))
    }

    func uploadSignature(_ request: UploadAdminElectronicSignatureRequestDTO) async throws -> AdminElectronicSignatureEnvelopeDTO {
        try await apiClient.send(endpoint("/api/v1/admin/electronic-signatures", .post), body: request)
    }

    func validateSignature(id: String, request: AdminSignatureActionRequestDTO) async throws -> AdminElectronicSignatureEnvelopeDTO {
        try await apiClient.send(endpoint("/api/v1/admin/electronic-signatures/\(id)/validate", .post), body: request)
    }

    func activateSignature(id: String, request: AdminSignatureActionRequestDTO) async throws -> AdminElectronicSignatureEnvelopeDTO {
        try await apiClient.send(endpoint("/api/v1/admin/electronic-signatures/\(id)/activate", .post), body: request)
    }

    func revokeSignature(id: String, request: AdminSignatureActionRequestDTO) async throws -> AdminElectronicSignatureEnvelopeDTO {
        try await apiClient.send(endpoint("/api/v1/admin/electronic-signatures/\(id)/revoke", .post), body: request)
    }

    func getSriSettings() async throws -> AdminSriSettingsResponseDTO {
        try await apiClient.send(endpoint("/api/v1/admin/sri/settings", .get))
    }

    func updateSriSettings(_ request: UpdateAdminSriSettingsRequestDTO) async throws -> AdminSriSettingsResponseDTO {
        try await apiClient.send(endpoint("/api/v1/admin/sri/settings", .put), body: request)
    }

    func getReadiness() async throws -> AdminSriReadinessResponseDTO {
        try await apiClient.send(endpoint("/api/v1/admin/sri/readiness", .get))
    }

    func runReadiness() async throws -> AdminSriReadinessResponseDTO {
        try await apiClient.send(endpoint("/api/v1/admin/sri/readiness/run", .post), body: EmptyRequestBody())
    }

    func startHomologation(_ request: AdminReasonRequestDTO) async throws -> AdminSriHomologationRunEnvelopeDTO {
        try await apiClient.send(endpoint("/api/v1/admin/sri/homologation-runs", .post), body: request)
    }

    func listHomologationRuns(limit: Int) async throws -> AdminSriHomologationRunsResponseDTO {
        try await apiClient.send(APIEndpoint(path: "/api/v1/admin/sri/homologation-runs", method: .get, queryItems: [URLQueryItem(name: "limit", value: "\(limit)")], requiresAuth: true, requiresOrganization: true))
    }

    func requestProductionEnable(_ request: RequestProductionEnableRequestDTO) async throws -> AdminSriSettingsResponseDTO {
        try await apiClient.send(endpoint("/api/v1/admin/sri/production/enable-request", .post), body: request)
    }

    private func endpoint(_ path: String, _ method: HTTPMethod) -> APIEndpoint {
        APIEndpoint(path: path, method: method, requiresAuth: true, requiresOrganization: true)
    }
}
