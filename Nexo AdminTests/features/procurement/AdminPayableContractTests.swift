//
//  AdminPayableContractTests.swift
//  Nexo AdminTests
//
//  Created by José Ruiz on 29/7/26.
//
//  27R.N — Admin payable read-only route, query and permission contract.
//

import XCTest
@testable import Nexo_Admin

class AdminPayableContractTests: XCTestCase {
    func testRoutesStayInsideExactReadOnlyAdminNamespace() {
        XCTAssertEqual(
            AdminProcurementRoutes.payables,
            "/api/v1/admin/procurement/payables"
        )
        XCTAssertEqual(
            AdminProcurementRoutes.payableAging,
            "/api/v1/admin/procurement/payables/aging"
        )
        XCTAssertEqual(
            AdminProcurementRoutes.payable("pbl/one ?"),
            "/api/v1/admin/procurement/payables/pbl%2Fone%20%3F"
        )
        XCTAssertFalse(AdminProcurementRoutes.payables.contains("/business/"))
    }

    func testListQueryUsesOnlyBackendSupportedFiltersAndBoundsLimit() {
        let dto = AdminPayableListQuery(
            branchId: " br_1 ",
            supplierId: " sup_1 ",
            status: .outstanding,
            dueFrom: " 2026-07-01 ",
            dueTo: " 2026-07-31 ",
            currency: " usd ",
            asOf: " 2026-07-24 ",
            limit: 500,
            cursor: " cursor_2 "
        ).toDTO()

        XCTAssertEqual(dto.branchId, "br_1")
        XCTAssertEqual(dto.supplierId, "sup_1")
        XCTAssertEqual(dto.effectiveStatus, "OPEN,PARTIALLY_PAID,OVERDUE")
        XCTAssertEqual(dto.dueFrom, "2026-07-01")
        XCTAssertEqual(dto.dueTo, "2026-07-31")
        XCTAssertEqual(dto.currency, "USD")
        XCTAssertEqual(dto.asOf, "2026-07-24")
        XCTAssertEqual(dto.limit, 100)
        XCTAssertEqual(dto.cursor, "cursor_2")
    }

    func testAllStatusOmitsEffectiveStatusAndLimitIsLowerBounded() {
        let dto = AdminPayableListQuery(
            branchId: nil,
            supplierId: nil,
            status: .all,
            dueFrom: nil,
            dueTo: nil,
            currency: nil,
            asOf: nil,
            limit: 0,
            cursor: nil
        ).toDTO()

        XCTAssertNil(dto.effectiveStatus)
        XCTAssertEqual(dto.limit, 1)
    }

    func testAgingQueryTrimsOnlySupportedScopeAndCutoffFields() {
        let dto = AdminPayableAgingQuery(
            branchId: " br_1 ",
            supplierId: " sup_1 ",
            currency: " usd ",
            asOf: " 2026-07-24 "
        ).toDTO()

        XCTAssertEqual(dto.branchId, "br_1")
        XCTAssertEqual(dto.supplierId, "sup_1")
        XCTAssertEqual(dto.currency, "USD")
        XCTAssertEqual(dto.asOf, "2026-07-24")
    }

    @MainActor
    func testListAndAgingPermissionsRemainIndependentAndDoNotImplyAudit() {
        XCTAssertTrue(AdminPayableAccess.canViewList([PermissionCatalog.payablesView]))
        XCTAssertFalse(AdminPayableAccess.canViewAging([PermissionCatalog.payablesView]))
        XCTAssertTrue(AdminPayableAccess.canViewAging([PermissionCatalog.payablesAgingView]))
        XCTAssertFalse(AdminPayableAccess.canViewList([PermissionCatalog.payablesAgingView]))
        XCTAssertTrue(AdminPayableAccess.canEnter([PermissionCatalog.all]))
        XCTAssertFalse(AdminPayableAccess.canEnter([]))

        let viewModel = AdminPayableViewModel(
            repository: AdminProcurementTestRepository(),
            permissions: [PermissionCatalog.payablesView]
        )
        XCTAssertFalse(viewModel.canViewAudit)
    }
}
