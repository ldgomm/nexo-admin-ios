//
//  AdminSupplierDocumentContractTests.swift
//  Nexo AdminTests
//
//  Created by José Ruiz on 29/7/26.
//
//  27R.N — Admin supplier document read contract and permission boundary.
//

import XCTest
@testable import Nexo_Admin

class AdminSupplierDocumentContractTests: XCTestCase {
    func testRoutesStayInsideExactReadOnlyAdminNamespace() {
        XCTAssertEqual(
            AdminProcurementRoutes.supplierDocuments,
            "/api/v1/admin/procurement/supplier-documents"
        )
        XCTAssertEqual(
            AdminProcurementRoutes.supplierDocument("sdoc/one ?"),
            "/api/v1/admin/procurement/supplier-documents/sdoc%2Fone%20%3F"
        )
        XCTAssertFalse(AdminProcurementRoutes.supplierDocuments.contains("/business/"))
    }

    func testListQueryUsesOnlyBackendSupportedFiltersAndBoundsLimit() {
        let dto = AdminSupplierDocumentListQuery(
            branchId: " br_1 ",
            supplierId: " sup_1 ",
            documentType: .supplierInvoice,
            status: .confirmed,
            documentDateFrom: " 2026-07-01 ",
            documentDateTo: " 2026-07-31 ",
            dueDateFrom: " 2026-08-01 ",
            dueDateTo: " 2026-08-31 ",
            query: " FAC-001 ",
            limit: 500,
            cursor: " cursor_2 "
        ).toDTO()

        XCTAssertEqual(dto.branchId, "br_1")
        XCTAssertEqual(dto.supplierId, "sup_1")
        XCTAssertEqual(dto.documentType, "SUPPLIER_INVOICE")
        XCTAssertEqual(dto.status, "CONFIRMED")
        XCTAssertEqual(dto.documentDateFrom, "2026-07-01")
        XCTAssertEqual(dto.documentDateTo, "2026-07-31")
        XCTAssertEqual(dto.dueDateFrom, "2026-08-01")
        XCTAssertEqual(dto.dueDateTo, "2026-08-31")
        XCTAssertEqual(dto.query, "FAC-001")
        XCTAssertEqual(dto.limit, 100)
        XCTAssertEqual(dto.cursor, "cursor_2")
    }

    func testAllFiltersAreOmittedAndLimitIsLowerBounded() {
        let dto = AdminSupplierDocumentListQuery(
            branchId: nil,
            supplierId: nil,
            documentType: .all,
            status: .all,
            documentDateFrom: nil,
            documentDateTo: nil,
            dueDateFrom: nil,
            dueDateTo: nil,
            query: nil,
            limit: 0,
            cursor: nil
        ).toDTO()

        XCTAssertNil(dto.documentType)
        XCTAssertNil(dto.status)
        XCTAssertEqual(dto.limit, 1)
    }

    @MainActor
    func testViewPermissionRemainsCanonicalAndDoesNotImplyAuditPermission() {
        XCTAssertTrue(AdminSupplierDocumentAccess.canView([PermissionCatalog.supplierDocumentsView]))
        XCTAssertFalse(AdminSupplierDocumentAccess.canView([]))
        XCTAssertTrue(AdminSupplierDocumentAccess.canView([PermissionCatalog.all]))

        let repository = AdminProcurementTestRepository()
        let viewOnly = AdminSupplierDocumentViewModel(
            repository: repository,
            permissions: [PermissionCatalog.supplierDocumentsView]
        )
        XCTAssertFalse(viewOnly.canViewAudit)
    }
}
