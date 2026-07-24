//
//  AdminPurchaseOrderViewModelTests.swift
//  Nexo AdminTests
//
//  27R.N.3 — Permission, backend filters, pagination and detail refresh.
//

import Foundation
import XCTest
@testable import Nexo_Admin

@MainActor
final class AdminPurchaseOrderViewModelTests: XCTestCase {
    func testMissingViewPermissionBlocksRepositoryCall() async {
        let repository = AdminProcurementTestRepository()
        let viewModel = AdminPurchaseOrderViewModel(repository: repository, permissions: [])

        await viewModel.refresh()

        XCTAssertTrue(repository.purchaseOrderListQueries.isEmpty)
        XCTAssertTrue(viewModel.purchaseOrders.isEmpty)
        XCTAssertNotNil(viewModel.errorMessage)
    }

    func testRefreshSendsExactBackendFilters() async {
        let repository = AdminProcurementTestRepository()
        let viewModel = makeViewModel(repository)
        viewModel.query = " PO-260721 "
        viewModel.branchId = " br_1 "
        viewModel.supplierId = " sup_1 "
        viewModel.statusFilter = .sent
        viewModel.expectedFrom = "2026-07-01"
        viewModel.expectedTo = "2026-07-31"

        await viewModel.refresh()

        XCTAssertEqual(repository.purchaseOrderListQueries.count, 1)
        let query = repository.purchaseOrderListQueries[0]
        XCTAssertEqual(query.query, "PO-260721")
        XCTAssertEqual(query.branchId, "br_1")
        XCTAssertEqual(query.supplierId, "sup_1")
        XCTAssertEqual(query.status, .sent)
        XCTAssertEqual(query.expectedFrom, "2026-07-01")
        XCTAssertEqual(query.expectedTo, "2026-07-31")
        XCTAssertEqual(query.limit, 50)
        XCTAssertNil(query.cursor)
    }

    func testInvalidDateRangeDoesNotCallBackend() async {
        let repository = AdminProcurementTestRepository()
        let viewModel = makeViewModel(repository)
        viewModel.expectedFrom = "2026-08-01"
        viewModel.expectedTo = "2026-07-31"

        await viewModel.refresh()

        XCTAssertTrue(repository.purchaseOrderListQueries.isEmpty)
        XCTAssertNotNil(viewModel.errorMessage)
    }

    func testPaginationUsesBackendCursorAndDeduplicatesOrders() async {
        let repository = AdminProcurementTestRepository()
        let first = AdminPurchaseOrder.fixture(id: "po_1")
        let second = AdminPurchaseOrder.fixture(id: "po_2", orderNumber: "PO-260721-000002")
        repository.purchaseOrderPageResults = [
            .success(AdminPurchaseOrderPage(purchaseOrders: [first], nextCursor: "cursor_2", hasMore: true)),
            .success(AdminPurchaseOrderPage(purchaseOrders: [first, second], nextCursor: nil, hasMore: false))
        ]
        let viewModel = makeViewModel(repository)

        await viewModel.refresh()
        await viewModel.loadNextPage()

        XCTAssertEqual(viewModel.purchaseOrders.map(\.id), ["po_1", "po_2"])
        XCTAssertEqual(repository.purchaseOrderListQueries.last?.cursor, "cursor_2")
        XCTAssertFalse(viewModel.hasMore)
    }

    func testDetailRefreshReplacesOrderWithCanonicalBackendVersion() async {
        let repository = AdminProcurementTestRepository()
        repository.purchaseOrderDetailResult = .success(
            .fixture(status: .received, version: 5, updatedAt: "2026-07-21T15:00:00Z")
        )
        let viewModel = makeViewModel(repository)

        await viewModel.refresh()
        await viewModel.refreshDetail(id: "po_1")

        XCTAssertEqual(repository.purchaseOrderDetailIds, ["po_1"])
        XCTAssertEqual(viewModel.order(id: "po_1")?.status, .received)
        XCTAssertEqual(viewModel.order(id: "po_1")?.version, 5)
        XCTAssertEqual(viewModel.order(id: "po_1")?.updatedAt, "2026-07-21T15:00:00Z")
    }

    private func makeViewModel(_ repository: AdminProcurementTestRepository) -> AdminPurchaseOrderViewModel {
        AdminPurchaseOrderViewModel(
            repository: repository,
            permissions: [PermissionCatalog.purchaseOrdersView, PermissionCatalog.purchaseOrdersCostView]
        )
    }
}
