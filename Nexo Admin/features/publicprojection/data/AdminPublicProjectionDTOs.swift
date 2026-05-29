//
//  AdminPublicProjectionDTOs.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import Foundation

struct AdminPublicProjectionResponseDTO: Decodable, Sendable {
    let organizationId: String
    let publicStoreId: String?
    let visible: Bool
    let status: String
    let businessName: String
    let activityTypes: [String]
    let publicCatalogRevision: String?
    let locationVisibility: String
    let publishedItemCount: Int
    let updatedAt: String?
    let warnings: [String]
    let blockers: [String]
}

struct AdminPublicProjectionSettingsRequestDTO: Encodable, Sendable {
    let businessName: String
    let locationVisibility: String
    let reason: String
}

struct AdminPublicProjectionActionRequestDTO: Encodable, Sendable {
    let reason: String
}
