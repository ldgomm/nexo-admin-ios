//
//  AdminPurchaseOrderContractTests.swift
//  Nexo AdminTests
//
//  27R.N.3 — Admin purchase order read contract and permission boundary.
//

import XCTest
@testable import Nexo_Admin

final class AdminPurchaseOrderContractTests: XCTestCase {
    func testRoutesStayInsideExactReadOnlyAdminNamespace() {
        XCTAssertEqual(
            AdminProcurementRoutes.purchaseOrders,
            "/api/v1/admin/procurement/purchase-orders"
        )
        XCTAssertEqual(
            AdminProcurementRoutes.purchaseOrder("po/one ?"),
            "/api/v1/admin/procurement/purchase-orders/po%2Fone%20%3F"
        )
        XCTAssertFalse(AdminProcurementRoutes.purchaseOrders.contains("/business/"))
    }

    func testListQueryUsesOnlyBackendSupportedFiltersAndBoundsLimit() {
        let dto = AdminPurchaseOrderListQuery(
            branchId: " br_1 ",
            supplierId: " sup_1 ",
            status: .partiallyReceived,
            expectedFrom: " 2026-07-01 ",
            expectedTo: " 2026-07-31 ",
            query: " PO-260721 ",
            limit: 500,
            cursor: " cursor_2 "
        ).toDTO()

        XCTAssertEqual(dto.branchId, "br_1")
        XCTAssertEqual(dto.supplierId, "sup_1")
        XCTAssertEqual(dto.status, "PARTIALLY_RECEIVED")
        XCTAssertEqual(dto.expectedFrom, "2026-07-01")
        XCTAssertEqual(dto.expectedTo, "2026-07-31")
        XCTAssertEqual(dto.query, "PO-260721")
        XCTAssertEqual(dto.limit, 100)
        XCTAssertEqual(dto.cursor, "cursor_2")
    }

    func testAllStatusOmitsWireFilter() {
        let dto = AdminPurchaseOrderListQuery(
            branchId: nil,
            supplierId: nil,
            status: .all,
            expectedFrom: nil,
            expectedTo: nil,
            query: nil,
            limit: 0,
            cursor: nil
        ).toDTO()

        XCTAssertNil(dto.status)
        XCTAssertEqual(dto.limit, 1)
    }

    func testViewAndCostPermissionsRemainIndependent() {
        XCTAssertTrue(AdminPurchaseOrderAccess.canView([PermissionCatalog.purchaseOrdersView]))
        XCTAssertFalse(AdminPurchaseOrderAccess.canViewCosts([PermissionCatalog.purchaseOrdersView]))
        XCTAssertTrue(AdminPurchaseOrderAccess.canViewCosts([PermissionCatalog.purchaseOrdersCostView]))
        XCTAssertTrue(AdminPurchaseOrderAccess.canView([PermissionCatalog.all]))
        XCTAssertTrue(AdminPurchaseOrderAccess.canViewCosts([PermissionCatalog.all]))
    }
}
