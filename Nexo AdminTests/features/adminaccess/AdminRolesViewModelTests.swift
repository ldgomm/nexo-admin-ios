//
//  AdminRolesViewModelTests.swift
//  Nexo Admin
//
//  Created by José Ruiz on 2/6/26.
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
        XCTAssertGreaterThan(viewModel.permissions.count, 10)
        XCTAssertFalse(viewModel.permissions.contains { $0.code == PermissionCatalog.all })
        XCTAssertEqual(viewModel.capabilityGroups.map(\.code), ["sales", "cash", "payments"])
    }


    func testDiagnosticsGroupsCashierPermissionsByHumanCapabilities() async {
        let repository = AdminAccessTestRepository()
        let viewModel = AdminRolesViewModel(repository: repository)
        await viewModel.load()

        let cashier = viewModel.roles.first { $0.code == "cashier" }!
        let diagnostics = viewModel.diagnostics(for: cashier)

        XCTAssertEqual(diagnostics.matchedCapabilityGroups.map(\.code), ["sales", "cash", "payments"])
        XCTAssertTrue(diagnostics.summaryBadges.contains("3 sensible") || diagnostics.summaryBadges.contains("1 sensible"))
        XCTAssertTrue(diagnostics.highRiskPermissions.contains { $0.code == PermissionCatalog.cashSessionOpen })
        XCTAssertTrue(diagnostics.uncoveredPermissionKeys.isEmpty)
    }

    func testCreateRoleValidatesRequiredFieldsAndWildcard() async {
        let repository = AdminAccessTestRepository()
        let viewModel = AdminRolesViewModel(repository: repository)
        viewModel.createInput.code = "bad"
        viewModel.createInput.name = "Bad"
        viewModel.createInput.description = "No debe usar wildcard"
        viewModel.createInput.permissionKeys = [PermissionCatalog.all]
        viewModel.createInput.reason = "Prueba"

        await viewModel.createRole()

        XCTAssertEqual(viewModel.errorMessage, "Completa código, nombre, descripción, permisos y motivo. No uses wildcard (*).")
    }

    func testApplyCashierTemplateUsesOnlyBackendAvailablePermissions() async {
        let repository = AdminAccessTestRepository()
        let viewModel = AdminRolesViewModel(repository: repository)
        await viewModel.load()

        viewModel.applyTemplate(.cashier)

        XCTAssertEqual(viewModel.createInput.code, "cajero")
        XCTAssertEqual(viewModel.createInput.name, "Cajero")
        XCTAssertTrue(viewModel.createInput.permissionKeys.contains(PermissionCatalog.salesView))
        XCTAssertTrue(viewModel.createInput.permissionKeys.contains(PermissionCatalog.cashSessionOpen))
        XCTAssertFalse(viewModel.createInput.permissionKeys.contains(PermissionCatalog.all))
    }

    func testCreateRoleRefreshesRoles() async {
        let repository = AdminAccessTestRepository()
        let viewModel = AdminRolesViewModel(repository: repository)
        await viewModel.load()
        viewModel.applyTemplate(.supervisor)

        await viewModel.createRole()

        guard case .loaded(let roles) = viewModel.state else {
            return XCTFail("Expected loaded roles")
        }
        XCTAssertTrue(roles.contains(where: { $0.code == "supervisor" }))
    }
}
