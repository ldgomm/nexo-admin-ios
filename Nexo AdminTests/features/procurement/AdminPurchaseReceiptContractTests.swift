//
//  AdminPurchaseReceiptContractTests.swift
//  Nexo AdminTests
//
//  Created by José Ruiz on 29/7/26.
//
//  27R.N.4 — Exact Admin read routes, filters and permission boundaries.
//

import XCTest
@testable import Nexo_Admin

class AdminPurchaseReceiptContractTests: XCTestCase {
    func testRoutesStayInsideExactReadOnlyAdminNamespace() {
        XCTAssertEqual(
            AdminProcurementRoutes.purchaseReceipts,
            "/api/v1/admin/procurement/purchase-receipts"
        )
        XCTAssertEqual(
            AdminProcurementRoutes.purchaseReceipt("pr/one ?"),
            "/api/v1/admin/procurement/purchase-receipts/pr%2Fone%20%3F"
        )
        XCTAssertEqual(
            AdminProcurementRoutes.purchaseReceiptInventoryEffects("pr/one ?"),
            "/api/v1/admin/procurement/purchase-receipts/pr%2Fone%20%3F/inventory-effects"
        )
        XCTAssertFalse(AdminProcurementRoutes.purchaseReceipts.contains("/business/"))
    }

    func testListQueryUsesOnlySupportedFiltersAndBoundsLimit() {
        let dto = AdminPurchaseReceiptListQuery(
            branchId: " br_1 ",
            supplierId: " sup_1 ",
            purchaseOrderId: " po_1 ",
            status: .confirmed,
            receivedFrom: " 2026-07-01T00:00:00Z ",
            receivedTo: " 2026-07-31T23:59:59Z ",
            limit: 500,
            cursor: " cursor_2 "
        ).toDTO()

        XCTAssertEqual(dto.branchId, "br_1")
        XCTAssertEqual(dto.supplierId, "sup_1")
        XCTAssertEqual(dto.purchaseOrderId, "po_1")
        XCTAssertEqual(dto.status, "CONFIRMED")
        XCTAssertEqual(dto.receivedFrom, "2026-07-01T00:00:00Z")
        XCTAssertEqual(dto.receivedTo, "2026-07-31T23:59:59Z")
        XCTAssertEqual(dto.limit, 100)
        XCTAssertEqual(dto.cursor, "cursor_2")
    }

    func testAllStatusOmitsWireFilterAndLowerBoundsLimit() {
        let dto = AdminPurchaseReceiptListQuery(
            branchId: nil,
            supplierId: nil,
            purchaseOrderId: nil,
            status: .all,
            receivedFrom: nil,
            receivedTo: nil,
            limit: 0,
            cursor: nil
        ).toDTO()

        XCTAssertNil(dto.status)
        XCTAssertEqual(dto.limit, 1)
    }

    func testInventoryEffectPermissionRequiresBothReadCapabilities() {
        XCTAssertTrue(AdminPurchaseReceiptAccess.canView([PermissionCatalog.purchaseReceiptsView]))
        XCTAssertFalse(
            AdminPurchaseReceiptAccess.canViewInventoryEffects([PermissionCatalog.purchaseReceiptsView])
        )
        XCTAssertFalse(
            AdminPurchaseReceiptAccess.canViewInventoryEffects([PermissionCatalog.inventoryView])
        )
        XCTAssertTrue(
            AdminPurchaseReceiptAccess.canViewInventoryEffects([
                PermissionCatalog.purchaseReceiptsView,
                PermissionCatalog.inventoryView
            ])
        )
        XCTAssertTrue(AdminPurchaseReceiptAccess.canViewInventoryEffects([PermissionCatalog.all]))
    }

    func testCanonicalValueReconciliationTokenAndScopeStayStable() {
        XCTAssertEqual(AdminPurchaseReceiptValueStatus.valueReconciled.rawValue, "VALUE_RECONCILED")
        XCTAssertEqual(
            AdminPurchaseReceiptReconciliationScope.quantityValueReconciled.rawValue,
            "QUANTITY_VALUE_RECONCILED"
        )
    }

    func testCostAndAuditPermissionsRemainIndependent() {
        XCTAssertFalse(AdminPurchaseReceiptAccess.canViewCosts([PermissionCatalog.purchaseReceiptsView]))
        XCTAssertTrue(AdminPurchaseReceiptAccess.canViewCosts([PermissionCatalog.purchaseOrdersCostView]))
        XCTAssertFalse(AdminPurchaseReceiptAccess.canViewAudit([PermissionCatalog.purchaseReceiptsView]))
        XCTAssertTrue(AdminPurchaseReceiptAccess.canViewAudit([PermissionCatalog.procurementAuditView]))
    }
}
