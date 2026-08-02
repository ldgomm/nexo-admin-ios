//
//  AdminPayableViewModelTests.swift
//  Nexo AdminTests
//
//  Created by José Ruiz on 29/7/26.
//
//  27R.N — Payable permissions, filters, ageing, pagination and detail refresh.
//

import Foundation
import XCTest
@testable import Nexo_Admin

@MainActor
class AdminPayableViewModelTests: XCTestCase {
    func testMissingPermissionsBlockAllRepositoryCalls() async {
        let repository = AdminProcurementTestRepository()
        let viewModel = makeViewModel(repository, permissions: [])

        await viewModel.refresh()

        XCTAssertTrue(repository.payableListQueries.isEmpty)
        XCTAssertTrue(repository.payableAgingQueries.isEmpty)
        XCTAssertTrue(viewModel.payables.isEmpty)
        XCTAssertNil(viewModel.aging)
        XCTAssertNotNil(viewModel.errorMessage)
    }

    func testRefreshSendsExactListAndAgingQueries() async {
        let repository = AdminProcurementTestRepository()
        let viewModel = makeViewModel(
            repository,
            permissions: [PermissionCatalog.payablesView, PermissionCatalog.payablesAgingView]
        )
        viewModel.branchId = " br_1 "
        viewModel.supplierId = " sup_1 "
        viewModel.dueFrom = "2026-07-01"
        viewModel.dueTo = "2026-07-31"
        viewModel.currency = " usd "
        viewModel.asOf = "2026-07-24"
        viewModel.statusFilter = .outstanding

        await viewModel.refresh()

        XCTAssertEqual(repository.payableListQueries.count, 1)
        let list = repository.payableListQueries[0]
        XCTAssertEqual(list.branchId, "br_1")
        XCTAssertEqual(list.supplierId, "sup_1")
        XCTAssertEqual(list.status, .outstanding)
        XCTAssertEqual(list.dueFrom, "2026-07-01")
        XCTAssertEqual(list.dueTo, "2026-07-31")
        XCTAssertEqual(list.currency, "USD")
        XCTAssertEqual(list.asOf, "2026-07-24")
        XCTAssertEqual(list.limit, 50)
        XCTAssertNil(list.cursor)

        XCTAssertEqual(repository.payableAgingQueries.count, 1)
        let aging = repository.payableAgingQueries[0]
        XCTAssertEqual(aging.branchId, "br_1")
        XCTAssertEqual(aging.supplierId, "sup_1")
        XCTAssertEqual(aging.currency, "USD")
        XCTAssertEqual(aging.asOf, "2026-07-24")
    }

    func testListAndAgingPermissionsRemainIndependent() async {
        let listRepository = AdminProcurementTestRepository()
        let listViewModel = makeViewModel(
            listRepository,
            permissions: [PermissionCatalog.payablesView]
        )
        await listViewModel.refresh()

        XCTAssertEqual(listRepository.payableListQueries.count, 1)
        XCTAssertTrue(listRepository.payableAgingQueries.isEmpty)
        XCTAssertEqual(listViewModel.payables.map(\.id), ["pbl_1"])
        XCTAssertNil(listViewModel.aging)
        XCTAssertTrue(listRepository.supplierDetailIds.isEmpty)
        XCTAssertTrue(listRepository.supplierDocumentDetailIds.isEmpty)

        let agingRepository = AdminProcurementTestRepository()
        let agingViewModel = makeViewModel(
            agingRepository,
            permissions: [PermissionCatalog.payablesAgingView]
        )
        await agingViewModel.refresh()

        XCTAssertTrue(agingRepository.payableListQueries.isEmpty)
        XCTAssertEqual(agingRepository.payableAgingQueries.count, 1)
        XCTAssertTrue(agingViewModel.payables.isEmpty)
        XCTAssertNotNil(agingViewModel.aging)
    }

    func testInvalidDateRangeStopsBeforeListAndAgingCalls() async {
        let repository = AdminProcurementTestRepository()
        let viewModel = makeViewModel(
            repository,
            permissions: [PermissionCatalog.payablesView, PermissionCatalog.payablesAgingView]
        )
        viewModel.dueFrom = "2026-08-01"
        viewModel.dueTo = "2026-07-31"

        await viewModel.refresh()

        XCTAssertTrue(repository.payableListQueries.isEmpty)
        XCTAssertTrue(repository.payableAgingQueries.isEmpty)
        XCTAssertNotNil(viewModel.errorMessage)
    }

