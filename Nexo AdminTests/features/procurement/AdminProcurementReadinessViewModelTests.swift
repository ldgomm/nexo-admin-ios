//
//  AdminProcurementReadinessViewModelTests.swift
//  Nexo AdminTests
//
//  Created by José Ruiz on 29/7/26.
//

import XCTest
@testable import Nexo_Admin

@MainActor
class AdminProcurementReadinessViewModelTests: XCTestCase {
    func testLoadUsesActiveBranchAndDefaultCurrency() async {
        let procurement = AdminProcurementTestRepository()
        let viewModel = AdminProcurementReadinessViewModel(
            foundationRepository: AdminFoundationTestRepository.procurementReady(),
            procurementRepository: procurement,
            permissions: AdminProcurementReadinessAccess.requiredPermissions,
            evaluator: AdminProcurementReadinessEvaluator(generatedAt: { Date(timeIntervalSince1970: 0) })
        )

        await viewModel.load()

        guard case .loaded(let report) = viewModel.state else {
            XCTFail("Expected loaded readiness")
            return
        }
        XCTAssertTrue(report.isReady)
        XCTAssertEqual(procurement.requests.count, 1)
        XCTAssertEqual(procurement.requests.first?.currency, "USD")
        XCTAssertEqual(procurement.requests.first?.branchId, "br_1")
    }

    func testMissingReportPermissionFailsBeforeRepositoryCall() async {
        let procurement = AdminProcurementTestRepository()
        let viewModel = AdminProcurementReadinessViewModel(
            foundationRepository: AdminFoundationTestRepository.procurementReady(),
            procurementRepository: procurement,
            permissions: []
        )

        await viewModel.load()

        guard case .failed(let message) = viewModel.state else {
            XCTFail("Expected permission failure")
            return
        }
        XCTAssertTrue(message.contains("permiso"))
        XCTAssertTrue(procurement.requests.isEmpty)
    }

    func testRepositoryFailureIsPresentedWithoutPartialReadiness() async {
        let procurement = AdminProcurementTestRepository(
            result: .failure(AppError.transport("sin conexión"))
        )
        let viewModel = AdminProcurementReadinessViewModel(
            foundationRepository: AdminFoundationTestRepository.procurementReady(),
            procurementRepository: procurement,
            permissions: AdminProcurementReadinessAccess.requiredPermissions
        )

        await viewModel.refresh()

        guard case .failed = viewModel.state else {
            XCTFail("Expected failed state")
            return
        }
        XCTAssertNil(viewModel.report)
    }
}
