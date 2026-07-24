//
//  AdminPurchaseReceiptViewModelTests.swift
//  Nexo AdminTests
//
//  27R.N.4 — Permission, exact filters, pagination and canonical detail loading.
//

import Foundation
import XCTest
@testable import Nexo_Admin

@MainActor
final class AdminPurchaseReceiptViewModelTests: XCTestCase {
    func testMissingReceiptPermissionBlocksRepositoryCall() async {
        let repository = AdminProcurementTestRepository()
        let viewModel = AdminPurchaseReceiptViewModel(repository: repository, permissions: [])

        await viewModel.refresh()

        XCTAssertTrue(repository.purchaseReceiptListQueries.isEmpty)
        XCTAssertTrue(viewModel.receipts.isEmpty)
        XCTAssertNotNil(viewModel.errorMessage)
    }

    func testRefreshSendsExactBackendFilters() async {
        let repository = AdminProcurementTestRepository()
        let viewModel = makeViewModel(repository)
        viewModel.branchId = " br_1 "
        viewModel.supplierId = " sup_1 "
        viewModel.purchaseOrderId = " po_1 "
        viewModel.statusFilter = .confirmed
        viewModel.receivedFrom = "2026-07-01T00:00:00Z"
        viewModel.receivedTo = "2026-07-31T23:59:59Z"

        await viewModel.refresh()

        XCTAssertEqual(repository.purchaseReceiptListQueries.count, 1)
        let query = repository.purchaseReceiptListQueries[0]
        XCTAssertEqual(query.branchId, "br_1")
        XCTAssertEqual(query.supplierId, "sup_1")
        XCTAssertEqual(query.purchaseOrderId, "po_1")
        XCTAssertEqual(query.status, .confirmed)
        XCTAssertEqual(query.receivedFrom, "2026-07-01T00:00:00Z")
        XCTAssertEqual(query.receivedTo, "2026-07-31T23:59:59Z")
        XCTAssertEqual(query.limit, 50)
        XCTAssertNil(query.cursor)
    }

    func testInvalidInstantRangeDoesNotCallBackend() async {
        let repository = AdminProcurementTestRepository()
        let viewModel = makeViewModel(repository)
        viewModel.receivedFrom = "2026-08-01"
        viewModel.receivedTo = "2026-07-31T23:59:59Z"

        await viewModel.refresh()

        XCTAssertTrue(repository.purchaseReceiptListQueries.isEmpty)
        XCTAssertNotNil(viewModel.errorMessage)
    }

    func testPaginationUsesBackendCursorAndDeduplicatesReceipts() async {
        let repository = AdminProcurementTestRepository()
        let first = AdminPurchaseReceipt.fixture(id: "pr_1")
        let second = AdminPurchaseReceipt.fixture(id: "pr_2", receiptNumber: "PR-260722-000002")
        repository.purchaseReceiptPageResults = [
            .success(AdminPurchaseReceiptPage(receipts: [first], nextCursor: "cursor_2", hasMore: true)),
            .success(AdminPurchaseReceiptPage(receipts: [first, second], nextCursor: nil, hasMore: false))
        ]
        let viewModel = makeViewModel(repository)

        await viewModel.refresh()
        await viewModel.loadNextPage()

        XCTAssertEqual(viewModel.receipts.map(\.id), ["pr_1", "pr_2"])
        XCTAssertEqual(repository.purchaseReceiptListQueries.last?.cursor, "cursor_2")
        XCTAssertFalse(viewModel.hasMore)
    }

    func testMissingInventoryPermissionDoesNotIssueEffectRequest() async {
        let repository = AdminProcurementTestRepository()
        let viewModel = AdminPurchaseReceiptViewModel(
            repository: repository,
            permissions: [PermissionCatalog.purchaseReceiptsView]
        )

        await viewModel.refresh()
        await viewModel.refreshDetail(id: "pr_1")

        XCTAssertEqual(repository.purchaseReceiptDetailIds, ["pr_1"])
        XCTAssertTrue(repository.purchaseReceiptEffectIds.isEmpty)
        XCTAssertNotNil(viewModel.effectError(receiptId: "pr_1"))
    }

    func testDetailLoadsReceiptEffectAndLinkedOrderFromCanonicalRepositories() async {
        let repository = AdminProcurementTestRepository()
        let viewModel = makeViewModel(repository)

        await viewModel.refresh()
        await viewModel.refreshDetail(id: "pr_1")

        XCTAssertEqual(repository.purchaseReceiptDetailIds, ["pr_1"])
        XCTAssertEqual(repository.purchaseReceiptEffectIds, ["pr_1"])
        XCTAssertEqual(repository.purchaseOrderDetailIds, ["po_1"])
        XCTAssertEqual(viewModel.inventoryEffects(receiptId: "pr_1")?.reconciliationScope, .quantityReconciled)
        XCTAssertEqual(viewModel.linkedPurchaseOrder(receiptId: "pr_1")?.orderNumber, "PO-260721-000001")
    }

    func testMismatchedEffectResponseIsSurfacedAndNotRendered() async {
        let repository = AdminProcurementTestRepository()
        repository.purchaseReceiptEffectResult = .success(.fixture(receiptId: "pr_other"))
        let viewModel = makeViewModel(repository)

        await viewModel.refresh()
        await viewModel.refreshDetail(id: "pr_1")

        XCTAssertNil(viewModel.inventoryEffects(receiptId: "pr_1"))
        XCTAssertNotNil(viewModel.effectError(receiptId: "pr_1"))
    }

    func testOrderNavigationPreloadsOnlySupportedPurchaseOrderFilter() async {
        let repository = AdminProcurementTestRepository()
        let viewModel = AdminPurchaseReceiptViewModel(
            repository: repository,
            permissions: fullPermissions,
            purchaseOrderId: "po_1"
        )

        await viewModel.refresh()

        XCTAssertEqual(repository.purchaseReceiptListQueries.first?.purchaseOrderId, "po_1")
    }

    private func makeViewModel(
        _ repository: AdminProcurementTestRepository
    ) -> AdminPurchaseReceiptViewModel {
        AdminPurchaseReceiptViewModel(
            repository: repository,
            permissions: fullPermissions
        )
    }

    private var fullPermissions: Set<String> {
        [
            PermissionCatalog.purchaseReceiptsView,
            PermissionCatalog.inventoryView,
            PermissionCatalog.purchaseOrdersView,
            PermissionCatalog.purchaseOrdersCostView,
            PermissionCatalog.procurementAuditView
        ]
    }
}
