//
//  AdminPublicProjectionRepository.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import Foundation

protocol AdminPublicProjectionRepository: Sendable {
    func getProjection() async throws -> AdminPublicStoreProjection
    func updateSettings(_ input: AdminPublicProjectionSettingsInput) async throws -> AdminPublicStoreProjection
    func publish(reason: String) async throws -> AdminPublicStoreProjection
    func hide(reason: String) async throws -> AdminPublicStoreProjection
    func suspend(reason: String) async throws -> AdminPublicStoreProjection
}