    func testPaginationUsesBackendCursorAndDeduplicatesPayables() async {
        let repository = AdminProcurementTestRepository()
        let first = AdminPayable.fixture(id: "pbl_1")
        let second = AdminPayable.fixture(id: "pbl_2", sourceId: "sdoc_2")
        repository.payablePageResults = [
            .success(AdminPayablePage(
                payables: [first],
                nextCursor: "cursor_2",
                hasMore: true,
                asOf: "2026-07-24"
            )),
            .success(AdminPayablePage(
                payables: [first, second],
                nextCursor: nil,
                hasMore: false,
                asOf: "2026-07-24"
            ))
        ]
        let viewModel = makeViewModel(repository, permissions: [PermissionCatalog.payablesView])

        await viewModel.refresh()
        await viewModel.loadNextPage()

        XCTAssertEqual(viewModel.payables.map(\.id), ["pbl_1", "pbl_2"])
        XCTAssertEqual(repository.payableListQueries.last?.cursor, "cursor_2")
        XCTAssertFalse(viewModel.hasMore)
    }

    func testDetailRefreshUsesListCutoffAndReplacesCanonicalBackendVersion() async {
        let repository = AdminProcurementTestRepository()
        repository.payableDetailResult = .success(
            .fixture(
                settlementStatus: .paid,
                effectiveStatus: .paid,
                originalAmount: "112.00",
                paidAmount: "112.00",
                balance: "0.00",
                version: 3,
                updatedAt: "2026-07-24T16:00:00Z"
            )
        )
        let viewModel = makeViewModel(repository, permissions: [PermissionCatalog.payablesView])
        viewModel.asOf = "2026-07-24"

        await viewModel.refresh()
        await viewModel.refreshDetail(id: "pbl_1")

        XCTAssertEqual(repository.payableDetailRequests.first?.id, "pbl_1")
        XCTAssertEqual(repository.payableDetailRequests.first?.asOf, "2026-07-24")
        XCTAssertEqual(viewModel.payablePresentation(id: "pbl_1")?.payable.effectiveStatus, .paid)
        XCTAssertEqual(viewModel.payablePresentation(id: "pbl_1")?.payable.version, 3)
        XCTAssertEqual(
            viewModel.payablePresentation(id: "pbl_1")?.payable.balance.amount,
            Decimal(string: "0.00")
        )
    }

    func testMismatchedDetailResponseIsSurfacedAndNotInserted() async {
        let repository = AdminProcurementTestRepository()
        repository.payableDetailResult = .success(.fixture(id: "pbl_other"))
        let viewModel = makeViewModel(repository, permissions: [PermissionCatalog.payablesView])

        await viewModel.refresh()
        let original = viewModel.payablePresentation(id: "pbl_1")
        await viewModel.refreshDetail(id: "pbl_1")

        XCTAssertEqual(viewModel.payablePresentation(id: "pbl_1"), original)
        XCTAssertNil(viewModel.payablePresentation(id: "pbl_other"))
        XCTAssertNotNil(viewModel.detailErrorMessage)
    }

    func testReferenceHydrationRequiresExactPermissionsAndUsesCaches() async {
        let repository = AdminProcurementTestRepository()
        let viewModel = makeViewModel(
            repository,
            permissions: [
                PermissionCatalog.payablesView,
                PermissionCatalog.suppliersView,
                PermissionCatalog.supplierDocumentsView
            ]
        )

        await viewModel.refresh()
        await viewModel.refresh()

        XCTAssertEqual(repository.supplierDetailIds, ["sup_1"])
        XCTAssertEqual(repository.supplierDocumentDetailIds, ["sdoc_1"])
        XCTAssertEqual(viewModel.payablePresentation(id: "pbl_1")?.supplierTitle, "Proveedor Uno")
        XCTAssertEqual(
            viewModel.payablePresentation(id: "pbl_1")?.sourceTitle,
            "FAC-001-001-000000123"
        )
    }

    private func makeViewModel(
        _ repository: AdminProcurementTestRepository,
        permissions: Set<String>
    ) -> AdminPayableViewModel {
        AdminPayableViewModel(repository: repository, permissions: permissions)
    }
}
