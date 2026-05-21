//
//  AdminRolesViewModelTests.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import XCTest
@testable import Nexo_Admin

@MainActor
final class AdminRolesViewModelTests: XCTestCase {
    func testLoadPublishesRolesAndPermissions() async {
        let repository = AdminAccessTestRepository()
        let viewModel = AdminRolesViewModel(repository: repository)

        await viewModel.load()

        guard case .loaded(let roles) = viewModel.state else {
            return XCTFail("Expected loaded roles")
        }
        XCTAssertEqual(roles.count, 2)
        XCTAssertEqual(viewModel.permissions.count, 3)
    }

    func testCreateRoleValidatesRequiredFields() async {
        let repository = AdminAccessTestRepository()
        let viewModel = AdminRolesViewModel(repository: repository)

        await viewModel.createRole()

        XCTAssertEqual(viewModel.errorMessage, "Completa código, nombre, descripción, permisos y motivo.")
    }

    func testCreateRoleRefreshesRoles() async {
        let repository = AdminAccessTestRepository()
        let viewModel = AdminRolesViewModel(repository: repository)
        await viewModel.load()
        viewModel.createInput.code = "supervisor"
        viewModel.createInput.name = "Supervisor"
        viewModel.createInput.description = "Puede supervisar operación"
        viewModel.createInput.permissionKeys = [PermissionCatalog.credentialsUsersView]
        viewModel.createInput.reason = "Prueba"

        await viewModel.createRole()

        guard case .loaded(let roles) = viewModel.state else {
            return XCTFail("Expected loaded roles")
        }
        XCTAssertTrue(roles.contains(where: { $0.code == "supervisor" }))
    }
}
