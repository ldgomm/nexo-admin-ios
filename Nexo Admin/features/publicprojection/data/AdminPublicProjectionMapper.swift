//
//  AdminPublicProjectionMapper.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import Foundation

extension AdminPublicProjectionResponseDTO {
    func toDomain() -> AdminPublicStoreProjection {
        AdminPublicStoreProjection(
            organizationId: organizationId,
            publicStoreId: publicStoreId,
            visible: visible,
            status: status,
            businessName: businessName,
            activityTypes: activityTypes,
            publicCatalogRevision: publicCatalogRevision,
            locationVisibility: locationVisibility,
            publishedItemCount: publishedItemCount,
            updatedAt: updatedAt,
            warnings: warnings,
            blockers: blockers
        )
    }
}

extension AdminPublicProjectionSettingsInput {
    func toRequest() -> AdminPublicProjectionSettingsRequestDTO {
        AdminPublicProjectionSettingsRequestDTO(
            businessName: businessName.trimmingCharacters(in: .whitespacesAndNewlines),
            locationVisibility: locationVisibility.trimmingCharacters(in: .whitespacesAndNewlines),
            reason: reason.trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }
}
