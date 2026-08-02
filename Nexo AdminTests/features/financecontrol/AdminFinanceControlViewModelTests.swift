//
//  AdminFinanceControlViewModelTests.swift
//  Nexo AdminTests
//
//  Created by José Ruiz on 29/7/26.
//

import XCTest
@testable import Nexo_Admin

@MainActor
class AdminFinanceControlViewModelTests: XCTestCase {
    func testLoadsValidatedBackendSnapshot() async {
        let expected = AdminFinanceControlTestFixtures.snapshot()
        let repository = AdminFinanceControlRepositoryStub(
            snapshotResult: .success(expected)
        )
        let viewModel = makeViewModel(repository: repository)

        await viewModel.load()

        XCTAssertEqual(viewModel.snapshot, expected)
        XCTAssertEqual(repository.loadCount, 1)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testMissingPermissionStopsBeforeRepository() async {
        let repository = AdminFinanceControlRepositoryStub(
            snapshotResult: .success(
                AdminFinanceControlTestFixtures.snapshot()
            )
        )
        let viewModel = AdminFinanceControlViewModel(
            effectivePermissions: [],
            repository: repository
        )

        await viewModel.load()

        XCTAssertEqual(repository.loadCount, 0)
        XCTAssertNil(viewModel.snapshot)
        XCTAssertEqual(
            viewModel.errorMessage,
            "No tienes permiso para consultar este control financiero."
        )
    }

    func testUnsafeSnapshotIsNotPresented() async {
        let repository = AdminFinanceControlRepositoryStub(
            snapshotResult: .success(
                AdminFinanceControlTestFixtures.snapshot(
                    authoritativeAccounting: true
                )
            )
        )
        let viewModel = makeViewModel(repository: repository)

        await viewModel.load()

        XCTAssertNil(viewModel.snapshot)
        XCTAssertEqual(
            viewModel.errorMessage,
            "No fue posible cargar el control financiero de forma segura."
        )
    }

    func testDeferredRuntimeFailsClosed() async {
        let repository = AdminFinanceControlRepositoryStub(
            snapshotResult: .failure(.runtimeEndpointUnavailable)
        )
        let viewModel = makeViewModel(repository: repository)

        await viewModel.load()

        XCTAssertNil(viewModel.snapshot)
        XCTAssertTrue(
            viewModel.errorMessage?.contains("cierre runtime de 28R") == true
        )
    }

    func testReviewsImportWithPermissionCapabilityAndReason() async {
        let repository = AdminFinanceControlRepositoryStub(
            snapshotResult: .success(
                AdminFinanceControlTestFixtures.snapshot()
            )
        )
        let viewModel = makeViewModel(repository: repository)
        await viewModel.load()

        await viewModel.reviewImportBatch(
            id: "import_1",
            reason: "Reviewed."
        )

        XCTAssertEqual(repository.reviewedImportBatches.count, 1)
        XCTAssertEqual(
            repository.reviewedImportBatches.first?.0,
            "import_1"
        )
        XCTAssertEqual(
            viewModel.lastActionReceipt,
            AdminFinanceControlTestFixtures.receipt
        )
    }

    func testBlankReviewReasonNeverCallsRepository() async {
        let repository = AdminFinanceControlRepositoryStub(
            snapshotResult: .success(
                AdminFinanceControlTestFixtures.snapshot()
            )
        )
        let viewModel = makeViewModel(repository: repository)
        await viewModel.load()

        await viewModel.reviewReconciliationException(
            id: "exception_1",
            reason: " "
        )

        XCTAssertTrue(repository.reviewedExceptions.isEmpty)
        XCTAssertNotNil(viewModel.errorMessage)
    }

    func testApprovedCutoverProducesEvidenceReceipt() async {
        let repository = AdminFinanceControlRepositoryStub(
            snapshotResult: .success(
                AdminFinanceControlTestFixtures.snapshot()
            )
        )
        let viewModel = makeViewModel(repository: repository)
        await viewModel.load()

        await viewModel.approveCutover(reason: "Reviewed and approved.")

        XCTAssertEqual(repository.cutoverReasons, ["Reviewed and approved."])
        XCTAssertEqual(
            viewModel.lastActionReceipt?.evidenceId,
            "evidence_action_1"
        )
    }

    func testBlockedCutoverNeverCallsRepository() async {
        let repository = AdminFinanceControlRepositoryStub(
            snapshotResult: .success(
                AdminFinanceControlTestFixtures.snapshot(
                    gapCount: 1
                )
            )
        )
        let viewModel = makeViewModel(repository: repository)
        await viewModel.load()

        await viewModel.approveCutover(reason: "Reviewed.")

        XCTAssertTrue(repository.cutoverReasons.isEmpty)
        XCTAssertTrue(viewModel.errorMessage?.contains("bloqueado") == true)
    }

    private func makeViewModel(
        repository: AdminFinanceControlRepositoryStub
    ) -> AdminFinanceControlViewModel {
        AdminFinanceControlViewModel(
            effectivePermissions: ["*"],
            repository: repository
        )
    }
}
