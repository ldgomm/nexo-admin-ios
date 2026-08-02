//
//  AdminProcurementReadinessEvaluatorTests.swift
//  Nexo AdminTests
//
//  Created by José Ruiz on 29/7/26.
//

import XCTest
@testable import Nexo_Admin

class AdminProcurementReadinessEvaluatorTests: XCTestCase {
    func testExactBackendContractsAndModulesAreReady() async throws {
        let report = try await makeReport(contracts: .fixture())

        XCTAssertTrue(report.isReady)
        XCTAssertEqual(report.blockedCount, 0)
        XCTAssertEqual(report.reportCount, 10)
        XCTAssertEqual(report.matchingPayableCount, 2)
        XCTAssertEqual(report.financeFactCount, 4)
        XCTAssertEqual(report.financeSourceFactSchemaVersion, 1)
        XCTAssertEqual(report.financeSourceFactTypeCount, 9)
        XCTAssertEqual(report.accountingCompletenessMatrix?.totalItemCount, 33)
        XCTAssertEqual(report.accountingCompletenessMatrix?.passExistingCount, 20)
        XCTAssertEqual(report.accountingCompletenessMatrix?.futureGapCount, 10)
        XCTAssertEqual(report.accountingCompletenessMatrix?.notApplicableCount, 3)
        XCTAssertEqual(
            report.accountingCompletenessMatrix?.items.first { $0.id == "SERVICE_PERIOD" }?.classification,
            .documentFutureGap
        )
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
        XCTAssertTrue(report.checks.contains { $0.id == "finance-source-facts-v1.contract" && $0.status == .blocked })
    }

    func testReplayBoundaryFailureBlocksReadiness() async throws {
        let report = try await makeReport(contracts: .fixture(replayReadOnly: false))

        XCTAssertFalse(report.isReady)
        XCTAssertTrue(report.checks.contains { $0.id == "finance-source-facts-v1.boundary" && $0.status == .blocked })
    }

    func testReplayCursorMismatchBlocksReadiness() async throws {
        let report = try await makeReport(contracts: .fixture(replayHasMore: true, replayNextCursorAvailable: false))

        XCTAssertFalse(report.isReady)
        XCTAssertTrue(report.checks.contains { $0.id == "finance-source-facts-v1.cursor" && $0.status == .blocked })
    }

    func testAccountingCompletenessVersionMismatchBlocksReadiness() async throws {
        let report = try await makeReport(contracts: .fixture(accountingMatrixVersion: "unexpected"))

        XCTAssertFalse(report.isReady)
        XCTAssertTrue(report.checks.contains { $0.id == "accounting-completeness.contract" && $0.status == .blocked })
    }

    func testAccountingCompletenessBoundaryFailureBlocksReadiness() async throws {
        let report = try await makeReport(contracts: .fixture(accountingMatrixReadOnly: false))

        XCTAssertFalse(report.isReady)
        XCTAssertTrue(report.checks.contains { $0.id == "accounting-completeness.boundary" && $0.status == .blocked })
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
