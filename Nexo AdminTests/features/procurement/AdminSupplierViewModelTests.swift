//
//  AdminSupplierViewModelTests.swift
//  Nexo AdminTests
//
//  27R.N.2 — Supplier permissions, filtering, pagination and mutations.
//

import XCTest
@testable import Nexo_Admin

@MainActor
final class AdminSupplierViewModelTests: XCTestCase {
    func testRefreshWithoutViewPermissionFailsBeforeRepositoryCall() async {
        let repository = AdminProcurementTestRepository()
        let viewModel = AdminSupplierViewModel(repository: repository, permissions: [])

        await viewModel.refresh()

        XCTAssertTrue(repository.supplierListQueries.isEmpty)
        XCTAssertTrue(viewModel.suppliers.isEmpty)
        XCTAssertNotNil(viewModel.errorMessage)
    }

    func testRefreshForwardsServerFiltersAndExactPageLimit() async {
        let repository = AdminProcurementTestRepository()
        let viewModel = makeViewModel(repository)
        viewModel.query = " proveedor "
        viewModel.category = " insumos "
        viewModel.statusFilter = .blocked

        await viewModel.refresh()

        let query = repository.supplierListQueries.first
        XCTAssertEqual(query?.query, "proveedor")
        XCTAssertEqual(query?.category, "insumos")
        XCTAssertEqual(query?.status, .blocked)
        XCTAssertEqual(query?.limit, 50)
        XCTAssertNil(query?.cursor)
    }

    func testPaginationUsesBackendCursorAndDeduplicatesSuppliers() async {
        let repository = AdminProcurementTestRepository()
        let first = AdminSupplier.fixture(id: "sup_1")
        let second = AdminSupplier.fixture(id: "sup_2", legalName: "Proveedor Dos S.A.")
        repository.supplierPageResults = [
            .success(AdminSupplierPage(suppliers: [first], nextCursor: "cursor_2", hasMore: true)),
            .success(AdminSupplierPage(suppliers: [first, second], nextCursor: nil, hasMore: false))
        ]
        let viewModel = makeViewModel(repository)

        await viewModel.refresh()
        await viewModel.loadNextPage()

        XCTAssertEqual(viewModel.suppliers.map(\.id), ["sup_1", "sup_2"])
        XCTAssertEqual(repository.supplierListQueries.map(\.cursor), [nil, "cursor_2"])
        XCTAssertFalse(viewModel.hasMore)
    }

    func testCreateRejectsIncompleteIdentificationBeforeRepositoryCall() async {
        let repository = AdminProcurementTestRepository()
        let viewModel = makeViewModel(repository)
        var input = makeInput(expectedVersion: nil)
        input.identificationType = .ruc
        input.identificationNumber = ""

        let saved = await viewModel.create(input)

        XCTAssertFalse(saved)
        XCTAssertTrue(repository.supplierCreateInputs.isEmpty)
        XCTAssertNotNil(viewModel.errorMessage)
    }

    func testCreateForwardsStableIdempotencyKeyAndUsesBackendResult() async {
        let repository = AdminProcurementTestRepository()
        let created = AdminSupplier.fixture(id: "sup_created", version: 1)
        repository.supplierCreateResult = .success(AdminSupplierMutationResult(
            supplier: created,
            requestId: "req_created",
            idempotencyReplayed: false
        ))
        let viewModel = makeViewModel(repository)
        let input = makeInput(expectedVersion: nil, idempotencyKey: "idem_create_1")

        let saved = await viewModel.create(input)

        XCTAssertTrue(saved)
        XCTAssertEqual(repository.supplierCreateInputs.first?.idempotencyKey, "idem_create_1")
        XCTAssertEqual(viewModel.suppliers.first?.id, "sup_created")
        XCTAssertEqual(viewModel.successMessage, "Proveedor creado y auditado.")
    }

    func testUpdateForwardsExactExpectedVersion() async {
        let repository = AdminProcurementTestRepository()
        let updated = AdminSupplier.fixture(legalName: "Proveedor Actualizado S.A.", version: 8)
        repository.supplierUpdateResult = .success(AdminSupplierMutationResult(
            supplier: updated,
            requestId: "req_update",
            idempotencyReplayed: nil
        ))
        let viewModel = makeViewModel(repository)

        let saved = await viewModel.update(
            id: "sup_1",
            input: makeInput(expectedVersion: 7)
        )

        XCTAssertTrue(saved)
        XCTAssertEqual(repository.supplierUpdateRequests.first?.id, "sup_1")
        XCTAssertEqual(repository.supplierUpdateRequests.first?.input.expectedVersion, 7)
        XCTAssertEqual(viewModel.suppliers.first?.version, 8)
    }

    func testStatusChangeRequiresReasonBeforeRepositoryCall() async {
        let repository = AdminProcurementTestRepository()
        let viewModel = makeViewModel(repository)

        let changed = await viewModel.changeStatus(
            id: "sup_1",
            input: AdminSupplierStatusInput(
                status: .blocked,
                reason: "  ",
                expectedVersion: 1,
                idempotencyKey: "idem_status_1"
            )
        )

        XCTAssertFalse(changed)
        XCTAssertTrue(repository.supplierStatusRequests.isEmpty)
    }

    func testStatusChangePreservesIdempotencyAndRemovesNonMatchingFilteredRow() async {
        let repository = AdminProcurementTestRepository()
        let blocked = AdminSupplier.fixture(status: .blocked, version: 2)
        repository.supplierStatusResult = .success(AdminSupplierMutationResult(
            supplier: blocked,
            requestId: "req_status",
            idempotencyReplayed: true
        ))
        let viewModel = makeViewModel(repository)
        viewModel.statusFilter = .active
        await viewModel.refresh()

        let changed = await viewModel.changeStatus(
            id: "sup_1",
            input: AdminSupplierStatusInput(
                status: .blocked,
                reason: "Revisión de riesgo",
                expectedVersion: 1,
                idempotencyKey: "idem_status_1"
            )
        )

        XCTAssertTrue(changed)
        XCTAssertEqual(repository.supplierStatusRequests.first?.input.idempotencyKey, "idem_status_1")
        XCTAssertTrue(viewModel.suppliers.isEmpty)
        XCTAssertTrue(viewModel.successMessage?.contains("ya había sido aplicado") == true)
    }

    private func makeViewModel(_ repository: AdminProcurementTestRepository) -> AdminSupplierViewModel {
        AdminSupplierViewModel(
            repository: repository,
            permissions: [
                PermissionCatalog.suppliersView,
                PermissionCatalog.suppliersSensitiveView,
                PermissionCatalog.suppliersCreate,
                PermissionCatalog.suppliersUpdate,
                PermissionCatalog.suppliersStatusManage
            ]
        )
    }

    private func makeInput(
        expectedVersion: Int64?,
        idempotencyKey: String = "idem_1"
    ) -> AdminSupplierWriteInput {
        AdminSupplierWriteInput(
            legalName: "Proveedor Uno S.A.",
            tradeName: "Proveedor Uno",
            identificationType: .ruc,
            identificationNumber: "1799999999001",
            email: "compras@example.test",
            phone: "022000000",
            address: "Quito",
            categories: ["insumos"],
            contacts: [],
            paymentTermsMode: .netDays,
            netDays: 30,
            paymentTermsLabel: "",
            paymentTermsNotes: "",
            notes: "",
            expectedVersion: expectedVersion,
            idempotencyKey: idempotencyKey
        )
    }
}
