//
//  AdminPermissionsViewModelTests.swift
//  Nexo Admin
//
//  Created by José Ruiz on 2/6/26.
//

import XCTest
@testable import Nexo_Admin

@MainActor
final class AdminPermissionsViewModelTests: XCTestCase {
    func testLoadPublishesPermissions() async {
        let repository = AdminAccessTestRepository()
        let viewModel = AdminPermissionsViewModel(repository: repository)

        await viewModel.load()

        guard case .loaded(let permissions) = viewModel.state else {
            return XCTFail("Expected permissions")
        }
        XCTAssertGreaterThan(permissions.count, 10)
        XCTAssertTrue(viewModel.categories.contains("Credentials"))
        XCTAssertTrue(viewModel.categories.contains("Cash"))
    }

    func testSearchFiltersPermissionsByRoleText() async {
        let repository = AdminAccessTestRepository()
        let viewModel = AdminPermissionsViewModel(repository: repository)
        await viewModel.load()
        viewModel.searchText = "roles"

        XCTAssertEqual(
            viewModel.filteredPermissions.map(\.code),
            [
                PermissionCatalog.credentialsRolesManage,
                PermissionCatalog.credentialsRolesView,
            ]
        )
    }

    func testSearchCanFindSpecificPermissionByActionText() async {
        let repository = AdminAccessTestRepository()
        let viewModel = AdminPermissionsViewModel(repository: repository)
        await viewModel.load()
        viewModel.searchText = "Ver roles"

        XCTAssertEqual(
            viewModel.filteredPermissions.map(\.code),
            [PermissionCatalog.credentialsRolesView]
        )
    }
}
