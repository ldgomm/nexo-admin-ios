//
//  AdminFoundationViewModelTests.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import XCTest
@testable import Nexo_Admin

@MainActor
final class AdminFoundationViewModelTests: XCTestCase {
    func testLoadBuildsFoundationSnapshot() async {
        let repository = AdminFoundationTestRepository()
        let viewModel = AdminFoundationViewModel(
            repository: repository,
            permissions: [PermissionCatalog.modulesView, PermissionCatalog.modulesManage]
        )

        await viewModel.load()

        guard case .loaded(let snapshot) = viewModel.state else {
            XCTFail("Expected loaded state")
            return
        }

        XCTAssertEqual(snapshot.context.catalogRevision, "catrev_test")
        XCTAssertEqual(snapshot.activeModules.count, 1)
        XCTAssertEqual(snapshot.inactiveModules.count, 1)
    }

    func testToggleEnableModuleUsesRepositoryAndRefreshes() async {
        let repository = AdminFoundationTestRepository()
        let viewModel = AdminFoundationViewModel(
            repository: repository,
            permissions: [PermissionCatalog.modulesView, PermissionCatalog.modulesManage]
        )

        await viewModel.load()
        let module = repository.modulesResult.modules.first { $0.code == "module.reservations" }!
        viewModel.prepareToggle(module: module)
        await viewModel.runToggle()

        XCTAssertEqual(repository.enabledCodes, ["module.reservations"])
        XCTAssertEqual(viewModel.successMessage, "Módulo activado.")
    }

    func testWithoutPermissionFailsFast() async {
        let repository = AdminFoundationTestRepository()
        let viewModel = AdminFoundationViewModel(repository: repository, permissions: [])

        await viewModel.load()

        guard case .failed(let message) = viewModel.state else {
            XCTFail("Expected failed state")
            return
        }

        XCTAssertTrue(message.contains("permisos"))
    }
}
