//
//  AdminSupplierPaymentViewModelTests.swift
//  Nexo AdminTests
//
//  Created by José Ruiz on 29/7/26.
//
//  27R.N — Supplier-payment permissions, filters, references and idempotent void.
//

import Foundation
import XCTest
@testable import Nexo_Admin

@MainActor
class AdminSupplierPaymentViewModelTests: XCTestCase {
    func testMissingViewPermissionBlocksRepositoryCalls() async {
        let repository = AdminProcurementTestRepository()
        let viewModel = makeViewModel(repository, permissions: [])

        await viewModel.refresh()

        XCTAssertTrue(repository.supplierPaymentListQueries.isEmpty)
        XCTAssertTrue(viewModel.supplierPayments.isEmpty)
        XCTAssertNotNil(viewModel.errorMessage)
    }

    func testRefreshSendsExactNormalizedFiltersIncludingSensitiveMethod() async {
        let repository = AdminProcurementTestRepository()
        let viewModel = makeViewModel(
            repository,
            permissions: [
                PermissionCatalog.supplierPaymentsView,
                PermissionCatalog.supplierPaymentsSensitiveView
            ]
        )
        viewModel.branchId = " br_1 "
        viewModel.supplierId = " sup_1 "
        viewModel.paymentFrom = " 2026-07-01 "
        viewModel.paymentTo = " 2026-07-31 "
        viewModel.query = " SP-202607 "
        viewModel.statusFilter = .recorded
        viewModel.methodFilter = .bankTransfer

        await viewModel.refresh()

        XCTAssertEqual(repository.supplierPaymentListQueries.count, 1)
        let query = repository.supplierPaymentListQueries[0]
        XCTAssertEqual(query.branchId, "br_1")
        XCTAssertEqual(query.supplierId, "sup_1")
        XCTAssertEqual(query.paymentFrom, "2026-07-01")
        XCTAssertEqual(query.paymentTo, "2026-07-31")
        XCTAssertEqual(query.query, "SP-202607")
        XCTAssertEqual(query.status, .recorded)
        XCTAssertEqual(query.method, .bankTransfer)
        XCTAssertEqual(query.limit, 50)
        XCTAssertNil(query.cursor)
    }

    func testMethodFilterIsNotSentWithoutSensitivePermission() async {
        let repository = AdminProcurementTestRepository()
        let viewModel = makeViewModel(
            repository,
            permissions: [PermissionCatalog.supplierPaymentsView]
        )
        viewModel.methodFilter = .card

        await viewModel.refresh()

        XCTAssertEqual(repository.supplierPaymentListQueries.first?.method, .all)
    }

    func testInvalidPaymentDateRangeStopsBeforeRepositoryCall() async {
        let repository = AdminProcurementTestRepository()
        let viewModel = makeViewModel(
            repository,
            permissions: [PermissionCatalog.supplierPaymentsView]
        )
        viewModel.paymentFrom = "2026-08-01"
        viewModel.paymentTo = "2026-07-31"

        await viewModel.refresh()

        XCTAssertTrue(repository.supplierPaymentListQueries.isEmpty)
        XCTAssertNotNil(viewModel.errorMessage)
    }

    func testPaginationUsesBackendCursorAndDeduplicatesPayments() async {
        let repository = AdminProcurementTestRepository()
        let first = AdminSupplierPayment.fixture()
        let second = AdminSupplierPayment.fixture(
            id: "spay_2",
            paymentNumber: "SP-202607-000002"
        )
        repository.supplierPaymentPageResults = [
            .success(AdminSupplierPaymentPage(
                supplierPayments: [first],
                nextCursor: "cursor_2",
                hasMore: true
            )),
            .success(AdminSupplierPaymentPage(
                supplierPayments: [first, second],
                nextCursor: nil,
                hasMore: false
            ))
        ]
        let viewModel = makeViewModel(
            repository,
            permissions: [PermissionCatalog.supplierPaymentsView]
        )

        await viewModel.refresh()
        await viewModel.loadNextPage()

        XCTAssertEqual(viewModel.supplierPayments.map(\.id), ["spay_1", "spay_2"])
        XCTAssertEqual(repository.supplierPaymentListQueries.last?.cursor, "cursor_2")
        XCTAssertFalse(viewModel.hasMore)
    }

