//
//  AdminBusinessAppReadinessViewModelTests.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import XCTest
@testable import Nexo_Admin

@MainActor
final class AdminBusinessAppReadinessViewModelTests: XCTestCase {
    func testRefreshLoadsReportWhenUserHasPermission() async {
        let repository = FakeFoundationRepository()
        let viewModel = AdminBusinessAppReadinessViewModel(
            repository: repository,
            permissions: [PermissionCatalog.modulesView],
            evaluator: AdminBusinessAppReadinessEvaluator(generatedAt: { Date(timeIntervalSince1970: 0) })
        )

        await viewModel.refresh()

        guard case .loaded(let report) = viewModel.state else {
            return XCTFail("Expected loaded state")
        }
        XCTAssertTrue(report.readyForBusinessApp)
        XCTAssertEqual(repository.contextCalls, 1)
        XCTAssertEqual(repository.modulesCalls, 1)
        XCTAssertEqual(repository.readinessCalls, 1)
    }

    func testRefreshFailsWhenUserCannotView() async {
        let viewModel = AdminBusinessAppReadinessViewModel(
            repository: FakeFoundationRepository(),
            permissions: [],
            evaluator: AdminBusinessAppReadinessEvaluator(generatedAt: { Date(timeIntervalSince1970: 0) })
        )

        await viewModel.refresh()

        guard case .failed(let message) = viewModel.state else {
            return XCTFail("Expected failed state")
        }
        XCTAssertTrue(message.contains("permisos"))
    }
}

final class FakeFoundationRepository: AdminFoundationRepository, @unchecked Sendable {
    var contextCalls = 0
    var modulesCalls = 0
    var readinessCalls = 0

    private let storedContext = AdminBusinessContext(
            user: AdminBusinessContextUser(id: "usr_1", displayName: "Admin", email: "admin@nexo.test"),
            organization: AdminBusinessContextOrganization(id: "org_1", legalName: "Altos", commercialName: "Altos", countryCode: "EC", taxId: "9999999999999", defaultCurrency: "USD", timezone: "America/Guayaquil"),
            branches: [AdminBusinessContextBranch(id: "br_1", code: "001", name: "Matriz", type: "main", status: "active", main: true)],
            activeBranchId: "br_1",
            activities: [AdminBusinessContextActivity(id: "act_1", activityType: "restaurant", workflowMode: "quick_sale", status: "active", requiresScheduling: false)],
            activeModules: [
                "core.sales", "core.cash", "core.catalog", "core.customers", "core.documents", "core.receivables", "core.reports",
                "foundation.idempotency", "foundation.catalog_revision", "foundation.outbox", "foundation.realtime_events"
            ],
            effectivePermissions: [PermissionCatalog.all],
            catalogRevision: "catrev_1",
            taxConfigurationRevision: "taxrev_1",
            realtime: AdminBusinessContextRealtime(enabled: false, sseUrl: "/api/v1/realtime/events")
        )

    func getBusinessContext(branchId: String?) async throws -> AdminBusinessContext {
        contextCalls += 1
        return storedContext
    }

    func listModules() async throws -> AdminModulesResult {
        modulesCalls += 1
        return AdminModulesResult(
            organizationId: storedContext.organization.id,
            modules: storedContext.activeModules.map {
                AdminResolvedModule(code: $0, name: $0, category: "test", status: "enabled", active: true, source: "test", dependencies: [], compatibleActivityTypes: [], defaultWorkflowModes: [], permissions: [], screens: [], events: [], blockedReasons: [])
            }
        )
    }

    func getModuleReadiness() async throws -> AdminModuleReadinessResult {
        readinessCalls += 1
        return AdminModuleReadinessResult(
            organizationId: storedContext.organization.id,
            readiness: storedContext.activeModules.map {
                AdminModuleReadinessItem(code: $0, ready: true, active: true, missingDependencies: [], warnings: [], blockers: [])
            }
        )
    }

    func enableModule(code: String, reason: String) async throws -> AdminModulesResult { try await listModules() }
    func disableModule(code: String, reason: String) async throws -> AdminModulesResult { try await listModules() }
}
