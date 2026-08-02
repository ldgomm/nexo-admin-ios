//
//  AdminProcurementExportsViewModelTests.swift
//  Nexo AdminTests
//
//  Created by José Ruiz on 29/7/26.
//
//  27R.N — Backend catalog validation and operational CSV export.
//

import Foundation
import XCTest
@testable import Nexo_Admin

@MainActor
class AdminProcurementExportsViewModelTests: XCTestCase {
    func testCatalogContainsExactlyNineOperationalReportsAndExcludesStatement() async {
        let repository = AdminProcurementTestRepository()
        let viewModel = makeViewModel(repository, permissions: [PermissionCatalog.reportsDashboardView])

        await viewModel.refreshCatalog()

        XCTAssertEqual(repository.reportCatalogRequestCount, 1)
        XCTAssertEqual(viewModel.reports.count, 9)
        XCTAssertFalse(viewModel.reports.contains(where: { $0.reportType == "supplier_statement" }))
        XCTAssertEqual(
            Set(viewModel.reports.map(\.reportType)),
            AdminProcurementReadinessEvaluator.requiredReportTypes.subtracting(["supplier_statement"])
        )
        XCTAssertNil(viewModel.errorMessage)
    }

    func testExportNormalizesFiltersAndUsesSelectedCatalogReport() async throws {
        let repository = AdminProcurementTestRepository()
        let viewModel = makeViewModel(repository, permissions: [
            PermissionCatalog.reportsDashboardView,
            PermissionCatalog.reportsExport
        ])
        await viewModel.refreshCatalog()
        viewModel.branchId = " br_1 "
        viewModel.supplierId = " sup_1 "
        viewModel.paymentMethod = " bank_transfer "
        viewModel.attachmentSourceType = " supplier_payment "
        viewModel.currency = " usd "
        viewModel.from = " 2026-07-01 "
        viewModel.to = " 2026-07-31 "
        viewModel.asOf = " 2026-07-31 "
        let report = try XCTUnwrap(viewModel.reports.first(where: {
            $0.reportType == "purchases_by_supplier"
        }))

        await viewModel.export(report)

        let query = try XCTUnwrap(repository.operationalReportDownloadQueries.first)
        XCTAssertEqual(query.reportType, "purchases_by_supplier")
        XCTAssertEqual(query.branchId, "br_1")
        XCTAssertEqual(query.supplierId, "sup_1")
        XCTAssertEqual(query.paymentMethod, "BANK_TRANSFER")
        XCTAssertEqual(query.attachmentSourceType, "SUPPLIER_PAYMENT")
        XCTAssertEqual(query.currency, "USD")
        XCTAssertEqual(query.from, "2026-07-01")
        XCTAssertEqual(query.to, "2026-07-31")
        XCTAssertEqual(query.asOf, "2026-07-31")
        XCTAssertEqual(viewModel.downloadedFile?.exportVersion, "27R.L.v1")
    }

    func testMissingOperationalCatalogEntryIsRejectedBeforeExport() async {
        let repository = AdminProcurementTestRepository()
        let original = AdminProcurementContractSnapshot.fixture().catalog
        repository.reportCatalogResult = .success(AdminProcurementReportCatalog(
            contractVersion: original.contractVersion,
            reports: original.reports.filter { $0.reportType != "purchases_by_supplier" },
            financeFactsPath: original.financeFactsPath,
            financeFactsCsvPath: original.financeFactsCsvPath,
            accountingEntriesGenerated: original.accountingEntriesGenerated
        ))
        let viewModel = makeViewModel(repository, permissions: [
            PermissionCatalog.reportsDashboardView,
            PermissionCatalog.reportsExport
        ])

        await viewModel.refreshCatalog()

        XCTAssertTrue(viewModel.reports.isEmpty)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertTrue(repository.operationalReportDownloadQueries.isEmpty)
    }

    func testFailedCatalogRefreshClearsPreviouslyValidatedReports() async {
        let repository = AdminProcurementTestRepository()
        let viewModel = makeViewModel(repository, permissions: [PermissionCatalog.reportsDashboardView])

        await viewModel.refreshCatalog()
        XCTAssertEqual(viewModel.reports.count, 9)

        repository.reportCatalogResult = .failure(AppError.transport("fallo controlado"))
        await viewModel.refreshCatalog()

        XCTAssertTrue(viewModel.reports.isEmpty)
        XCTAssertNotNil(viewModel.errorMessage)
    }

    func testExportPermissionAndInvalidDateStopBeforeRepositoryCall() async throws {
        let blockedRepository = AdminProcurementTestRepository()
        let blocked = makeViewModel(blockedRepository, permissions: [PermissionCatalog.reportsDashboardView])
        await blocked.refreshCatalog()
        let blockedReport = try XCTUnwrap(blocked.reports.first)
        await blocked.export(blockedReport)
        XCTAssertTrue(blockedRepository.operationalReportDownloadQueries.isEmpty)

        let repository = AdminProcurementTestRepository()
        let invalid = makeViewModel(repository, permissions: [
            PermissionCatalog.reportsDashboardView,
            PermissionCatalog.reportsExport
        ])
        await invalid.refreshCatalog()
        invalid.from = "2026-08-01"
        invalid.to = "2026-07-31"
        let report = try XCTUnwrap(invalid.reports.first)
        await invalid.export(report)
        XCTAssertTrue(repository.operationalReportDownloadQueries.isEmpty)
        XCTAssertNotNil(invalid.errorMessage)
    }

    private func makeViewModel(
        _ repository: AdminProcurementTestRepository,
        permissions: Set<String>
    ) -> AdminProcurementExportsViewModel {
        AdminProcurementExportsViewModel(repository: repository, permissions: permissions)
    }
}
