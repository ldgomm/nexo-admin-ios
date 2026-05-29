//
//  MockAdminPublicProjectionData.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import Foundation

enum MockAdminPublicProjectionData {
    static let privateProjection = AdminPublicStoreProjection(
        organizationId: "org_1",
        publicStoreId: "store_altos",
        visible: false,
        status: "private",
        businessName: "Altos del Murco",
        activityTypes: ["restaurant", "tourism"],
        publicCatalogRevision: "pubcat_001",
        locationVisibility: "approximate",
        publishedItemCount: 0,
        updatedAt: "2026-05-27T00:00:00Z",
        warnings: ["No hay productos publicados"],
        blockers: []
    )
}
