//
//  AdminOperationsViewModelTests.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import XCTest
@testable import Nexo_Admin

@MainActor
final class AdminOperationsViewModelTests: XCTestCase {
    func testLoadInitialLoadsReportsCashAndAuditWhenPermissionsAllow() async {
        let viewModel = AdminOperationsViewModel(
            repository: MockAdminOperationsRepository(),
            permissions: [PermissionCatalog.all]
        )

        await viewModel.loadInitial()

        XCTAssertNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.todayReport?.sales.saleCount, 24)
        XCTAssertEqual(viewModel.currentCashSession?.id, "cash_1")
        XCTAssertEqual(viewModel.cashSessions.count, 2)
        XCTAssertEqual(viewModel.auditLogs.count, 2)
        XCTAssertEqual(viewModel.diagnostics?.status, "healthy")
    }

    func testWithoutPermissionsDoesNotLoad() async {
        let viewModel = AdminOperationsViewModel(
            repository: MockAdminOperationsRepository(),
            permissions: []
        )

        await viewModel.loadInitial()

        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertNil(viewModel.todayReport)
        XCTAssertTrue(viewModel.cashSessions.isEmpty)
    }

    func testAuditQuickFilterUpdatesFilter() {
        let viewModel = AdminOperationsViewModel(
            repository: MockAdminOperationsRepository(),
            permissions: [PermissionCatalog.auditView]
        )

        viewModel.applyAuditQuickFilter(surface: "catalog")

        XCTAssertEqual(viewModel.auditFilter.surface, "catalog")
    }
}
