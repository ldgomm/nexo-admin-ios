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
            id: id?.trimmedOrNil ?? objectPath?.trimmedOrNil ?? publicUrl?.trimmedOrNil ?? url?.trimmedOrNil ?? UUID().uuidString,
            ownerKind: ownerKind?.trimmedOrNil ?? role?.trimmedOrNil ?? type?.trimmedOrNil ?? "CATALOG_ITEM",
            url: publicUrl?.trimmedOrNil ?? url?.trimmedOrNil ?? objectPath?.trimmedOrNil ?? "",
            mimeType: mimeType?.trimmedOrNil ?? "application/octet-stream",
            status: status?.trimmedOrNil ?? "ACTIVE",
            isPrimary: isPrimary ?? (role?.uppercased() == "PRIMARY"),
            sortOrder: sortOrder ?? 0,
            type: type,
            role: role,
            storageProvider: storageProvider,
            bucket: bucket,
            objectPath: objectPath,
            publicUrl: publicUrl,
            signedUrlRequired: signedUrlRequired,
            sizeBytes: sizeBytes,
            checksumSha256: checksumSha256,
            width: width,
            height: height,
            altText: altText
        )
    }
}

extension AdminCatalogRelatedItemResponseDTO {
    func toDomain() -> AdminCatalogRelatedItem {
        let effectiveTargetItemId = targetItemId?.trimmedOrNil ?? relatedItemId?.trimmedOrNil
        return AdminCatalogRelatedItem(
            id: id?.trimmedOrNil ?? effectiveTargetItemId ?? UUID().uuidString,
            targetItemId: effectiveTargetItemId,
            relatedItemId: relatedItemId?.trimmedOrNil ?? effectiveTargetItemId,
            relationType: relationType,
            priority: priority,
            type: type,
            reason: reason,
            sortOrder: sortOrder,
            status: status
        )
    }
}

extension AdminCatalogBundleComponentResponseDTO {
    func toDomain() -> AdminCatalogBundleComponent {
        AdminCatalogBundleComponent(
            catalogItemId: catalogItemId,
            quantity: quantity,
            required: required,
            displayNameOverride: displayNameOverride
        )
    }
}

extension AdminCatalogPriceListEntryResponseDTO {
    func toDomain() -> AdminCatalogPriceListEntry {
        AdminCatalogPriceListEntry(
            priceListId: priceListId,
            label: label,
            price: price?.toDomain(),
            kind: kind,
            active: active
        )
    }
}

extension AdminCatalogPromotionEligibilityResponseDTO {
    func toDomain() -> AdminCatalogPromotionEligibility {
        AdminCatalogPromotionEligibility(
            eligibleForPromotions: eligibleForPromotions,
            eligibleForCoupons: eligibleForCoupons,
            eligibleForBundleOffers: eligibleForBundleOffers,
            promotionTags: promotionTags ?? []
        )
    }
}

extension AdminCatalogDiscountPolicyResponseDTO {
    func toDomain() -> AdminCatalogDiscountPolicy {
        AdminCatalogDiscountPolicy(
            discountAllowed: discountAllowed,
            requiresManagerApproval: requiresManagerApproval,
            maxManualDiscountPercent: maxManualDiscountPercent
        )
    }
}

extension AdminCatalogBundleDefinitionResponseDTO {
    func toDomain() -> AdminCatalogBundleDefinition {
        AdminCatalogBundleDefinition(
            kind: kind,
            components: components.map { $0.toDomain() },
            pricingMode: pricingMode,
            inventoryMode: inventoryMode,
            isOperationallyReady: isOperationallyReady
        )
    }
}

extension AdminCatalogMetadataSnapshotResponseDTO {
    func toDomain() -> AdminCatalogMetadataSnapshot {
        AdminCatalogMetadataSnapshot(
            rawKeys: rawKeys,
            priceListEntries: priceListEntries.map { $0.toDomain() },
            promotionEligibility: promotionEligibility?.toDomain(),
            discountPolicy: discountPolicy?.toDomain(),
            tags: tags,
            publicTitle: publicTitle,
            publicDescription: publicDescription,
            searchKeywords: searchKeywords,
            isFeatured: isFeatured,
            isNewArrival: isNewArrival,
            isBestSeller: isBestSeller,
            isPubliclyVisible: isPubliclyVisible
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
            sourceType: sourceType,
            localName: localName,
            displayName: displayName,
            shortDescription: shortDescription,
            description: description,
            publicDescription: publicDescription,
            searchableText: searchableText,
            type: type,
            status: status,
            localPrice: localPrice.toDomain(),
            compareAtPrice: compareAtPrice?.toDomain(),
            cost: cost?.toDomain(),
            taxProfileId: taxProfileId,
            publicDiscoveryStatus: publicDiscoveryStatus,
            brandId: brandId,
            categoryId: categoryId,
            unitId: unitId,
            productFamilyId: productFamilyId,
            parentProductId: parentProductId,
            variantAttributes: variantAttributes,
            identifiers: identifiers.map { $0.toDomain() },
            attributes: attributes,
            media: media.map { $0.toDomain() },
            alternateCodes: alternateCodes ?? [],
            tags: tags ?? [],
            relatedItems: relatedItems?.map { $0.toDomain() } ?? [],
            bundle: bundle?.toDomain(),
            pricingMetadata: pricingMetadata?.toDomain() ?? .empty,
            commercialMetadata: commercialMetadata?.toDomain() ?? .empty,
            readinessWarnings: readinessWarnings ?? [],
            canSell: canSell,
            effectiveStatus: effectiveStatus
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
