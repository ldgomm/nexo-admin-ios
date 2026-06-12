//
//  MockAdminPublicProjectionRepository.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import Foundation

final class MockAdminPublicProjectionRepository: AdminPublicProjectionRepository, @unchecked Sendable {
    var projection: AdminPublicStoreProjection

    init(projection: AdminPublicStoreProjection = MockAdminPublicProjectionData.privateProjection) {
        self.projection = projection
    }

    func getProjection() async throws -> AdminPublicStoreProjection { projection }

    func updateSettings(_ input: AdminPublicProjectionSettingsInput) async throws -> AdminPublicStoreProjection {
        projection = AdminPublicStoreProjection(
            organizationId: projection.organizationId,
            publicStoreId: projection.publicStoreId,
            visible: projection.visible,
            status: projection.status,
            businessName: input.businessName,
            activityTypes: projection.activityTypes,
            publicCatalogRevision: projection.publicCatalogRevision,
            locationVisibility: input.locationVisibility,
            publishedItemCount: projection.publishedItemCount,
            updatedAt: projection.updatedAt,
            warnings: projection.warnings,
            blockers: projection.blockers
        )
        return projection
    }

    func publish(reason: String) async throws -> AdminPublicStoreProjection { setVisible(true, status: "public") }
    func hide(reason: String) async throws -> AdminPublicStoreProjection { setVisible(false, status: "hidden_temporarily") }
    func suspend(reason: String) async throws -> AdminPublicStoreProjection { setVisible(false, status: "suspended_by_platform") }

    private func setVisible(_ visible: Bool, status: String) -> AdminPublicStoreProjection {
        projection = AdminPublicStoreProjection(
            organizationId: projection.organizationId,
            publicStoreId: projection.publicStoreId,
            visible: visible,
            status: status,
            businessName: projection.businessName,
            activityTypes: projection.activityTypes,
            publicCatalogRevision: projection.publicCatalogRevision,
            locationVisibility: projection.locationVisibility,
            publishedItemCount: projection.publishedItemCount,
            updatedAt: projection.updatedAt,
            warnings: projection.warnings,
            blockers: projection.blockers
        )
        return projection
    }
}
