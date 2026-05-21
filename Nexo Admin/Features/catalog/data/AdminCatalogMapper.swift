//
//  AdminCatalogMapper.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import Foundation

extension AdminCatalogMoney {
    func toRequestDTO() -> AdminCatalogMoneyRequestDTO {
        AdminCatalogMoneyRequestDTO(amount: amount.nexoPlainString, currency: currency)
    }
}

extension AdminCatalogMoneyResponseDTO {
    func toDomain() -> AdminCatalogMoney {
        AdminCatalogMoney(amount: Decimal(string: amount) ?? 0, currency: currency)
    }
}

extension AdminCatalogIdentifier {
    func toRequestDTO() -> AdminCatalogIdentifierRequestDTO {
        AdminCatalogIdentifierRequestDTO(
            type: type,
            value: value,
            scope: scope,
            source: source,
            status: status,
            isPrimary: isPrimary
        )
    }
}

extension AdminCatalogIdentifierResponseDTO {
    func toDomain() -> AdminCatalogIdentifier {
        AdminCatalogIdentifier(
            type: type,
            value: value,
            normalizedValue: normalizedValue,
            scope: scope,
            status: status,
            source: source,
            isPrimary: isPrimary
        )
    }
}

extension AdminCatalogMediaAssetResponseDTO {
    func toDomain() -> AdminCatalogMediaAsset {
        AdminCatalogMediaAsset(
            id: id,
            ownerKind: ownerKind,
            url: url,
            mimeType: mimeType,
            status: status,
            isPrimary: isPrimary,
            sortOrder: sortOrder
        )
    }
}

extension AdminCatalogMasterTemplateResponseDTO {
    func toDomain() -> AdminCatalogMasterTemplate {
        AdminCatalogMasterTemplate(
            id: id,
            globalCatalogId: globalCatalogId,
            canonicalName: canonicalName,
            normalizedName: normalizedName,
            type: type,
            status: status,
            productFamilyId: productFamilyId,
            variantAttributes: variantAttributes,
            identifiers: identifiers.map { $0.toDomain() },
            attributes: attributes,
            media: media.map { $0.toDomain() }
        )
    }
}

extension AdminCatalogLocalItemResponseDTO {
    func toDomain() -> AdminCatalogLocalItem {
        AdminCatalogLocalItem(
            id: id,
            organizationId: organizationId,
            branchId: branchId,
            activityId: activityId,
            templateId: templateId,
            globalCatalogId: globalCatalogId,
            localName: localName,
            searchableText: searchableText,
            type: type,
            status: status,
            localPrice: localPrice.toDomain(),
            taxProfileId: taxProfileId,
            publicDiscoveryStatus: publicDiscoveryStatus,
            productFamilyId: productFamilyId,
            variantAttributes: variantAttributes,
            identifiers: identifiers.map { $0.toDomain() },
            attributes: attributes,
            media: media.map { $0.toDomain() }
        )
    }
}

extension AdminCatalogRequestResponseDTO {
    func toDomain() -> AdminCatalogRequest {
        AdminCatalogRequest(
            id: id,
            organizationId: organizationId,
            requestedByUserId: requestedByUserId,
            requestedName: requestedName,
            requestedType: requestedType,
            description: description,
            suggestedCategoryId: suggestedCategoryId,
            suggestedTaxProfileCode: suggestedTaxProfileCode,
            identifiers: identifiers.map { $0.toDomain() },
            status: status,
            reviewedByUserId: reviewedByUserId,
            reviewedAt: reviewedAt,
            reviewReason: reviewReason,
            linkedTemplateId: linkedTemplateId,
            adminMessage: adminMessage,
            createdAt: createdAt,
            updatedAt: updatedAt,
            version: version
        )
    }
}

extension AdminCatalogPriceHistoryItemResponseDTO {
    func toDomain() -> AdminCatalogPriceHistoryEntry {
        AdminCatalogPriceHistoryEntry(
            id: id,
            organizationId: organizationId,
            catalogItemId: catalogItemId,
            oldPrice: oldPrice.toDomain(),
            newPrice: newPrice.toDomain(),
            changedByUserId: changedByUserId,
            reason: reason,
            changedAt: changedAt
        )
    }
}

extension SaveAdminCatalogLocalItemInput {
    func toRequestDTO() -> UpdateAdminCatalogLocalItemRequestDTO {
        UpdateAdminCatalogLocalItemRequestDTO(
            localName: localName?.trimmedOrNil,
            localPrice: localPrice?.toRequestDTO(),
            taxProfileCode: taxProfileCode?.trimmedOrNil,
            identifiers: identifiers?.map { $0.toRequestDTO() },
            status: status?.trimmedOrNil,
            reason: reason
        )
    }
}

extension CopyAdminCatalogTemplateInput {
    func toRequestDTO() -> CopyAdminCatalogItemFromTemplateRequestDTO {
        CopyAdminCatalogItemFromTemplateRequestDTO(
            templateId: templateId,
            branchId: branchId?.trimmedOrNil,
            activityId: activityId,
            localPrice: localPrice.toRequestDTO(),
            taxProfileCode: taxProfileCode,
            reason: reason
        )
    }
}

extension CreateAdminCatalogRequestInput {
    func toRequestDTO() -> CreateAdminCatalogRequestRequestDTO {
        CreateAdminCatalogRequestRequestDTO(
            requestedName: requestedName,
            requestedType: requestedType,
            description: description?.trimmedOrNil,
            suggestedCategoryId: suggestedCategoryId?.trimmedOrNil,
            suggestedTaxProfileCode: suggestedTaxProfileCode?.trimmedOrNil,
            identifiers: identifiers.map { $0.toRequestDTO() }
        )
    }
}

private extension Decimal {
    var nexoPlainString: String {
        NSDecimalNumber(decimal: self).stringValue
    }
}
