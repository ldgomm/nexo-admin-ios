//
//  AdminSupplierDocumentViewModelTests.swift
//  Nexo AdminTests
//
//  Created by José Ruiz on 29/7/26.
//
//  27R.N — Permission, filters, pagination and detail refresh.
//

import Foundation
import XCTest
@testable import Nexo_Admin

@MainActor
class AdminSupplierDocumentViewModelTests: XCTestCase {
    func testMissingViewPermissionBlocksRepositoryCall() async {
        let repository = AdminProcurementTestRepository()
        let viewModel = AdminSupplierDocumentViewModel(repository: repository, permissions: [])

        await viewModel.refresh()

        XCTAssertTrue(repository.supplierDocumentListQueries.isEmpty)
        XCTAssertTrue(viewModel.supplierDocuments.isEmpty)
        XCTAssertNotNil(viewModel.errorMessage)
    }

    func testRefreshSendsExactBackendFilters() async {
        let repository = AdminProcurementTestRepository()
        let viewModel = makeViewModel(repository)
        viewModel.query = " FAC-001 "
        viewModel.branchId = " br_1 "
        viewModel.supplierId = " sup_1 "
        viewModel.documentTypeFilter = .supplierInvoice
        viewModel.statusFilter = .confirmed
        viewModel.documentDateFrom = "2026-07-01"
        viewModel.documentDateTo = "2026-07-31"
        viewModel.dueDateFrom = "2026-08-01"
        viewModel.dueDateTo = "2026-08-31"

        await viewModel.refresh()

        XCTAssertEqual(repository.supplierDocumentListQueries.count, 1)
        let query = repository.supplierDocumentListQueries[0]
        XCTAssertEqual(query.query, "FAC-001")
        XCTAssertEqual(query.branchId, "br_1")
        XCTAssertEqual(query.supplierId, "sup_1")
        XCTAssertEqual(query.documentType, .supplierInvoice)
        XCTAssertEqual(query.status, .confirmed)
        XCTAssertEqual(query.documentDateFrom, "2026-07-01")
        XCTAssertEqual(query.documentDateTo, "2026-07-31")
        XCTAssertEqual(query.dueDateFrom, "2026-08-01")
        XCTAssertEqual(query.dueDateTo, "2026-08-31")
        XCTAssertEqual(query.limit, 50)
        XCTAssertNil(query.cursor)
    }

    func testInvalidDateRangeDoesNotCallBackend() async {
        let repository = AdminProcurementTestRepository()
        let viewModel = makeViewModel(repository)
        viewModel.documentDateFrom = "2026-08-01"
        viewModel.documentDateTo = "2026-07-31"

        await viewModel.refresh()

        XCTAssertTrue(repository.supplierDocumentListQueries.isEmpty)
        XCTAssertNotNil(viewModel.errorMessage)
    }

    func testPaginationUsesBackendCursorAndDeduplicatesDocuments() async {
        let repository = AdminProcurementTestRepository()
        let first = AdminSupplierDocument.fixture(id: "sdoc_1")
        let second = AdminSupplierDocument.fixture(
            id: "sdoc_2",
            documentNumber: "FAC-001-001-000000124"
        )
        repository.supplierDocumentPageResults = [
            .success(AdminSupplierDocumentPage(
                supplierDocuments: [first],
                nextCursor: "cursor_2",
                hasMore: true
            )),
            .success(AdminSupplierDocumentPage(
                supplierDocuments: [first, second],
                nextCursor: nil,
                hasMore: false
            ))
        ]
        let viewModel = makeViewModel(repository)

        await viewModel.refresh()
        await viewModel.loadNextPage()

        XCTAssertEqual(viewModel.supplierDocuments.map(\.id), ["sdoc_1", "sdoc_2"])
        XCTAssertEqual(repository.supplierDocumentListQueries.last?.cursor, "cursor_2")
        XCTAssertFalse(viewModel.hasMore)
    }

    func testDetailRefreshReplacesDocumentWithCanonicalBackendVersion() async {
        let repository = AdminProcurementTestRepository()
        repository.supplierDocumentDetailResult = .success(
            .fixture(
                status: .cancelled,
                version: 4,
                updatedAt: "2026-07-23T16:00:00Z"
            )
        )
        let viewModel = makeViewModel(repository)

        await viewModel.refresh()
        await viewModel.refreshDetail(id: "sdoc_1")

        XCTAssertEqual(repository.supplierDocumentDetailIds, ["sdoc_1"])
        XCTAssertEqual(viewModel.supplierDocument(id: "sdoc_1")?.status, .cancelled)
        XCTAssertEqual(viewModel.supplierDocument(id: "sdoc_1")?.version, 4)
        XCTAssertEqual(viewModel.supplierDocument(id: "sdoc_1")?.updatedAt, "2026-07-23T16:00:00Z")
    }

    func testMismatchedDetailResponseIsSurfacedAndNotInserted() async {
        let repository = AdminProcurementTestRepository()
        repository.supplierDocumentDetailResult = .success(.fixture(id: "sdoc_other"))
        let viewModel = makeViewModel(repository)

        await viewModel.refresh()
        let original = viewModel.supplierDocument(id: "sdoc_1")
        await viewModel.refreshDetail(id: "sdoc_1")

        XCTAssertEqual(viewModel.supplierDocument(id: "sdoc_1"), original)
        XCTAssertNil(viewModel.supplierDocument(id: "sdoc_other"))
        XCTAssertNotNil(viewModel.detailErrorMessage)
    }

    private func makeViewModel(_ repository: AdminProcurementTestRepository) -> AdminSupplierDocumentViewModel {
        AdminSupplierDocumentViewModel(
            repository: repository,
            permissions: [PermissionCatalog.supplierDocumentsView]
        )
    }
}
