//
//  AdminPublicProjectionViewModelTests.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import XCTest
@testable import Nexo_Admin

@MainActor
final class AdminPublicProjectionViewModelTests: XCTestCase {
    func testRefreshLoadsProjection() async {
        let repository = FakePublicProjectionRepository()
        let viewModel = AdminPublicProjectionViewModel(
            repository: repository,
            permissions: [PermissionCatalog.publicProjectionView]
        )

        await viewModel.refresh()

        guard case .loaded(let projection) = viewModel.state else {
            return XCTFail("Expected loaded state")
        }
        XCTAssertEqual(projection.businessName, "Altos del Murco")
        XCTAssertFalse(projection.visible)
    }

    func testPublishRequiresManagePermission() async {
        let viewModel = AdminPublicProjectionViewModel(
            repository: FakePublicProjectionRepository(),
            permissions: [PermissionCatalog.publicProjectionView]
        )

        await viewModel.refresh()
        viewModel.prepareAction(.publish)

        XCTAssertFalse(viewModel.canRunAction)
    }

    func testPublishUpdatesProjection() async {
        let repository = FakePublicProjectionRepository()
        let viewModel = AdminPublicProjectionViewModel(
            repository: repository,
            permissions: [PermissionCatalog.publicProjectionManage]
        )

        await viewModel.refresh()
        viewModel.prepareAction(.publish)
        await viewModel.runAction()

        guard case .loaded(let projection) = viewModel.state else {
            return XCTFail("Expected loaded state")
        }
        XCTAssertTrue(projection.visible)
        XCTAssertEqual(projection.status, "public")
    }
}

final class FakePublicProjectionRepository: AdminPublicProjectionRepository, @unchecked Sendable {
    var projection = AdminPublicStoreProjection(
        organizationId: "org_1",
        publicStoreId: "store_1",
        visible: false,
        status: "private",
        businessName: "Altos del Murco",
        activityTypes: ["restaurant"],
        publicCatalogRevision: "pubcat_1",
        locationVisibility: "hidden",
        publishedItemCount: 0,
        updatedAt: nil,
        warnings: [],
        blockers: []
    )

    func getProjection() async throws -> AdminPublicStoreProjection { projection }
    func updateSettings(_ input: AdminPublicProjectionSettingsInput) async throws -> AdminPublicStoreProjection { projection }
    func publish(reason: String) async throws -> AdminPublicStoreProjection {
        projection = AdminPublicStoreProjection(organizationId: projection.organizationId, publicStoreId: projection.publicStoreId, visible: true, status: "public", businessName: projection.businessName, activityTypes: projection.activityTypes, publicCatalogRevision: projection.publicCatalogRevision, locationVisibility: projection.locationVisibility, publishedItemCount: projection.publishedItemCount, updatedAt: projection.updatedAt, warnings: projection.warnings, blockers: projection.blockers)
        return projection
    }
    func hide(reason: String) async throws -> AdminPublicStoreProjection { projection }
    func suspend(reason: String) async throws -> AdminPublicStoreProjection { projection }
}
