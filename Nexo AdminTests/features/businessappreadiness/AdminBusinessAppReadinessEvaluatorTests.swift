//
//  AdminBusinessAppReadinessEvaluatorTests.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import XCTest
@testable import Nexo_Admin

final class AdminBusinessAppReadinessEvaluatorTests: XCTestCase {
    func testReadySnapshotHasNoRequiredBlockers() {
        let report = AdminBusinessAppReadinessEvaluator(generatedAt: { Date(timeIntervalSince1970: 0) })
            .evaluate(snapshot: makeSnapshot(context: makeContext()))

        XCTAssertTrue(report.readyForBusinessApp)
        XCTAssertEqual(report.blockedRequiredCount, 0)
        XCTAssertTrue(report.readyCount > 0)
    }

    func testMissingIdempotencyBlocksBusinessApp() {
        var context = makeContext()
        context = AdminBusinessContext(
            user: context.user,
            organization: context.organization,
            branches: context.branches,
            activeBranchId: context.activeBranchId,
            activities: context.activities,
            activeModules: context.activeModules.filter { $0 != "foundation.idempotency" },
            effectivePermissions: context.effectivePermissions,
            catalogRevision: context.catalogRevision,
            taxConfigurationRevision: context.taxConfigurationRevision,
            realtime: context.realtime
        )

        let report = AdminBusinessAppReadinessEvaluator(generatedAt: { Date(timeIntervalSince1970: 0) })
            .evaluate(snapshot: makeSnapshot(context: context))

        XCTAssertFalse(report.readyForBusinessApp)
        XCTAssertTrue(report.blockedRequiredCount >= 1)
        XCTAssertTrue(report.sections.flatMap(\.checks).contains { $0.id == "module.foundation.idempotency" && $0.status == .blocked })
    }

    func testUnknownCatalogRevisionBlocksBusinessApp() {
        var context = makeContext()
        context = AdminBusinessContext(
            user: context.user,
            organization: context.organization,
            branches: context.branches,
            activeBranchId: context.activeBranchId,
            activities: context.activities,
            activeModules: context.activeModules,
            effectivePermissions: context.effectivePermissions,
            catalogRevision: "unknown",
            taxConfigurationRevision: context.taxConfigurationRevision,
            realtime: context.realtime
        )

        let report = AdminBusinessAppReadinessEvaluator(generatedAt: { Date(timeIntervalSince1970: 0) })
            .evaluate(snapshot: makeSnapshot(context: context))

        XCTAssertFalse(report.readyForBusinessApp)
        XCTAssertTrue(report.sections.flatMap(\.checks).contains { $0.id == "catalog.revision" && $0.status == .blocked })
    }

    private func makeSnapshot(context: AdminBusinessContext) -> AdminFoundationSnapshot {
        let modules = context.activeModules.map {
            AdminResolvedModule(
                code: $0,
                name: $0,
                category: $0.hasPrefix("core") ? "core" : "foundation",
                status: "enabled",
                active: true,
                source: "system",
                dependencies: [],
                compatibleActivityTypes: [],
                defaultWorkflowModes: [],
                permissions: [],
                screens: [],
                events: [],
                blockedReasons: []
            )
        }
        let readiness = context.activeModules.map {
            AdminModuleReadinessItem(
                code: $0,
                ready: true,
                active: true,
                missingDependencies: [],
                warnings: [],
                blockers: []
            )
        }
        return AdminFoundationSnapshot(context: context, modules: modules, readiness: readiness)
    }

    private func makeContext() -> AdminBusinessContext {
        AdminBusinessContext(
            user: AdminBusinessContextUser(id: "usr_1", displayName: "Admin", email: "admin@nexo.test"),
            organization: AdminBusinessContextOrganization(id: "org_1", legalName: "Altos", commercialName: "Altos", countryCode: "EC", taxId: "9999999999999", defaultCurrency: "USD", timezone: "America/Guayaquil"),
            branches: [AdminBusinessContextBranch(id: "br_1", code: "001", name: "Matriz", type: "main", status: "active", main: true)],
            activeBranchId: "br_1",
            activities: [AdminBusinessContextActivity(id: "act_1", activityType: "restaurant", workflowMode: "quick_sale", status: "active", requiresScheduling: false)],
            activeModules: [
                "core.sales",
                "core.cash",
                "core.catalog",
                "core.customers",
                "core.documents",
                "core.receivables",
                "core.reports",
                "foundation.idempotency",
                "foundation.catalog_revision",
                "foundation.outbox",
                "foundation.realtime_events"
            ],
            effectivePermissions: [PermissionCatalog.all],
            catalogRevision: "catrev_1",
            taxConfigurationRevision: "taxrev_1",
            realtime: AdminBusinessContextRealtime(enabled: false, sseUrl: "/api/v1/realtime/events")
        )
    }
}
