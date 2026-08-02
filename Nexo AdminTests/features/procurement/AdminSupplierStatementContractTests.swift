//
//  AdminSupplierStatementContractTests.swift
//  Nexo AdminTests
//
//  Created by José Ruiz on 29/7/26.
//
//  27R.N — Supplier-statement routes, exact filters and permission boundaries.
//

import XCTest
@testable import Nexo_Admin

class AdminSupplierStatementContractTests: XCTestCase {
    func testRoutesUseExactAdminStatementAndOperationalExportContracts() {
        XCTAssertEqual(
            AdminProcurementRoutes.supplierStatement("sup/a?"),
            "/api/v1/admin/procurement/suppliers/sup%2Fa%3F/statement"
        )
        XCTAssertEqual(
            AdminProcurementRoutes.supplierStatementCSV("sup_1"),
            "/api/v1/admin/procurement/suppliers/sup_1/statement.csv"
        )
        XCTAssertEqual(
            AdminProcurementRoutes.reportCSV("purchases_by_supplier"),
            "/api/v1/admin/procurement/reports/purchases_by_supplier/export.csv"
        )
    }

    func testStatementQueryNormalizesContextAndBoundsPagination() {
        let dto = AdminSupplierStatementQuery(
            supplierId: " sup_1 ",
            branchId: " br_1 ",
            currency: " usd ",
            from: " 2026-07-01 ",
            to: " 2026-07-31 ",
            asOf: " 2026-07-31 ",
            limit: 500,
            cursor: " cursor_2 "
        ).toDTO()

        XCTAssertEqual(dto.supplierId, "sup_1")
        XCTAssertEqual(dto.branchId, "br_1")
        XCTAssertEqual(dto.currency, "USD")
        XCTAssertEqual(dto.from, "2026-07-01")
        XCTAssertEqual(dto.to, "2026-07-31")
        XCTAssertEqual(dto.asOf, "2026-07-31")
        XCTAssertEqual(dto.limit, 100)
        XCTAssertEqual(dto.cursor, "cursor_2")
    }

    func testOperationalExportQueryNormalizesOnlyServerSupportedFilters() {
        let dto = AdminProcurementOperationalExportQuery(
            reportType: " PURCHASES_BY_SUPPLIER ",
            branchId: " br_1 ",
            supplierId: " sup_1 ",
            category: " insumos ",
            catalogItemId: " cat_1 ",
            paymentMethod: " bank_transfer ",
            attachmentSourceType: " supplier_document ",
            currency: " usd ",
            from: " 2026-07-01 ",
            to: " 2026-07-31 ",
            asOf: " 2026-07-31 "
        ).toDTO()

        XCTAssertEqual(dto.reportType, "purchases_by_supplier")
        XCTAssertEqual(dto.branchId, "br_1")
        XCTAssertEqual(dto.supplierId, "sup_1")
        XCTAssertEqual(dto.paymentMethod, "BANK_TRANSFER")
        XCTAssertEqual(dto.attachmentSourceType, "SUPPLIER_DOCUMENT")
        XCTAssertEqual(dto.currency, "USD")
    }

    func testStatementPermissionsRemainIndependentAndAuditIsStricter() {
        XCTAssertFalse(AdminSupplierStatementAccess.canView([]))
        XCTAssertTrue(AdminSupplierStatementAccess.canView([
            PermissionCatalog.supplierStatementsView
        ]))
        XCTAssertFalse(AdminSupplierStatementAccess.canExport([
            PermissionCatalog.supplierStatementsView
        ]))
        XCTAssertTrue(AdminSupplierStatementAccess.canExport([
            PermissionCatalog.supplierStatementsView,
            PermissionCatalog.supplierStatementsExport
        ]))
        XCTAssertFalse(AdminSupplierStatementAccess.canViewAudit([
            PermissionCatalog.supplierStatementsView
        ]))
        XCTAssertTrue(AdminSupplierStatementAccess.canViewAudit([
            PermissionCatalog.procurementAuditView
        ]))
    }

    func testOperationalExportsRequireCatalogViewAndStepUpExportPermission() {
        XCTAssertFalse(AdminProcurementExportAccess.canViewCatalog([]))
        XCTAssertTrue(AdminProcurementExportAccess.canViewCatalog([
            PermissionCatalog.reportsDashboardView
        ]))
        XCTAssertFalse(AdminProcurementExportAccess.canExport([
            PermissionCatalog.reportsDashboardView
        ]))
        XCTAssertTrue(AdminProcurementExportAccess.canExport([
            PermissionCatalog.reportsDashboardView,
            PermissionCatalog.reportsExport
        ]))
    }
}
