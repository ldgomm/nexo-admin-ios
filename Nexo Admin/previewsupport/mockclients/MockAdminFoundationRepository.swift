//
//  MockAdminFoundationRepository.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import Foundation

final class MockAdminFoundationRepository: AdminFoundationRepository, @unchecked Sendable {
    var context: AdminBusinessContext
    var modules: [AdminResolvedModule]
    var readiness: [AdminModuleReadinessItem]

    init(
        context: AdminBusinessContext = MockAdminFoundationData.context,
        modules: [AdminResolvedModule] = MockAdminFoundationData.modules,
        readiness: [AdminModuleReadinessItem] = MockAdminFoundationData.readiness
    ) {
        self.context = context
        self.modules = modules
        self.readiness = readiness
    }

    func getBusinessContext(branchId: String?) async throws -> AdminBusinessContext { context }
    func listModules() async throws -> AdminModulesResult { AdminModulesResult(organizationId: context.organization.id, modules: modules) }
    func getModuleReadiness() async throws -> AdminModuleReadinessResult { AdminModuleReadinessResult(organizationId: context.organization.id, readiness: readiness) }
    func enableModule(code: String, reason: String) async throws -> AdminModulesResult {
        modules = modules.map { $0.code == code ? $0.copy(active: true, status: "enabled") : $0 }
        return AdminModulesResult(organizationId: context.organization.id, modules: modules)
    }
    func disableModule(code: String, reason: String) async throws -> AdminModulesResult {
        modules = modules.map { $0.code == code ? $0.copy(active: false, status: "disabled") : $0 }
        return AdminModulesResult(organizationId: context.organization.id, modules: modules)
    }
}

private extension AdminResolvedModule {
    func copy(active: Bool, status: String) -> AdminResolvedModule {
        AdminResolvedModule(
            code: code,
            name: name,
            category: category,
            status: status,
            active: active,
            source: source,
            dependencies: dependencies,
            compatibleActivityTypes: compatibleActivityTypes,
            defaultWorkflowModes: defaultWorkflowModes,
            permissions: permissions,
            screens: screens,
            events: events,
            blockedReasons: blockedReasons
        )
    }
}
