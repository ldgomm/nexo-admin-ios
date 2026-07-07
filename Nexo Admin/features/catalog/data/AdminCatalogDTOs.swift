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
    let id: String?
    let ownerKind: String?
    let url: String?
    let type: String?
    let role: String?
    let storageProvider: String?
    let bucket: String?
    let objectPath: String?
    let publicUrl: String?
    let signedUrlRequired: Bool?
    let mimeType: String?
    let sizeBytes: Int?
    let checksumSha256: String?
    let width: Int?
    let height: Int?
    let altText: String?
    let status: String?
    let isPrimary: Bool?
    let sortOrder: Int?
}

struct AdminCatalogRelatedItemResponseDTO: Decodable, Sendable {
    let id: String?
    let relatedItemId: String?
    let targetItemId: String?
    let relationType: String?
    let priority: Int?
    let type: String?
    let reason: String?
    let sortOrder: Int?
    let status: String?
}

struct AdminCatalogBundleComponentResponseDTO: Decodable, Sendable {
    let catalogItemId: String
    let quantity: String?
    let required: Bool?
    let displayNameOverride: String?
}

struct AdminCatalogPriceListEntryResponseDTO: Decodable, Sendable {
    let priceListId: String?
    let label: String?
    let price: AdminCatalogMoneyResponseDTO?
    let kind: String?
    let active: Bool?
}

struct AdminCatalogPromotionEligibilityResponseDTO: Decodable, Sendable {
    let eligibleForPromotions: Bool?
    let eligibleForCoupons: Bool?
    let eligibleForBundleOffers: Bool?
    let promotionTags: [String]?
}

struct AdminCatalogDiscountPolicyResponseDTO: Decodable, Sendable {
    let discountAllowed: Bool?
    let requiresManagerApproval: Bool?
    let maxManualDiscountPercent: String?
}


struct AdminCatalogBundleDefinitionResponseDTO: Decodable, Sendable {
    let kind: String?
    let components: [AdminCatalogBundleComponentResponseDTO]
    let pricingMode: String?
    let inventoryMode: String?
    let isOperationallyReady: Bool?

    private enum CodingKeys: String, CodingKey {
        case kind
        case components
        case pricingMode
        case inventoryMode
        case isOperationallyReady
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.kind = try container.decodeIfPresent(String.self, forKey: .kind)
        self.components = try container.decodeIfPresent([AdminCatalogBundleComponentResponseDTO].self, forKey: .components) ?? []
        self.pricingMode = try container.decodeIfPresent(String.self, forKey: .pricingMode)
        self.inventoryMode = try container.decodeIfPresent(String.self, forKey: .inventoryMode)
        self.isOperationallyReady = try container.decodeIfPresent(Bool.self, forKey: .isOperationallyReady)
    }
}

struct AdminCatalogMetadataSnapshotResponseDTO: Decodable, Sendable {
    let rawKeys: [String]
    let priceListEntries: [AdminCatalogPriceListEntryResponseDTO]
    let promotionEligibility: AdminCatalogPromotionEligibilityResponseDTO?
    let discountPolicy: AdminCatalogDiscountPolicyResponseDTO?
    let tags: [String]
    let publicTitle: String?
    let publicDescription: String?
    let searchKeywords: [String]
    let isFeatured: Bool?
    let isNewArrival: Bool?
    let isBestSeller: Bool?
    let isPubliclyVisible: Bool?

    init(from decoder: Decoder) throws {
        if let container = try? decoder.container(keyedBy: AdminCatalogDynamicCodingKey.self) {
            rawKeys = container.allKeys.map(\.stringValue).sorted()
            priceListEntries = try container.decodeIfPresent([AdminCatalogPriceListEntryResponseDTO].self, forKey: AdminCatalogDynamicCodingKey("priceListEntries")) ?? []
            promotionEligibility = try container.decodeIfPresent(AdminCatalogPromotionEligibilityResponseDTO.self, forKey: AdminCatalogDynamicCodingKey("promotionEligibility"))
            discountPolicy = try container.decodeIfPresent(AdminCatalogDiscountPolicyResponseDTO.self, forKey: AdminCatalogDynamicCodingKey("discountPolicy"))
            tags = try container.decodeIfPresent([String].self, forKey: AdminCatalogDynamicCodingKey("tags")) ?? []
            publicTitle = try container.decodeIfPresent(String.self, forKey: AdminCatalogDynamicCodingKey("publicTitle"))
            publicDescription = try container.decodeIfPresent(String.self, forKey: AdminCatalogDynamicCodingKey("publicDescription"))
            searchKeywords = try container.decodeIfPresent([String].self, forKey: AdminCatalogDynamicCodingKey("searchKeywords")) ?? []
            isFeatured = try container.decodeIfPresent(Bool.self, forKey: AdminCatalogDynamicCodingKey("isFeatured"))
            isNewArrival = try container.decodeIfPresent(Bool.self, forKey: AdminCatalogDynamicCodingKey("isNewArrival"))
            isBestSeller = try container.decodeIfPresent(Bool.self, forKey: AdminCatalogDynamicCodingKey("isBestSeller"))
            isPubliclyVisible = try container.decodeIfPresent(Bool.self, forKey: AdminCatalogDynamicCodingKey("isPubliclyVisible"))
        } else {
            rawKeys = []
            priceListEntries = []
            promotionEligibility = nil
            discountPolicy = nil
            tags = []
            publicTitle = nil
            publicDescription = nil
            searchKeywords = []
            isFeatured = nil
            isNewArrival = nil
            isBestSeller = nil
            isPubliclyVisible = nil
        }
    }
}

struct AdminCatalogDynamicCodingKey: CodingKey {
    let stringValue: String
    let intValue: Int?

    init(_ stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }

    init?(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }

    init?(intValue: Int) {
        self.stringValue = String(intValue)
        self.intValue = intValue
    }
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
    let displayName: String?
    let shortDescription: String?
    let description: String?
    let publicDescription: String?
    let searchableText: String
    let type: String
    let status: String
    let localPrice: AdminCatalogMoneyResponseDTO
    let compareAtPrice: AdminCatalogMoneyResponseDTO?
    let cost: AdminCatalogMoneyResponseDTO?
    let taxProfileId: String
    let publicDiscoveryStatus: String
    let brandId: String?
    let categoryId: String?
    let unitId: String?
    let productFamilyId: String?
    let parentProductId: String?
    let variantAttributes: [String: String]
    let identifiers: [AdminCatalogIdentifierResponseDTO]
    let attributes: [String: String]
    let media: [AdminCatalogMediaAssetResponseDTO]
    let alternateCodes: [String]?
    let tags: [String]?
    let relatedItems: [AdminCatalogRelatedItemResponseDTO]?
    let bundle: AdminCatalogBundleDefinitionResponseDTO?
    let pricingMetadata: AdminCatalogMetadataSnapshotResponseDTO?
    let commercialMetadata: AdminCatalogMetadataSnapshotResponseDTO?
    let readinessWarnings: [String]?
    let canSell: Bool?
    let effectiveStatus: String?
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
