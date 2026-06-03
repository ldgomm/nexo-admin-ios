//
//  AdminUsersViewModelTests.swift
//  Nexo Admin
//
//  Created by José Ruiz on 2/6/26.
//

import XCTest
@testable import Nexo_Admin

@MainActor
final class AdminUsersViewModelTests: XCTestCase {
    func testLoadPublishesUsersAndAssignableRoles() async {
        let repository = AdminAccessTestRepository()
        let viewModel = AdminUsersViewModel(repository: repository)

        await viewModel.load()

        guard case .loaded(let users) = viewModel.state else {
            return XCTFail("Expected loaded users")
        }
        XCTAssertEqual(users.count, 2)
        XCTAssertEqual(viewModel.activeRoles.map(\.id), ["role_cashier"])
        XCTAssertEqual(viewModel.createInput.roleIds, ["role_cashier"])
    }

    func testCreateTemporaryUserPublishesSecretAndRefreshesList() async {
        let repository = AdminAccessTestRepository()
        let viewModel = AdminUsersViewModel(repository: repository)
        await viewModel.load()
        viewModel.createInput.email = "new@nexo.test"
        viewModel.createInput.displayName = "Nuevo Operador"
        viewModel.createInput.roleIds = ["role_cashier"]
        viewModel.createInput.reason = "Prueba"

        await viewModel.createTemporaryUser()

        XCTAssertEqual(viewModel.createdTemporaryUser?.temporaryPassword, "Temp123!Demo")
        guard case .loaded(let users) = viewModel.state else {
            return XCTFail("Expected refreshed users")
        }
        XCTAssertTrue(users.contains(where: { $0.email == "new@nexo.test" }))
    }
}