    func testSupplierReferenceHydrationRequiresPermissionAndUsesCache() async {
        let repository = AdminProcurementTestRepository()
        let viewModel = makeViewModel(
            repository,
            permissions: [
                PermissionCatalog.supplierPaymentsView,
                PermissionCatalog.suppliersView
            ]
        )

        await viewModel.refresh()
        await viewModel.refresh()

        XCTAssertEqual(repository.supplierDetailIds, ["sup_1"])
        XCTAssertEqual(viewModel.supplierPayments.first?.supplierTitle, "Proveedor Uno")
    }

    func testDetailHydratesPayableAndSupplierDocumentReferencesWithExactPermissions() async {
        let repository = AdminProcurementTestRepository()
        let viewModel = makeViewModel(
            repository,
            permissions: [
                PermissionCatalog.supplierPaymentsView,
                PermissionCatalog.suppliersView,
                PermissionCatalog.payablesView,
                PermissionCatalog.supplierDocumentsView
            ]
        )

        await viewModel.refresh()
        await viewModel.refreshDetail(id: "spay_1")
        await viewModel.refreshDetail(id: "spay_1")

        XCTAssertEqual(repository.supplierPaymentDetailIds, ["spay_1", "spay_1"])
        XCTAssertEqual(repository.payableDetailRequests.map { $0.id }, ["pbl_1"])
        XCTAssertEqual(repository.supplierDocumentDetailIds, ["sdoc_1"])
        let allocation = viewModel.paymentPresentation(id: "spay_1")!.payment.allocations[0]
        XCTAssertEqual(
            viewModel.payableReferenceTitle(for: allocation, index: 0),
            "Documento FAC-001-001-000000123"
        )
    }

    func testVoidRequiresPermissionRecordedStateAndReasonBeforeRepositoryCall() async {
        let missingPermissionRepository = AdminProcurementTestRepository()
        let missingPermissionViewModel = makeViewModel(
            missingPermissionRepository,
            permissions: [PermissionCatalog.supplierPaymentsView]
        )
        await missingPermissionViewModel.refresh()
        _ = await missingPermissionViewModel.voidPayment(id: "spay_1", reason: "Duplicado")
        XCTAssertTrue(missingPermissionRepository.supplierPaymentVoidRequests.isEmpty)

        let missingReasonRepository = AdminProcurementTestRepository()
        let missingReasonViewModel = makeViewModel(
            missingReasonRepository,
            permissions: [
                PermissionCatalog.supplierPaymentsView,
                PermissionCatalog.supplierPaymentsVoid
            ]
        )
        await missingReasonViewModel.refresh()
        _ = await missingReasonViewModel.voidPayment(id: "spay_1", reason: "   ")
        XCTAssertTrue(missingReasonRepository.supplierPaymentVoidRequests.isEmpty)

        let wrongStateRepository = AdminProcurementTestRepository()
        wrongStateRepository.supplierPaymentPageResults = [
            .success(AdminSupplierPaymentPage(
                supplierPayments: [.fixture(status: .voided, version: 3)],
                nextCursor: nil,
                hasMore: false
            ))
        ]
        let wrongStateViewModel = makeViewModel(
            wrongStateRepository,
            permissions: [
                PermissionCatalog.supplierPaymentsView,
                PermissionCatalog.supplierPaymentsVoid
            ]
        )
        await wrongStateViewModel.refresh()
        _ = await wrongStateViewModel.voidPayment(id: "spay_1", reason: "Duplicado")
        XCTAssertTrue(wrongStateRepository.supplierPaymentVoidRequests.isEmpty)
    }

