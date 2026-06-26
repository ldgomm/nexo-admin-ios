//
//  AdminVerticalActivationViewModelTests.swift
//  Nexo AdminTests
//
//  Created by Nexo on 26/6/26.
//

import XCTest
@testable import Nexo_Admin

@MainActor
final class AdminVerticalActivationViewModelTests: XCTestCase {
    func testLoadSuccessBuildsRestaurantPresentation() async {
        let repository = AdminVerticalsTestRepository()
        let viewModel = AdminVerticalActivationViewModel(
            repository: repository,
            permissions: [PermissionCatalog.verticalsView]
        )

        await viewModel.load()

        guard case .loaded(let presentation) = viewModel.state else {
            XCTFail("Expected loaded state")
            return
        }

        XCTAssertEqual(repository.listPackagesCount, 1)
        XCTAssertEqual(repository.listActivationsCount, 1)
        XCTAssertEqual(repository.readinessCount, 1)
        XCTAssertEqual(presentation.package?.code, "restaurant")
        XCTAssertFalse(presentation.isRestaurantActive)
        XCTAssertEqual(presentation.readiness?.warnCount, 2)
    }

    func testActivateRestaurantUsesConservativeCapabilities() async {
        let repository = AdminVerticalsTestRepository()
        let viewModel = AdminVerticalActivationViewModel(
            repository: repository,
            permissions: [PermissionCatalog.verticalsActivate]
        )

        await viewModel.load()
        await viewModel.activateRestaurant()

        XCTAssertEqual(repository.activateCount, 1)
        XCTAssertEqual(repository.lastActivationRequest?.defaultWorkMode, "quick_sale")
        XCTAssertEqual(
            Set(repository.lastActivationRequest?.enabledCapabilities ?? []),
            ["restaurant.menu_attributes", "restaurant.service_type", "restaurant.event_service"]
        )
        XCTAssertTrue(viewModel.successMessage?.contains("activado") == true)
    }

    func testDeactivateRestaurantRequiresActiveState() async {
        let repository = AdminVerticalsTestRepository(activations: .fixture(active: true))
        let viewModel = AdminVerticalActivationViewModel(
            repository: repository,
            permissions: [PermissionCatalog.verticalsDeactivate]
        )

        await viewModel.load()
        await viewModel.deactivateRestaurant()

        XCTAssertEqual(repository.deactivateCount, 1)
        XCTAssertTrue(repository.lastDeactivationReason?.contains("Desactivar restaurante") == true)
    }

    func testWithoutPermissionFailsFast() async {
        let repository = AdminVerticalsTestRepository()
        let viewModel = AdminVerticalActivationViewModel(repository: repository, permissions: [])

        await viewModel.load()

        guard case .failed(let message) = viewModel.state else {
            XCTFail("Expected failed state")
            return
        }

        XCTAssertEqual(repository.listPackagesCount, 0)
        XCTAssertTrue(message.contains("permisos"))
    }

    func testRepositoryErrorProducesFailedState() async {
        let repository = AdminVerticalsTestRepository(error: AppError.server("Vertical backend no disponible"))
        let viewModel = AdminVerticalActivationViewModel(
            repository: repository,
            permissions: [PermissionCatalog.verticalsView]
        )

        await viewModel.load()

        guard case .failed(let message) = viewModel.state else {
            XCTFail("Expected failed state")
            return
        }

        XCTAssertTrue(message.contains("Vertical backend no disponible"))
    }
}
