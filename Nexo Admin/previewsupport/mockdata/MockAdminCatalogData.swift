//
//  MockAdminCatalogData.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import Foundation

enum MockAdminCatalogData {
    static let cuyIdentifier = AdminCatalogIdentifier(type: "SKU", value: "CUY-ENTERO", normalizedValue: "CUY-ENTERO", isPrimary: true)
    static let borregoIdentifier = AdminCatalogIdentifier(type: "SKU", value: "BORREGO-ASADO", normalizedValue: "BORREGO-ASADO", isPrimary: true)

    static let localItems: [AdminCatalogLocalItem] = [
        AdminCatalogLocalItem(
            id: "ocat_cuy_entero",
            organizationId: "org_altos",
            branchId: "br_main",
            activityId: "act_restaurant",
            templateId: "tpl_cuy_entero",
            globalCatalogId: "gcat_cuy_entero_asado",
            sourceType: "SEED",
            localName: "Cuy entero asado",
            searchableText: "cuy entero asado cuy-entero",
            type: "PRODUCT",
            status: "ACTIVE",
            localPrice: AdminCatalogMoney(amount: 24),
            taxProfileId: "iva_current_full",
            publicDiscoveryStatus: "PRIVATE",
            productFamilyId: "pfam_cuy_preparado",
            variantAttributes: [:],
            identifiers: [cuyIdentifier],
            attributes: ["category": "Platos Fuertes"],
            media: []
        ),
        AdminCatalogLocalItem(
            id: "ocat_borrego",
            organizationId: "org_altos",
            branchId: "br_main",
            activityId: "act_restaurant",
            templateId: "tpl_borrego",
            globalCatalogId: "gcat_borrego_asado",
            sourceType: "ADOPTED",
            localName: "Borrego asado",
            searchableText: "borrego asado borrego-asado",
            type: "PRODUCT",
            status: "PAUSED",
            localPrice: AdminCatalogMoney(amount: 10),
            taxProfileId: "iva_current_full",
            publicDiscoveryStatus: "PRIVATE",
            productFamilyId: "pfam_borrego_preparado",
            variantAttributes: [:],
            identifiers: [borregoIdentifier],
            attributes: ["category": "Platos Fuertes"],
            media: []
        )
    ]

    static let masterTemplates: [AdminCatalogMasterTemplate] = [
        AdminCatalogMasterTemplate(
            id: "tpl_cuy_entero",
            globalCatalogId: "gcat_cuy_entero_asado",
            canonicalName: "Cuy entero asado",
            normalizedName: "cuy entero asado",
            type: "PRODUCT",
            status: "ACTIVE",
            productFamilyId: "pfam_cuy_preparado",
            variantAttributes: [:],
            identifiers: [cuyIdentifier],
            attributes: ["category": "Platos Fuertes"],
            media: []
        ),
        AdminCatalogMasterTemplate(
            id: "tpl_parrillada_andina",
            globalCatalogId: "gcat_parrillada_andina",
            canonicalName: "Parrillada andina",
            normalizedName: "parrillada andina",
            type: "PRODUCT",
            status: "ACTIVE",
            productFamilyId: "pfam_parrilladas",
            variantAttributes: [:],
            identifiers: [AdminCatalogIdentifier(type: "SKU", value: "PARR-ANDINA", isPrimary: true)],
            attributes: ["category": "Platos Fuertes"],
            media: []
        )
    ]

    static let requests: [AdminCatalogRequest] = [
        AdminCatalogRequest(
            id: "creq_extreme_slide",
            organizationId: "org_altos",
            requestedByUserId: "usr_admin",
            requestedName: "Extreme slide",
            requestedType: "SERVICE",
            description: "Servicio turístico nuevo para vender como experiencia.",
            suggestedCategoryId: "cat_tourism",
            suggestedTaxProfileCode: "iva_current_full",
            identifiers: [],
            status: "PENDING",
            reviewedByUserId: nil,
            reviewedAt: nil,
            reviewReason: nil,
            linkedTemplateId: nil,
            adminMessage: nil,
            createdAt: "2026-05-21T12:00:00Z",
            updatedAt: "2026-05-21T12:00:00Z",
            version: 1
        )
    ]

    static let priceHistory: [AdminCatalogPriceHistoryEntry] = [
        AdminCatalogPriceHistoryEntry(
            id: "ph_1",
            organizationId: "org_altos",
            catalogItemId: "ocat_cuy_entero",
            oldPrice: AdminCatalogMoney(amount: 22),
            newPrice: AdminCatalogMoney(amount: 24),
            changedByUserId: "usr_admin",
            reason: "Actualización de precio de temporada",
            changedAt: "2026-05-20T10:00:00Z"
        )
    ]
}
