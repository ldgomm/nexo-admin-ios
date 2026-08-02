//
//  AdminSupplierStatementViewModelTests.swift
//  Nexo AdminTests
//
//  Created by José Ruiz on 29/7/26.
//
//  27R.N — Supplier context, canonical pagination and backend CSV export.
//

import Foundation
import XCTest
@testable import Nexo_Admin

@MainActor
class AdminSupplierStatementViewModelTests: XCTestCase {
    func testInitialSupplierCreatesExactContextAndNormalizedQuery() async {
        let repository = AdminProcurementTestRepository()
        repository.supplierStatementResults = [
            .success(statement(
                opening: "10.00",
                lines: [line(id: "stmt_1", charge: "100.00", credit: "0.00", running: "110.00")],
                closing: "110.00"
            ))
        ]
        let supplier = AdminSupplier.fixture()
        let viewModel = makeViewModel(repository, supplier: supplier)
        viewModel.branchId = " br_1 "
        viewModel.currency = " usd "
        viewModel.from = " 2026-07-01 "
        viewModel.to = " 2026-07-31 "
        viewModel.asOf = " 2026-07-31 "

        await viewModel.refresh()

        XCTAssertEqual(viewModel.selectedSupplierId, "sup_1")
        XCTAssertEqual(viewModel.selectedSupplierName, "Proveedor Uno")
        XCTAssertEqual(viewModel.openingBalance?.amount, Decimal(string: "10.00"))
        XCTAssertEqual(viewModel.closingBalance?.amount, Decimal(string: "110.00"))
        let query = repository.supplierStatementQueries.first
        XCTAssertEqual(query?.supplierId, "sup_1")
        XCTAssertEqual(query?.branchId, "br_1")
        XCTAssertEqual(query?.currency, "USD")
        XCTAssertEqual(query?.from, "2026-07-01")
        XCTAssertEqual(query?.to, "2026-07-31")
        XCTAssertEqual(query?.asOf, "2026-07-31")
        XCTAssertEqual(query?.limit, 100)
        XCTAssertNil(query?.cursor)
    }

