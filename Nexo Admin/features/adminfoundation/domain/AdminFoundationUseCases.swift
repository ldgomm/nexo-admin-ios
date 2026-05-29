//
//  AdminFoundationUseCases.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import Foundation

struct GetAdminFoundationSnapshotUseCase: Sendable {
    let repository: any AdminFoundationRepository

    func execute(branchId: String? = nil) async throws -> AdminFoundationSnapshot {
        async let contextTask = repository.getBusinessContext(branchId: branchId)
        async let modulesTask = repository.listModules()
        async let readinessTask = repository.getModuleReadiness()

        let context = try await contextTask
        let modules = try await modulesTask
        let readiness = try await readinessTask

        return AdminFoundationSnapshot(
            context: context,
            modules: modules.modules,
            readiness: readiness.readiness
        )
    }
}

struct ChangeAdminModuleStatusUseCase: Sendable {
    let repository: any AdminFoundationRepository

    func enable(code: String, reason: String) async throws -> AdminModulesResult {
        try await repository.enableModule(code: code, reason: reason)
    }

    func disable(code: String, reason: String) async throws -> AdminModulesResult {
        try await repository.disableModule(code: code, reason: reason)
    }
}
