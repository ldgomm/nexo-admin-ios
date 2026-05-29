//
//  AdminFoundationRepository.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import Foundation

protocol AdminFoundationRepository: Sendable {
    func getBusinessContext(branchId: String?) async throws -> AdminBusinessContext
    func listModules() async throws -> AdminModulesResult
    func getModuleReadiness() async throws -> AdminModuleReadinessResult
    func enableModule(code: String, reason: String) async throws -> AdminModulesResult
    func disableModule(code: String, reason: String) async throws -> AdminModulesResult
}

final class AdminFoundationRemoteRepository: AdminFoundationRepository, @unchecked Sendable {
    private let api: AdminFoundationAPI

    init(api: AdminFoundationAPI) {
        self.api = api
    }

    func getBusinessContext(branchId: String?) async throws -> AdminBusinessContext {
        try await api.getBusinessContext(branchId: branchId).toDomain()
    }

    func listModules() async throws -> AdminModulesResult {
        try await api.listModules().toDomain()
    }

    func getModuleReadiness() async throws -> AdminModuleReadinessResult {
        try await api.getModuleReadiness().toDomain()
    }

    func enableModule(code: String, reason: String) async throws -> AdminModulesResult {
        try await api.enableModule(code: code, reason: reason).toDomain()
    }

    func disableModule(code: String, reason: String) async throws -> AdminModulesResult {
        try await api.disableModule(code: code, reason: reason).toDomain()
    }
}
