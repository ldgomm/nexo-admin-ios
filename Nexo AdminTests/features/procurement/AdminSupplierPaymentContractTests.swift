//
//  AdminSupplierPaymentContractTests.swift
//  Nexo AdminTests
//
//  Created by José Ruiz on 29/7/26.
//
//  27R.N — Admin supplier-payment routes, filters and permission boundary.
//

import XCTest
@testable import Nexo_Admin

class AdminSupplierPaymentContractTests: XCTestCase {
    func testRoutesUseAdminReadAndVoidContract() {
        XCTAssertEqual(
            AdminProcurementRoutes.supplierPayments,
            "/api/v1/admin/procurement/supplier-payments"
        )
        XCTAssertEqual(
            AdminProcurementRoutes.supplierPayment("spay/a?"),
            "/api/v1/admin/procurement/supplier-payments/spay%2Fa%3F"
        )
        XCTAssertEqual(
            AdminProcurementRoutes.voidSupplierPayment("spay_1"),
            "/api/v1/admin/procurement/supplier-payments/spay_1/void"
        )
    }

    func testListQueryNormalizesExactServerFiltersAndBoundsLimit() {
        let dto = AdminSupplierPaymentListQuery(
            branchId: " br_1 ",
            supplierId: " sup_1 ",
            status: .recorded,
            paymentFrom: " 2026-07-01 ",
            paymentTo: " 2026-07-31 ",
            method: .bankTransfer,
            query: " SP-202607 ",
            limit: 500,
            cursor: " cursor_2 "
        ).toDTO()

        XCTAssertEqual(dto.branchId, "br_1")
        XCTAssertEqual(dto.supplierId, "sup_1")
        XCTAssertEqual(dto.status, "RECORDED")
        XCTAssertEqual(dto.paymentFrom, "2026-07-01")
        XCTAssertEqual(dto.paymentTo, "2026-07-31")
        XCTAssertEqual(dto.method, "BANK_TRANSFER")
        XCTAssertEqual(dto.query, "SP-202607")
        XCTAssertEqual(dto.limit, 100)
        XCTAssertEqual(dto.cursor, "cursor_2")
    }

    func testAllFiltersOmitOptionalQueryValues() {
        let dto = AdminSupplierPaymentListQuery(
            branchId: nil,
            supplierId: nil,
            status: .all,
            paymentFrom: nil,
            paymentTo: nil,
            method: .all,
            query: nil,
            limit: 0,
            cursor: nil
        ).toDTO()

        XCTAssertNil(dto.status)
        XCTAssertNil(dto.method)
        XCTAssertEqual(dto.limit, 1)
    }

    func testVoidInputTrimsReasonAndCarriesExactVersion() {
        let input = AdminSupplierPaymentVoidInput(
            reason: "  Pago duplicado  ",
            expectedVersion: 7,
            idempotencyKey: "void-key"
        )

        XCTAssertEqual(input.toDTO(), AdminSupplierPaymentVoidRequestDTO(
            reason: "Pago duplicado",
            expectedVersion: 7
        ))
    }

    func testAccessRequiresIndependentViewSensitiveVoidAndAuditPermissions() {
        XCTAssertFalse(AdminSupplierPaymentAccess.canView([]))
        XCTAssertTrue(AdminSupplierPaymentAccess.canView([PermissionCatalog.supplierPaymentsView]))
        XCTAssertFalse(AdminSupplierPaymentAccess.canViewSensitive([PermissionCatalog.supplierPaymentsView]))
        XCTAssertTrue(AdminSupplierPaymentAccess.canViewSensitive([
            PermissionCatalog.supplierPaymentsSensitiveView
        ]))
        XCTAssertFalse(AdminSupplierPaymentAccess.canVoid(
            .recorded,
            permissions: [PermissionCatalog.supplierPaymentsView]
        ))
        XCTAssertTrue(AdminSupplierPaymentAccess.canVoid(
            .recorded,
            permissions: [PermissionCatalog.supplierPaymentsVoid]
        ))
        XCTAssertFalse(AdminSupplierPaymentAccess.canVoid(
            .voided,
            permissions: [PermissionCatalog.supplierPaymentsVoid]
        ))
        XCTAssertTrue(AdminSupplierPaymentAccess.canViewAudit([
            PermissionCatalog.procurementAuditView
        ]))
    }
}
