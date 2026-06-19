//
//  AdminCatalogDTOs.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import Foundation

struct AdminCatalogMoneyRequestDTO: Encodable, Sendable {
    let amount: String
    let currency: String
}

struct AdminCatalogMoneyResponseDTO: Decodable, Sendable {
    let amount: String
    let currency: String
}

struct AdminCatalogIdentifierRequestDTO: Encodable, Sendable {
    let type: String
    let value: String
    let scope: String
    let source: String
    let status: String
    let isPrimary: Bool
}

struct AdminCatalogIdentifierResponseDTO: Decodable, Sendable {
    let type: String
    let value: String
    let normalizedValue: String
    let scope: String
    let status: String
    let source: String
    let isPrimary: Bool
}

struct AdminCatalogMediaAssetResponseDTO: Decodable, Sendable {
    let id: String
    let ownerKind: String
    let url: String
    let mimeType: String
    let status: String
    let isPrimary: Bool
    let sortOrder: Int
}

struct AdminCatalogMasterTemplateResponseDTO: Decodable, Sendable {
    let id: String
    let globalCatalogId: String
    let canonicalName: String
    let normalizedName: String
    let type: String
    let status: String
    let productFamilyId: String?
    let variantAttributes: [String: String]
    let identifiers: [AdminCatalogIdentifierResponseDTO]
    let attributes: [String: String]
    let media: [AdminCatalogMediaAssetResponseDTO]
}

struct AdminCatalogMasterTemplatesResponseDTO: Decodable, Sendable {
    let templates: [AdminCatalogMasterTemplateResponseDTO]
}

struct CopyAdminCatalogItemFromTemplateRequestDTO: Encodable, Sendable {
    let templateId: String
    let branchId: String?
    let activityId: String
    let localPrice: AdminCatalogMoneyRequestDTO
    let taxProfileCode: String
    let reason: String
}

struct UpdateAdminCatalogLocalItemRequestDTO: Encodable, Sendable {
    let localName: String?
    let localPrice: AdminCatalogMoneyRequestDTO?
    let taxProfileCode: String?
    let identifiers: [AdminCatalogIdentifierRequestDTO]?
    let status: String?
    let reason: String
}

struct AdminCatalogLocalItemActionRequestDTO: Encodable, Sendable {
    let reason: String
}

struct AdminCatalogLocalItemResponseDTO: Decodable, Sendable {
    let id: String
    let organizationId: String
    let branchId: String?
    let activityId: String
    let templateId: String?
    let globalCatalogId: String?
    let sourceType: String?
    let localName: String
    let searchableText: String
    let type: String
    let status: String
    let localPrice: AdminCatalogMoneyResponseDTO
    let taxProfileId: String
    let publicDiscoveryStatus: String
    let productFamilyId: String?
    let variantAttributes: [String: String]
    let identifiers: [AdminCatalogIdentifierResponseDTO]
    let attributes: [String: String]
    let media: [AdminCatalogMediaAssetResponseDTO]
}

struct AdminCatalogLocalItemsResponseDTO: Decodable, Sendable {
    let items: [AdminCatalogLocalItemResponseDTO]
}

struct CreateAdminCatalogRequestRequestDTO: Encodable, Sendable {
    let requestedName: String
    let requestedType: String
    let description: String?
    let suggestedCategoryId: String?
    let suggestedTaxProfileCode: String?
    let identifiers: [AdminCatalogIdentifierRequestDTO]
}

struct AdminCatalogRequestResponseDTO: Decodable, Sendable {
    let id: String
    let organizationId: String
    let requestedByUserId: String
    let requestedName: String
    let requestedType: String
    let description: String?
    let suggestedCategoryId: String?
    let suggestedTaxProfileCode: String?
    let identifiers: [AdminCatalogIdentifierResponseDTO]
    let status: String
    let reviewedByUserId: String?
    let reviewedAt: String?
    let reviewReason: String?
    let linkedTemplateId: String?
    let adminMessage: String?
    let createdAt: String
    let updatedAt: String
    let version: Int
}

struct AdminCatalogRequestsResponseDTO: Decodable, Sendable {
    let requests: [AdminCatalogRequestResponseDTO]
}

struct AdminCatalogPriceHistoryResponseDTO: Decodable, Sendable {
    let history: [AdminCatalogPriceHistoryItemResponseDTO]
}

struct AdminCatalogPriceHistoryItemResponseDTO: Decodable, Sendable {
    let id: String
    let organizationId: String
    let catalogItemId: String
    let oldPrice: AdminCatalogMoneyResponseDTO
    let newPrice: AdminCatalogMoneyResponseDTO
    let changedByUserId: String
    let reason: String
    let changedAt: String
}
