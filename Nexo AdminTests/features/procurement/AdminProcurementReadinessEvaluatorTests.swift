//
//  AdminProcurementReadinessEvaluatorTests.swift
//  Nexo AdminTests
//

import XCTest
@testable import Nexo_Admin

final class AdminProcurementReadinessEvaluatorTests: XCTestCase {
    func testExactBackendContractsAndModulesAreReady() async throws {
        let report = try await makeReport(contracts: .fixture())

        XCTAssertTrue(report.isReady)
        XCTAssertEqual(report.blockedCount, 0)
        XCTAssertEqual(report.reportCount, 10)
        XCTAssertEqual(report.matchingPayableCount, 2)
        XCTAssertEqual(report.financeFactCount, 4)
    }

    func testBackendReconciliationFailureBlocksReadiness() async throws {
        let report = try await makeReport(contracts: .fixture(payableReconciled: false))

        XCTAssertFalse(report.isReady)
        XCTAssertTrue(report.checks.contains { $0.id == "payables.reconciled" && $0.status == .blocked })
    }

    func testAccountingEntryGenerationInside27RBlocksBoundary() async throws {
        let report = try await makeReport(contracts: .fixture(accountingEntriesGenerated: true))

        XCTAssertFalse(report.isReady)
        XCTAssertTrue(report.checks.contains { $0.id == "accounting.not-generated" && $0.status == .blocked })
    }

    func testBackendBranchScopeMismatchBlocksReadiness() async throws {
        let report = try await makeReport(contracts: .fixture(branchId: "br_other"))

        XCTAssertFalse(report.isReady)
        XCTAssertTrue(report.checks.contains { $0.id == "payables.contract" && $0.status == .blocked })
        XCTAssertTrue(report.checks.contains { $0.id == "finance-facts.contract" && $0.status == .blocked })
    }

    func testUnexpectedCatalogImplementationBlocksReadiness() async throws {
        let report = try await makeReport(contracts: .fixture(catalogImplementationOverride: "unexpected"))

        XCTAssertFalse(report.isReady)
        XCTAssertTrue(report.checks.contains { $0.id == "catalog.complete" && $0.status == .blocked })
    }

    func testLimitedRoleCreatesPermissionWarningsWithoutRecalculatingBackendHealth() async throws {
        let foundation = AdminFoundationTestRepository.procurementReady()
        let context = foundation.contextResult
        foundation.contextResult = AdminBusinessContext(
            user: context.user,
            organization: context.organization,
            branches: context.branches,
            activeBranchId: context.activeBranchId,
            activities: context.activities,
            activeModules: context.activeModules,
            effectivePermissions: [PermissionCatalog.reportsDashboardView],
            catalogRevision: context.catalogRevision,
            taxConfigurationRevision: context.taxConfigurationRevision,
            realtime: context.realtime
        )

        let report = try await GetAdminProcurementReadinessReportUseCase(
            foundationRepository: foundation,
            procurementRepository: AdminProcurementTestRepository(),
            evaluator: AdminProcurementReadinessEvaluator(generatedAt: { Date(timeIntervalSince1970: 0) })
        ).execute()

        XCTAssertTrue(report.isReady)
        XCTAssertGreaterThan(report.warningCount, 0)
        XCTAssertEqual(report.openPayableBalance?.amount, Decimal(string: "125.40"))
    }

    func testInactivePurchasesModuleProducesBlockedReportWithoutCallingProcurement() async throws {
        let foundation = AdminFoundationTestRepository.procurementReady()
        let context = foundation.contextResult
        foundation.contextResult = AdminBusinessContext(
            user: context.user,
            organization: context.organization,
            branches: context.branches,
            activeBranchId: context.activeBranchId,
            activities: context.activities,
            activeModules: ["core.reports"],
            effectivePermissions: context.effectivePermissions,
            catalogRevision: context.catalogRevision,
            taxConfigurationRevision: context.taxConfigurationRevision,
            realtime: context.realtime
        )
        foundation.modulesResult = AdminModulesResult(
            organizationId: "org_1",
            modules: foundation.modulesResult.modules.map {
                $0.code == "module.purchases" ? $0.copy(active: false) : $0
            }
        )
        foundation.readinessResult = AdminModuleReadinessResult(
            organizationId: "org_1",
            readiness: foundation.readinessResult.readiness.map {
                $0.code == "module.purchases"
                    ? AdminModuleReadinessItem(code: $0.code, ready: false, active: false, missingDependencies: [], warnings: [], blockers: [])
                    : $0
            }
        )
        let procurement = AdminProcurementTestRepository()

        let report = try await GetAdminProcurementReadinessReportUseCase(
            foundationRepository: foundation,
            procurementRepository: procurement
        ).execute()

        XCTAssertFalse(report.isReady)
        XCTAssertNil(report.reportCount)
        XCTAssertTrue(procurement.requests.isEmpty)
        XCTAssertTrue(report.checks.contains { $0.id == "backend.available" && $0.status == .blocked })
    }

    private func makeReport(
        contracts: AdminProcurementContractSnapshot
    ) async throws -> AdminProcurementReadinessReport {
        try await GetAdminProcurementReadinessReportUseCase(
            foundationRepository: AdminFoundationTestRepository.procurementReady(),
            procurementRepository: AdminProcurementTestRepository(result: .success(contracts)),
            evaluator: AdminProcurementReadinessEvaluator(generatedAt: { Date(timeIntervalSince1970: 0) })
        ).execute()
    }
}