    func testVoidRetriesWithSameIdempotencyKeyAndUsesCanonicalServerResult() async {
        let repository = AdminProcurementTestRepository()
        repository.supplierPaymentVoidResults = [
            .failure(SupplierPaymentTestError.transient),
            .success(AdminSupplierPaymentMutationResult(
                supplierPayment: .fixture(status: .voided, version: 3),
                requestId: "req_void",
                idempotencyReplayed: true
            ))
        ]
        let viewModel = makeViewModel(
            repository,
            permissions: [
                PermissionCatalog.supplierPaymentsView,
                PermissionCatalog.supplierPaymentsVoid
            ]
        )
        await viewModel.refresh()

        let firstAttempt = await viewModel.voidPayment(id: "spay_1", reason: "  Pago duplicado  ")
        XCTAssertNil(firstAttempt)
        let result = await viewModel.voidPayment(id: "spay_1", reason: "  Pago duplicado  ")

        XCTAssertEqual(repository.supplierPaymentVoidRequests.count, 2)
        XCTAssertEqual(repository.supplierPaymentVoidRequests[0].id, "spay_1")
        XCTAssertEqual(repository.supplierPaymentVoidRequests[0].input.expectedVersion, 2)
        XCTAssertEqual(repository.supplierPaymentVoidRequests[0].input.reason, "Pago duplicado")
        XCTAssertEqual(
            repository.supplierPaymentVoidRequests[0].input.idempotencyKey,
            repository.supplierPaymentVoidRequests[1].input.idempotencyKey
        )
        XCTAssertEqual(result?.status, .voided)
        XCTAssertEqual(viewModel.paymentPresentation(id: "spay_1")?.payment.version, 3)
        XCTAssertNotNil(viewModel.detailInfoMessage)
    }

    func testChangedVoidIntentUsesANewIdempotencyKey() async {
        let repository = AdminProcurementTestRepository()
        repository.supplierPaymentVoidResults = [
            .failure(SupplierPaymentTestError.transient),
            .success(AdminSupplierPaymentMutationResult(
                supplierPayment: .fixture(status: .voided, version: 3),
                requestId: "req_void_changed",
                idempotencyReplayed: false
            ))
        ]
        let viewModel = makeViewModel(
            repository,
            permissions: [
                PermissionCatalog.supplierPaymentsView,
                PermissionCatalog.supplierPaymentsVoid
            ]
        )
        await viewModel.refresh()

        _ = await viewModel.voidPayment(id: "spay_1", reason: "Primer motivo")
        _ = await viewModel.voidPayment(id: "spay_1", reason: "Segundo motivo")

        XCTAssertEqual(repository.supplierPaymentVoidRequests.count, 2)
        XCTAssertNotEqual(
            repository.supplierPaymentVoidRequests[0].input.idempotencyKey,
            repository.supplierPaymentVoidRequests[1].input.idempotencyKey
        )
    }

    func testVoidedPaymentLeavesRecordedFilterButRemainsAvailableInDetail() async {
        let repository = AdminProcurementTestRepository()
        let viewModel = makeViewModel(
            repository,
            permissions: [
                PermissionCatalog.supplierPaymentsView,
                PermissionCatalog.supplierPaymentsVoid
            ]
        )
        viewModel.statusFilter = .recorded
        await viewModel.refresh()
        await viewModel.refreshDetail(id: "spay_1")

        _ = await viewModel.voidPayment(id: "spay_1", reason: "Pago duplicado")

        XCTAssertTrue(viewModel.supplierPayments.isEmpty)
        XCTAssertEqual(viewModel.paymentPresentation(id: "spay_1")?.payment.status, .voided)
    }

    private func makeViewModel(
        _ repository: AdminProcurementTestRepository,
        permissions: Set<String>
    ) -> AdminSupplierPaymentViewModel {
        AdminSupplierPaymentViewModel(repository: repository, permissions: permissions)
    }
}

private enum SupplierPaymentTestError: Error {
    case transient
}
