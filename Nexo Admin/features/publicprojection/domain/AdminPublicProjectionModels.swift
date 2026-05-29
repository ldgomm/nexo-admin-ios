//
//  AdminPublicProjectionModels.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import Foundation

struct AdminPublicStoreProjection: Equatable, Sendable {
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

    var statusTitle: String { status.nexoReadableKey }
    var visibilityTitle: String { visible ? "Visible" : "Privado" }
    var canPublish: Bool { blockers.isEmpty && !visible }
    var hasWarnings: Bool { !warnings.isEmpty }
    var hasBlockers: Bool { !blockers.isEmpty }
}

struct AdminPublicProjectionSettingsInput: Equatable, Sendable {
    var businessName = ""
    var locationVisibility = "hidden"
    var reason = "Actualizar publicación pública desde Nexo Admin iOS"
}

enum AdminPublicProjectionAction: Equatable, Sendable {
    case publish
    case hide
    case suspend

    var title: String {
        switch self {
        case .publish: return "Publicar"
        case .hide: return "Ocultar"
        case .suspend: return "Suspender"
        }
    }

    var defaultReason: String {
        switch self {
        case .publish: return "Publicar storefront desde Nexo Admin iOS"
        case .hide: return "Ocultar storefront desde Nexo Admin iOS"
        case .suspend: return "Suspender storefront desde Nexo Admin iOS"
        }
    }
}

struct AdminPublicProjectionActionDraft: Equatable, Sendable {
    var action: AdminPublicProjectionAction = .hide
    var reason = "Ocultar storefront desde Nexo Admin iOS"
}