    func testPaginationRequiresCanonicalBalanceContinuityAndUsesBackendCursor() async throws {
        let repository = AdminProcurementTestRepository()
        repository.supplierStatementResults = [
            .success(statement(
                opening: "0.00",
                lines: [line(id: "stmt_1", charge: "100.00", credit: "0.00", running: "100.00")],
                closing: "100.00",
                nextCursor: "cursor_2",
                hasMore: true
            )),
            .success(statement(
                opening: "100.00",
                lines: [line(
                    id: "stmt_2",
                    sourceType: .paymentAllocation,
                    charge: "0.00",
                    credit: "30.00",
                    running: "70.00"
                )],
                closing: "70.00"
            ))
        ]
        let viewModel = makeViewModel(repository)
        configureCanonicalStatementContext(viewModel)

        await viewModel.refresh()
        let first = try XCTUnwrap(viewModel.lines.first)
        await viewModel.loadNextPageIfNeeded(currentLine: first)

        XCTAssertEqual(viewModel.lines.map(\.id), ["stmt_1", "stmt_2"])
        XCTAssertEqual(viewModel.openingBalance?.amount, Decimal(string: "0.00"))
        XCTAssertEqual(viewModel.closingBalance?.amount, Decimal(string: "70.00"))
        XCTAssertEqual(repository.supplierStatementQueries.last?.cursor, "cursor_2")
        XCTAssertFalse(viewModel.hasMore)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testDiscontinuousSecondPageStopsWithoutMixingLines() async throws {
        let repository = AdminProcurementTestRepository()
        repository.supplierStatementResults = [
            .success(statement(
                opening: "0.00",
                lines: [line(id: "stmt_1", charge: "100.00", credit: "0.00", running: "100.00")],
                closing: "100.00",
                nextCursor: "cursor_2",
                hasMore: true
            )),
            .success(statement(
                opening: "99.00",
                lines: [line(id: "stmt_2", charge: "1.00", credit: "0.00", running: "100.00")],
                closing: "100.00"
            ))
        ]
        let viewModel = makeViewModel(repository)
        configureCanonicalStatementContext(viewModel)

        await viewModel.refresh()
        let first = try XCTUnwrap(viewModel.lines.first)
        await viewModel.loadNextPageIfNeeded(currentLine: first)

        XCTAssertEqual(viewModel.lines.map(\.id), ["stmt_1"])
        XCTAssertEqual(viewModel.closingBalance?.amount, Decimal(string: "100.00"))
        XCTAssertNotNil(viewModel.errorMessage)
    }

    func testFailedRefreshAfterFilterChangeClearsPreviouslyLoadedStatement() async {
        let repository = AdminProcurementTestRepository()
        repository.supplierStatementResults = [
            .success(statement(
                opening: "0.00",
                lines: [line(id: "stmt_1", charge: "100.00", credit: "0.00", running: "100.00")],
                closing: "100.00"
            )),
            .failure(AppError.transport("fallo controlado"))
        ]
        let viewModel = makeViewModel(repository)
        configureCanonicalStatementContext(viewModel)

        await viewModel.refresh()
        XCTAssertEqual(viewModel.lines.map(\.id), ["stmt_1"])

        viewModel.from = "2026-07-02"
        await viewModel.refresh()

        XCTAssertTrue(viewModel.lines.isEmpty)
        XCTAssertNil(viewModel.openingBalance)
        XCTAssertNil(viewModel.closingBalance)
        XCTAssertNotNil(viewModel.errorMessage)
    }

    func testBranchContextMismatchIsRejectedWithoutPublishingRows() async {
        let repository = AdminProcurementTestRepository()
        repository.supplierStatementResults = [
            .success(AdminSupplierStatement(
                supplierId: "sup_1",
                branchId: "br_wrong",
                currency: "USD",
                from: nil,
                to: nil,
                asOf: "2026-07-31",
                openingBalance: money("0.00"),
                lines: [line(id: "stmt_1", charge: "10.00", credit: "0.00", running: "10.00")],
                closingBalance: money("10.00"),
                nextCursor: nil,
                hasMore: false
            ))
        ]
        let viewModel = makeViewModel(repository)
        viewModel.branchId = "br_1"
        viewModel.asOf = "2026-07-31"

        await viewModel.refresh()

        XCTAssertTrue(viewModel.lines.isEmpty)
        XCTAssertNil(viewModel.closingBalance)
        XCTAssertNotNil(viewModel.errorMessage)
    }

    func testCSVExportUsesCurrentFiltersAndServerFileOnlyWithBothPermissions() async {
        let repository = AdminProcurementTestRepository()
        let viewModel = makeViewModel(
            repository,
            permissions: [
                PermissionCatalog.supplierStatementsView,
                PermissionCatalog.supplierStatementsExport
            ]
        )
        viewModel.from = "2026-07-01"
        viewModel.to = "2026-07-31"
        viewModel.asOf = "2026-07-31"

        await viewModel.exportCSV()

        XCTAssertEqual(repository.supplierStatementDownloadQueries.count, 1)
        XCTAssertEqual(repository.supplierStatementDownloadQueries.first?.cursor, nil)
        XCTAssertEqual(repository.supplierStatementDownloadQueries.first?.limit, 100)
        XCTAssertEqual(viewModel.downloadedFile?.exportType, "supplier_statement")
        XCTAssertEqual(viewModel.downloadedFile?.exportVersion, "27R.J.v1")
        XCTAssertNil(viewModel.errorMessage)

        let deniedRepository = AdminProcurementTestRepository()
        let denied = makeViewModel(
            deniedRepository,
            permissions: [PermissionCatalog.supplierStatementsView]
        )
        await denied.exportCSV()
        XCTAssertTrue(deniedRepository.supplierStatementDownloadQueries.isEmpty)
        XCTAssertNotNil(denied.errorMessage)
    }

    func testOperationalExportUsesValidatedBackendCatalogAndExactReportType() async throws {
        let repository = AdminProcurementTestRepository()
        repository.operationalReportDownloadResult = .success(.fixture(
            exportType: "purchases_by_supplier",
            exportVersion: "27R.L.v1",
            fileName: "nexo_purchases_by_supplier.csv"
        ))
        let viewModel = AdminProcurementExportsViewModel(
            repository: repository,
            permissions: [
                PermissionCatalog.reportsDashboardView,
                PermissionCatalog.reportsExport
            ]
        )

        await viewModel.refreshCatalog()
        let report = try XCTUnwrap(
            viewModel.reports.first(where: { $0.reportType == "purchases_by_supplier" })
        )
        viewModel.currency = " usd "
        viewModel.from = "2026-07-01"
        viewModel.to = "2026-07-31"
        await viewModel.export(report)

        XCTAssertEqual(viewModel.reports.count, 9)
        XCTAssertEqual(repository.operationalReportDownloadQueries.first?.reportType, "purchases_by_supplier")
        XCTAssertEqual(repository.operationalReportDownloadQueries.first?.currency, "USD")
        XCTAssertEqual(viewModel.downloadedFile?.exportVersion, "27R.L.v1")
        XCTAssertNil(viewModel.errorMessage)
    }

    private func configureCanonicalStatementContext(
        _ viewModel: AdminSupplierStatementViewModel
    ) {
        viewModel.branchId = "br_1"
        viewModel.from = "2026-07-01"
        viewModel.to = "2026-07-31"
        viewModel.asOf = "2026-07-31"
    }

    private func makeViewModel(
        _ repository: AdminProcurementTestRepository,
        permissions: Set<String> = [
            PermissionCatalog.supplierStatementsView,
            PermissionCatalog.suppliersView,
            PermissionCatalog.procurementAuditView
        ],
        supplier: AdminSupplier = .fixture()
    ) -> AdminSupplierStatementViewModel {
        AdminSupplierStatementViewModel(
            repository: repository,
            permissions: permissions,
            initialSupplier: supplier
        )
    }

    private func statement(
        opening: String,
        lines: [AdminSupplierStatementLine],
        closing: String,
        nextCursor: String? = nil,
        hasMore: Bool = false
    ) -> AdminSupplierStatement {
        AdminSupplierStatement(
            supplierId: "sup_1",
            branchId: "br_1",
            currency: "USD",
            from: "2026-07-01",
            to: "2026-07-31",
            asOf: "2026-07-31",
            openingBalance: money(opening),
            lines: lines,
            closingBalance: money(closing),
            nextCursor: nextCursor,
            hasMore: hasMore
        )
    }

    private func line(
        id: String,
        sourceType: AdminSupplierStatementSourceType = .supplierDocument,
        charge: String,
        credit: String,
        running: String
    ) -> AdminSupplierStatementLine {
        AdminSupplierStatementLine(
            id: id,
            occurredAt: "2026-07-24T15:00:00Z",
            sourceType: sourceType,
            sourceId: "source_\(id)",
            description: "Movimiento \(id)",
            charge: money(charge),
            credit: money(credit),
            runningBalance: money(running),
            currency: "USD",
            auditResourceType: "supplier_document",
            auditResourceId: "audit_\(id)"
        )
    }

    private func money(_ amount: String) -> AdminProcurementMoney {
        AdminProcurementMoney(amount: Decimal(string: amount)!, currency: "USD")
    }
}
