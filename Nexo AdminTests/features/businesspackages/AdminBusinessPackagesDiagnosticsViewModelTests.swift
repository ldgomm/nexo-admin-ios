//
//  AdminBusinessPackagesDiagnosticsViewModelTests.swift
//  Nexo AdminTests
//
//  Created by Nexo on 22/6/26.
//

import XCTest
@testable import Nexo_Admin

@MainActor
final class AdminBusinessPackagesDiagnosticsViewModelTests: XCTestCase {
    func testLoadSuccessProducesRecommendedPresets() async {
        let repository = AdminBusinessPackagesTestRepository()
        let viewModel = AdminBusinessPackagesDiagnosticsViewModel(
            repository: repository,
            permissions: [PermissionCatalog.modulesView]
        )

        await viewModel.load()

        guard case .loaded(let presentation) = viewModel.state else {
            XCTFail("Expected loaded state")
            return
        }

        XCTAssertEqual(repository.loadCount, 1)
        XCTAssertEqual(presentation.recommendedPresets.map(\.code), ["restaurant"])
        XCTAssertEqual(presentation.activityTypeCodes, ["restaurant"])
    }

    func testRegulatedPresetsExposeHealthPharmacyAndLab() async {
        let viewModel = AdminBusinessPackagesDiagnosticsViewModel(
            repository: AdminBusinessPackagesTestRepository(),
            permissions: [PermissionCatalog.modulesView]
        )

        await viewModel.load()

        guard case .loaded(let presentation) = viewModel.state else {
            XCTFail("Expected loaded state")
            return
        }

        XCTAssertEqual(Set(presentation.regulatedPresets.map(\.code)), ["health_office_future", "pharmacy_basic_future", "clinical_lab_future"])
        XCTAssertFalse(presentation.availablePresets.contains { $0.code == "health_office_future" })
    }

    func testWarningsAreExposed() async {
        let viewModel = AdminBusinessPackagesDiagnosticsViewModel(
            repository: AdminBusinessPackagesTestRepository(),
            permissions: [PermissionCatalog.modulesView]
        )

        await viewModel.load()

        guard case .loaded(let presentation) = viewModel.state else {
            XCTFail("Expected loaded state")
            return
        }

        XCTAssertEqual(presentation.warnings, ["tourism_experiences is metadata only"])
    }

    func testRepositoryErrorProducesHumanFailedState() async {
        let repository = AdminBusinessPackagesTestRepository(error: AppError.server("Backend no disponible"))
        let viewModel = AdminBusinessPackagesDiagnosticsViewModel(
            repository: repository,
            permissions: [PermissionCatalog.modulesView]
        )

        await viewModel.load()

        guard case .failed(let message) = viewModel.state else {
            XCTFail("Expected failed state")
            return
        }

        XCTAssertTrue(message.contains("Backend no disponible"))
    }

    func testWithoutPermissionFailsFast() async {
        let repository = AdminBusinessPackagesTestRepository()
        let viewModel = AdminBusinessPackagesDiagnosticsViewModel(repository: repository, permissions: [])

        await viewModel.load()

        guard case .failed(let message) = viewModel.state else {
            XCTFail("Expected failed state")
            return
        }

        XCTAssertEqual(repository.loadCount, 0)
        XCTAssertTrue(message.contains("permisos"))
    }
}
