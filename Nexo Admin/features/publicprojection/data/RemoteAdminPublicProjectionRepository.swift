//
//  RemoteAdminPublicProjectionRepository.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import Foundation

final class RemoteAdminPublicProjectionRepository: AdminPublicProjectionRepository, @unchecked Sendable {
    private let api: AdminPublicProjectionAPI

    init(api: AdminPublicProjectionAPI) {
        self.api = api
    }

    func getProjection() async throws -> AdminPublicStoreProjection {
        try await api.getProjection().toDomain()
    }

    func updateSettings(_ input: AdminPublicProjectionSettingsInput) async throws -> AdminPublicStoreProjection {
        try await api.updateSettings(input.toRequest()).toDomain()
    }

    func publish(reason: String) async throws -> AdminPublicStoreProjection {
        try await api.publish(AdminPublicProjectionActionRequestDTO(reason: reason)).toDomain()
    }

    func hide(reason: String) async throws -> AdminPublicStoreProjection {
        try await api.hide(AdminPublicProjectionActionRequestDTO(reason: reason)).toDomain()
    }

    func suspend(reason: String) async throws -> AdminPublicStoreProjection {
        try await api.suspend(AdminPublicProjectionActionRequestDTO(reason: reason)).toDomain()
    }
}
