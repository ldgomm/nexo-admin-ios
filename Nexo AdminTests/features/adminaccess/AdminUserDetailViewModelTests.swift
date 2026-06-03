//
//  AdminUserDetailViewModelTests.swift
//  Nexo Admin
//
//  Created by José Ruiz on 2/6/26.
//

import XCTest
@testable import Nexo_Admin

@MainActor
final class AdminUserDetailViewModelTests: XCTestCase {
    func testLoadHydratesUpdateInputAndOnlyAssignableRoles() async {
        let repository = AdminAccessTestRepository()
        let viewModel = AdminUserDetailViewModel(userId: "usr_cashier", repository: repository)

        await viewModel.load()

        XCTAssertEqual(viewModel.user?.email, "cashier@nexo.test")
        XCTAssertEqual(viewModel.updateInput.displayName, "Cajero Demo")
        XCTAssertEqual(viewModel.updateInput.roleIds, ["role_cashier"])
        XCTAssertEqual(viewModel.roles.map(\.id), ["role_cashier"])
    }

    func testBlockUserRequiresReason() async {
        let repository = AdminAccessTestRepository()
        let viewModel = AdminUserDetailViewModel(userId: "usr_cashier", repository: repository)
        await viewModel.load()

        await viewModel.blockUser()

        XCTAssertEqual(viewModel.errorMessage, "Ingresa un motivo para bloquear el usuario.")
    }

    func testResetPasswordPublishesTemporaryPassword() async {
        let repository = AdminAccessTestRepository()
        let viewModel = AdminUserDetailViewModel(userId: "usr_cashier", repository: repository)
        await viewModel.load()
        viewModel.actionReason = "Soporte"

        await viewModel.resetPassword()

        XCTAssertEqual(viewModel.resetPasswordResult?.temporaryPassword, "Reset123!Demo")
    }
}
