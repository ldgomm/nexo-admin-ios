//
//  AdminFoundationTestRepository.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import Foundation
@testable import Nexo_Admin

final class AdminFoundationTestRepository: AdminFoundationRepository, @unchecked Sendable {
    var contextResult: AdminBusinessContext
    var modulesResult: AdminModulesResult
    var readinessResult: AdminModuleReadinessResult
    var enabledCodes: [String] = []
    var disabledCodes: [String] = []

    init(
        contextResult: AdminBusinessContext = .fixture(),
        modulesResult: AdminModulesResult = .fixture(),
        readinessResult: AdminModuleReadinessResult = .fixture()
    ) {
        self.contextResult = contextResult
        self.modulesResult = modulesResult
        self.readinessResult = readinessResult
    }

    func getBusinessContext(branchId: String?) async throws -> AdminBusinessContext {
        contextResult
    }

    func listModules() async throws -> AdminModulesResult {
        modulesResult
    }

    func getModuleReadiness() async throws -> AdminModuleReadinessResult {
        readinessResult
    }

    func enableModule(code: String, reason: String) async throws -> AdminModulesResult {
        enabledCodes.append(code)
        modulesResult = AdminModulesResult(
            organizationId: modulesResult.organizationId,
            modules: modulesResult.modules.map {
                $0.code == code ? $0.copy(active: true) : $0
            }
        )
        return modulesResult
    }

    func disableModule(code: String, reason: String) async throws -> AdminModulesResult {
        disabledCodes.append(code)
        modulesResult = AdminModulesResult(
            organizationId: modulesResult.organizationId,
            modules: modulesResult.modules.map {
                $0.code == code ? $0.copy(active: false) : $0
            }
        )
        return modulesResult
    }
}

extension AdminBusinessContext {
    static func fixture() -> AdminBusinessContext {
        AdminBusinessContext(
            user: AdminBusinessContextUser(id: "usr_1", displayName: "Admin", email: "admin@nexo.test"),
            organization: AdminBusinessContextOrganization(
                id: "org_1",
                legalName: "Altos del Murco",
                commercialName: "Altos del Murco",
                countryCode: "EC",
                taxId: "9999999999999",
                defaultCurrency: "USD",
                timezone: "America/Guayaquil"
            ),
            branches: [
                AdminBusinessContextBranch(id: "br_1", code: "001", name: "Matriz", type: "main", status: "active", main: true)
            ],
            activeBranchId: "br_1",
            activities: [
                AdminBusinessContextActivity(id: "act_1", activityType: "restaurant", workflowMode: "quick_sale", status: "active", requiresScheduling: false)
            ],
            activeModules: ["core.sales", "core.cash"],
            effectivePermissions: [PermissionCatalog.modulesView, PermissionCatalog.modulesManage],
            catalogRevision: "catrev_test",
            taxConfigurationRevision: "taxrev_test",
            realtime: AdminBusinessContextRealtime(enabled: false, sseUrl: "/api/v1/realtime/events")
        )
    }
}

extension AdminModulesResult {
    static func fixture() -> AdminModulesResult {
        AdminModulesResult(
            organizationId: "org_1",
            modules: [
                AdminResolvedModule.fixture(code: "core.sales", active: true),
                AdminResolvedModule.fixture(code: "module.reservations", active: false)
            ]
        )
    }
}

extension AdminModuleReadinessResult {
    static func fixture() -> AdminModuleReadinessResult {
        AdminModuleReadinessResult(
            organizationId: "org_1",
            readiness: [
                AdminModuleReadinessItem(code: "core.sales", ready: true, active: true, missingDependencies: [], warnings: [], blockers: []),
                AdminModuleReadinessItem(code: "module.reservations", ready: true, active: false, missingDependencies: [], warnings: [], blockers: [])
            ]
        )
    }
}

extension AdminResolvedModule {
    static func fixture(code: String, active: Bool) -> AdminResolvedModule {
        AdminResolvedModule(
            code: code,
            name: code.nexoReadableKey,
            category: code.hasPrefix("core") ? "CORE" : "OPTIONAL",
            status: "ACTIVE",
            active: active,
            source: active ? "AUTO" : "ADMIN",
            dependencies: [],
            compatibleActivityTypes: ["restaurant"],
            defaultWorkflowModes: ["quick_sale"],
            permissions: [],
            screens: [],
            events: [],
            blockedReasons: []
        )
    }

    func copy(active: Bool) -> AdminResolvedModule {
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
