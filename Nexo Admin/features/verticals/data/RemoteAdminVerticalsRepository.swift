//
//  RemoteAdminVerticalsRepository.swift
//  Nexo Admin
//
//  Created by Nexo on 26/6/26.
//

import Foundation

final class RemoteAdminVerticalsRepository: AdminVerticalsRepository, @unchecked Sendable {
    private let api: AdminVerticalsAPI

    init(api: AdminVerticalsAPI) {
        self.api = api
    }

    func listPackages() async throws -> AdminVerticalPackagesResult {
        try await api.listPackages().toDomain()
    }

    func listActivations() async throws -> AdminVerticalActivationsResult {
        try await api.listActivations().toDomain()
    }

    func activate(verticalCode: String, request: AdminVerticalActivationRequest) async throws -> AdminVerticalActivation {
        try await api.activate(verticalCode: verticalCode, request: request.toDTO()).toDomain()
    }

    func deactivate(verticalCode: String, reason: String) async throws -> AdminVerticalActivation {
        try await api.deactivate(
            verticalCode: verticalCode,
            request: AdminVerticalDeactivateRequestDTO(reason: reason)
        ).toDomain()
    }

    func readiness(verticalCode: String) async throws -> AdminVerticalReadinessResult {
        try await api.readiness(verticalCode: verticalCode).toDomain()
    }
}
