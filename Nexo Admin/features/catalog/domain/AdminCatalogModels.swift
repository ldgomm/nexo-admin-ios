//
//  AdminCatalogModels.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import Foundation

struct AdminCatalogMoney: Equatable, Sendable {
    let amount: Decimal
    let currency: String

    init(amount: Decimal, currency: String = "USD") {
        self.amount = amount
        self.currency = currency
    }

    static let zero = AdminCatalogMoney(amount: 0)

    var formatted: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSDecimalNumber(decimal: amount)) ?? "\(currency) \(amount)"
    }
}

struct AdminCatalogIdentifier: Identifiable, Equatable, Sendable {
    let id: String
    let type: String
    let value: String
    let normalizedValue: String
    let scope: String
    let status: String
    let source: String
    let isPrimary: Bool

    init(
        type: String,
        value: String,
        normalizedValue: String? = nil,
        scope: String = "ORGANIZATION",
        status: String = "ACTIVE",
        source: String = "ORGANIZATION",
        isPrimary: Bool = false
    ) {
        self.id = "\(type.lowercased())_\(value.lowercased())"
        self.type = type
        self.value = value
        self.normalizedValue = normalizedValue ?? value
        self.scope = scope
        self.status = status
        self.source = source
        self.isPrimary = isPrimary
    }
}

struct AdminCatalogMediaAsset: Identifiable, Equatable, Sendable {
    let id: String
    let ownerKind: String
    let url: String
    let mimeType: String
    let status: String
    let isPrimary: Bool
    let sortOrder: Int
    let type: String?
    let role: String?
    let storageProvider: String?
    let bucket: String?
    let objectPath: String?
    let publicUrl: String?
    let signedUrlRequired: Bool?
    let sizeBytes: Int?
    let checksumSha256: String?
    let width: Int?
    let height: Int?
    let altText: String?
}

struct AdminCatalogRelatedItem: Identifiable, Equatable, Sendable {
    let id: String
    let targetItemId: String?
    let relatedItemId: String?
    let relationType: String?
    let priority: Int?
    let type: String?
    let reason: String?
    let sortOrder: Int?
    let status: String?
}

struct AdminCatalogBundleComponent: Equatable, Sendable {
    let catalogItemId: String
    let quantity: String?
    let required: Bool?
    let displayNameOverride: String?
}

struct AdminCatalogPriceListEntry: Equatable, Sendable {
    let priceListId: String?
    let label: String?
    let price: AdminCatalogMoney?
    let kind: String?
    let active: Bool?
}

struct AdminCatalogPromotionEligibility: Equatable, Sendable {
    let eligibleForPromotions: Bool?
    let eligibleForCoupons: Bool?
    let eligibleForBundleOffers: Bool?
    let promotionTags: [String]
}

struct AdminCatalogDiscountPolicy: Equatable, Sendable {
    let discountAllowed: Bool?
    let requiresManagerApproval: Bool?
    let maxManualDiscountPercent: String?
}

struct AdminCatalogBundleDefinition: Equatable, Sendable {
    let kind: String?
    let components: [AdminCatalogBundleComponent]
    let pricingMode: String?
    let inventoryMode: String?
    let isOperationallyReady: Bool?
}

struct AdminCatalogMetadataSnapshot: Equatable, Sendable {
    let rawKeys: [String]
    let priceListEntries: [AdminCatalogPriceListEntry]
    let promotionEligibility: AdminCatalogPromotionEligibility?
    let discountPolicy: AdminCatalogDiscountPolicy?
    let tags: [String]
    let publicTitle: String?
    let publicDescription: String?
    let searchKeywords: [String]
    let isFeatured: Bool?
    let isNewArrival: Bool?
    let isBestSeller: Bool?
    let isPubliclyVisible: Bool?

    init(
        rawKeys: [String] = [],
        priceListEntries: [AdminCatalogPriceListEntry] = [],
        promotionEligibility: AdminCatalogPromotionEligibility? = nil,
        discountPolicy: AdminCatalogDiscountPolicy? = nil,
        tags: [String] = [],
        publicTitle: String? = nil,
        publicDescription: String? = nil,
        searchKeywords: [String] = [],
        isFeatured: Bool? = nil,
        isNewArrival: Bool? = nil,
        isBestSeller: Bool? = nil,
        isPubliclyVisible: Bool? = nil
    ) {
        self.rawKeys = rawKeys
        self.priceListEntries = priceListEntries
        self.promotionEligibility = promotionEligibility
        self.discountPolicy = discountPolicy
        self.tags = tags
        self.publicTitle = publicTitle
        self.publicDescription = publicDescription
        self.searchKeywords = searchKeywords
        self.isFeatured = isFeatured
        self.isNewArrival = isNewArrival
        self.isBestSeller = isBestSeller
        self.isPubliclyVisible = isPubliclyVisible
    }

    static let empty = AdminCatalogMetadataSnapshot(rawKeys: [])
    var hasContent: Bool {
        !rawKeys.isEmpty || !priceListEntries.isEmpty || promotionEligibility != nil || discountPolicy != nil ||
        !tags.isEmpty || publicTitle != nil || publicDescription != nil || !searchKeywords.isEmpty ||
        isFeatured != nil || isNewArrival != nil || isBestSeller != nil || isPubliclyVisible != nil
    }
}

struct AdminCatalogMasterTemplate: Identifiable, Equatable, Sendable {
    let id: String
    let globalCatalogId: String
    let canonicalName: String
    let normalizedName: String
    let type: String
    let status: String
    let productFamilyId: String?
    let variantAttributes: [String: String]
    let identifiers: [AdminCatalogIdentifier]
    let attributes: [String: String]
    let media: [AdminCatalogMediaAsset]

    var primaryIdentifier: String? {
        identifiers.first(where: { $0.isPrimary })?.value ?? identifiers.first?.value
    }
}

struct AdminCatalogLocalItem: Identifiable, Equatable, Sendable {
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
    let localPrice: AdminCatalogMoney
    let compareAtPrice: AdminCatalogMoney?
    let cost: AdminCatalogMoney?
    let taxProfileId: String
    let publicDiscoveryStatus: String
    let brandId: String?
    let categoryId: String?
    let unitId: String?
    let productFamilyId: String?
    let parentProductId: String?
    let variantAttributes: [String: String]
    let identifiers: [AdminCatalogIdentifier]
    let attributes: [String: String]
    let media: [AdminCatalogMediaAsset]
    let alternateCodes: [String]
    let tags: [String]
    let relatedItems: [AdminCatalogRelatedItem]
    let bundle: AdminCatalogBundleDefinition?
    let pricingMetadata: AdminCatalogMetadataSnapshot
    let commercialMetadata: AdminCatalogMetadataSnapshot
    let readinessWarnings: [String]
    let canSell: Bool?
    let effectiveStatus: String?

    init(
        id: String,
        organizationId: String,
        branchId: String?,
        activityId: String,
        templateId: String?,
        globalCatalogId: String?,
        sourceType: String? = nil,
        localName: String,
        displayName: String? = nil,
        shortDescription: String? = nil,
        description: String? = nil,
        publicDescription: String? = nil,
        searchableText: String,
        type: String,
        status: String,
        localPrice: AdminCatalogMoney,
        compareAtPrice: AdminCatalogMoney? = nil,
        cost: AdminCatalogMoney? = nil,
        taxProfileId: String,
        publicDiscoveryStatus: String,
        brandId: String? = nil,
        categoryId: String? = nil,
        unitId: String? = nil,
        productFamilyId: String?,
        parentProductId: String? = nil,
        variantAttributes: [String: String],
        identifiers: [AdminCatalogIdentifier],
        attributes: [String: String],
        media: [AdminCatalogMediaAsset],
        alternateCodes: [String] = [],
        tags: [String] = [],
        relatedItems: [AdminCatalogRelatedItem] = [],
        bundle: AdminCatalogBundleDefinition? = nil,
        pricingMetadata: AdminCatalogMetadataSnapshot = .empty,
        commercialMetadata: AdminCatalogMetadataSnapshot = .empty,
        readinessWarnings: [String] = [],
        canSell: Bool? = nil,
        effectiveStatus: String? = nil
    ) {
        self.id = id
        self.organizationId = organizationId
        self.branchId = branchId
        self.activityId = activityId
        self.templateId = templateId
        self.globalCatalogId = globalCatalogId
        self.sourceType = sourceType
        self.localName = localName
        self.displayName = displayName
        self.shortDescription = shortDescription
        self.description = description
        self.publicDescription = publicDescription
        self.searchableText = searchableText
        self.type = type
        self.status = status
        self.localPrice = localPrice
        self.compareAtPrice = compareAtPrice
        self.cost = cost
        self.taxProfileId = taxProfileId
        self.publicDiscoveryStatus = publicDiscoveryStatus
        self.brandId = brandId
        self.categoryId = categoryId
        self.unitId = unitId
        self.productFamilyId = productFamilyId
        self.parentProductId = parentProductId
        self.variantAttributes = variantAttributes
        self.identifiers = identifiers
        self.attributes = attributes
        self.media = media
        self.alternateCodes = alternateCodes
        self.tags = tags
        self.relatedItems = relatedItems
        self.bundle = bundle
        self.pricingMetadata = pricingMetadata
        self.commercialMetadata = commercialMetadata
        self.readinessWarnings = readinessWarnings
        self.canSell = canSell
        self.effectiveStatus = effectiveStatus
    }

    var isActive: Bool { status.uppercased() == "ACTIVE" }
    var isPaused: Bool { status.uppercased() == "PAUSED" }
    var isRemoved: Bool { status.uppercased() == "REMOVED_FROM_ACCOUNT" }
    var hasUsefulPrice: Bool { localPrice.isGreaterThanZero }
    var hasTaxProfile: Bool { taxProfileId.trimmedOrNil != nil }
    var primaryIdentifier: String? {
        identifiers.first(where: { $0.isPrimary })?.value ?? identifiers.first?.value
    }
    var sourceTypeForDiagnostics: AdminCatalogItemSourceType {
        AdminCatalogItemSourceType(rawValue: (sourceType ?? attributes["sourceType"] ?? attributes["source_type"] ?? "").nexoCatalogUpperSnake)
            ?? (templateId?.trimmedOrNil != nil || globalCatalogId?.trimmedOrNil != nil ? .adopted : .unknown)
    }
    var sourceDisplayTitle: String { sourceTypeForDiagnostics.title }
    var sourceSystemImage: String { sourceTypeForDiagnostics.systemImage }
    var templateReferenceText: String {
        templateId?.trimmedOrNil ?? globalCatalogId?.trimmedOrNil ?? "—"
    }
}

enum AdminCatalogItemSourceType: String, Equatable, Sendable, CaseIterable {
    case manual = "MANUAL"
    case adopted = "ADOPTED"
    case imported = "IMPORTED"
    case seed = "SEED"
    case unknown = "UNKNOWN"

    var title: String {
        switch self {
        case .manual: "Manual"
        case .adopted: "Adoptado"
        case .imported: "Importado"
        case .seed: "Seed"
        case .unknown: "Sin origen"
        }
    }

    var systemImage: String {
        switch self {
        case .manual: "pencil"
        case .adopted: "doc.on.doc"
        case .imported: "tray.and.arrow.down"
        case .seed: "leaf"
        case .unknown: "questionmark.circle"
        }
    }
}

enum AdminCatalogDiagnosticsStatus: String, Equatable, Sendable {
    case ready
    case review
    case incomplete

    var title: String {
        switch self {
        case .ready: "Catálogo listo"
        case .review: "Revisar catálogo"
        case .incomplete: "Catálogo incompleto"
        }
    }

    var systemImage: String {
        switch self {
        case .ready: "checkmark.seal.fill"
        case .review: "exclamationmark.triangle.fill"
        case .incomplete: "xmark.octagon.fill"
        }
    }
}

struct AdminCatalogDiagnostics: Equatable, Sendable {
    let totalItems: Int
    let activeItems: Int
    let pausedItems: Int
    let removedItems: Int
    let adoptedItems: Int
    let seedItems: Int
    let manualItems: Int
    let importedItems: Int
    let unknownSourceItems: Int
    let missingPriceItems: Int
    let missingTaxProfileItems: Int
    let duplicateNameItems: Int
    let duplicateIdentifierItems: Int
    let pendingRequests: Int

    var status: AdminCatalogDiagnosticsStatus {
        if totalItems == 0 || activeItems == 0 || missingPriceItems > 0 || missingTaxProfileItems > 0 {
            return .incomplete
        }
        if pausedItems > 0 || removedItems > 0 || unknownSourceItems > 0 || duplicateNameItems > 0 || duplicateIdentifierItems > 0 || pendingRequests > 0 {
            return .review
        }
        return .ready
    }

    var score: Int {
        guard totalItems > 0 else { return 0 }
        var value = 100
        if activeItems == 0 { value -= 35 }
        value -= min(35, missingTaxProfileItems * 12)
        value -= min(25, missingPriceItems * 10)
        value -= min(15, duplicateNameItems * 5)
        value -= min(15, duplicateIdentifierItems * 5)
        value -= min(10, unknownSourceItems * 3)
        value -= min(10, pendingRequests * 2)
        return max(0, min(100, value))
    }

    var blockers: [String] {
        var values: [String] = []
        if totalItems == 0 { values.append("El negocio no tiene productos/servicios privados.") }
        if activeItems == 0 && totalItems > 0 { values.append("No hay productos activos para vender.") }
        if missingPriceItems > 0 { values.append("Hay \(missingPriceItems) ítem(s) sin precio operativo válido.") }
        if missingTaxProfileItems > 0 { values.append("Hay \(missingTaxProfileItems) ítem(s) sin tax profile local.") }
        return values
    }

    var warnings: [String] {
        var values: [String] = []
        if pausedItems > 0 { values.append("Hay \(pausedItems) ítem(s) pausado(s).") }
        if removedItems > 0 { values.append("Hay \(removedItems) copia(s) removida(s) del negocio.") }
        if unknownSourceItems > 0 { values.append("Hay \(unknownSourceItems) ítem(s) sin origen claro: manual, adoptado, seed o importado.") }
        if duplicateNameItems > 0 { values.append("Hay \(duplicateNameItems) ítem(s) con nombres duplicados o muy similares.") }
        if duplicateIdentifierItems > 0 { values.append("Hay \(duplicateIdentifierItems) ítem(s) con identificadores duplicados.") }
        if pendingRequests > 0 { values.append("Hay \(pendingRequests) solicitud(es) pendientes de catálogo.") }
        return values
    }

    var sourceSummary: String {
        "\(adoptedItems) adoptados · \(seedItems) seed · \(manualItems) manuales · \(importedItems) importados"
    }

    static func from(items: [AdminCatalogLocalItem], pendingRequests: Int) -> AdminCatalogDiagnostics {
        let visibleItems = items.filter { !$0.isRemoved }
        let sources = Dictionary(grouping: items, by: { $0.sourceTypeForDiagnostics })
        return AdminCatalogDiagnostics(
            totalItems: items.count,
            activeItems: items.filter(\.isActive).count,
            pausedItems: items.filter(\.isPaused).count,
            removedItems: items.filter(\.isRemoved).count,
            adoptedItems: sources[.adopted]?.count ?? 0,
            seedItems: sources[.seed]?.count ?? 0,
            manualItems: sources[.manual]?.count ?? 0,
            importedItems: sources[.imported]?.count ?? 0,
            unknownSourceItems: sources[.unknown]?.count ?? 0,
            missingPriceItems: visibleItems.filter { !$0.hasUsefulPrice }.count,
            missingTaxProfileItems: visibleItems.filter { !$0.hasTaxProfile }.count,
            duplicateNameItems: duplicateCount(visibleItems.map { $0.localName.nexoCatalogComparableKey }),
            duplicateIdentifierItems: duplicateCount(visibleItems.flatMap { $0.identifiers.map { $0.normalizedValue.nexoCatalogComparableKey } }),
            pendingRequests: pendingRequests
        )
    }

    private static func duplicateCount(_ keys: [String]) -> Int {
        Dictionary(grouping: keys.filter { !$0.isEmpty }, by: { $0 })
            .values
            .filter { $0.count > 1 }
            .reduce(0) { $0 + $1.count }
    }
}

struct AdminCatalogRequest: Identifiable, Equatable, Sendable {
    let id: String
    let organizationId: String
    let requestedByUserId: String
    let requestedName: String
    let requestedType: String
    let description: String?
    let suggestedCategoryId: String?
    let suggestedTaxProfileCode: String?
    let identifiers: [AdminCatalogIdentifier]
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

struct AdminCatalogPriceHistoryEntry: Identifiable, Equatable, Sendable {
    let id: String
    let organizationId: String
    let catalogItemId: String
    let oldPrice: AdminCatalogMoney
    let newPrice: AdminCatalogMoney
    let changedByUserId: String
    let reason: String
    let changedAt: String
}

struct AdminCatalogSummary: Equatable, Sendable {
    let localItems: [AdminCatalogLocalItem]
    let masterTemplates: [AdminCatalogMasterTemplate]
    let requests: [AdminCatalogRequest]
}

struct AdminCatalogSearchInput: Equatable, Sendable {
    var query: String = ""
    var identifier: String = ""
    var type: String = ""
    var statuses: String = ""
    var limit: Int = 50
}

struct SaveAdminCatalogLocalItemInput: Equatable, Sendable {
    let id: String
    var localName: String?
    var localPrice: AdminCatalogMoney?
    var taxProfileCode: String?
    var identifiers: [AdminCatalogIdentifier]?
    var status: String?
    var reason: String
}

struct CopyAdminCatalogTemplateInput: Equatable, Sendable {
    var templateId: String
    var branchId: String?
    var activityId: String
    var localPrice: AdminCatalogMoney
    var taxProfileCode: String
    var reason: String
}

struct CreateAdminCatalogRequestInput: Equatable, Sendable {
    var requestedName: String
    var requestedType: String
    var description: String?
    var suggestedCategoryId: String?
    var suggestedTaxProfileCode: String?
    var identifiers: [AdminCatalogIdentifier]
}

struct AdminCatalogActionInput: Equatable, Sendable {
    let id: String
    let reason: String
}

extension AdminCatalogMoney {
    var isGreaterThanZero: Bool {
        amount > Decimal.zero
    }
}

private extension String {
    var nexoCatalogUpperSnake: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "-", with: "_")
            .replacingOccurrences(of: " ", with: "_")
            .uppercased()
    }

    var nexoCatalogComparableKey: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .lowercased()
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
    }
}

extension AdminCatalogLocalItem {
    var v1cIdentifierSummary: String {
        let primary = primaryIdentifier?.trimmedOrNil
        let extraCount = max(0, identifiers.count - (primary == nil ? 0 : 1))
        if let primary, extraCount > 0 { return "\(primary) + \(extraCount) identificadores" }
        if let primary { return primary }
        return "Sin identificadores avanzados"
    }

    var v1cTagSummary: String {
        if !tags.isEmpty { return tags.prefix(5).joined(separator: ", ") }
        return v1cAttributeValue(for: ["tags", "searchTags", "search_tags", "searchKeywords", "search_keywords", "keywords"])
        ?? "Sin tags visibles"
    }

    var v1cMediaSummary: String {
        if !media.isEmpty { return "\(media.count) asset(s) de media registrados" }
        if let value = v1cAttributeValue(for: ["primaryImageUrl", "primary_image_url", "imageUrl", "image_url", "media", "images", "objectPath", "object_path"]) {
            return "Metadata presente: \(value)"
        }
        return "Sin media; carga de archivos queda pendiente"
    }

    var v1cRelatedSummary: String {
        if !relatedItems.isEmpty { return "\(relatedItems.count) relacionado(s) preparados" }
        return v1cAttributeValue(for: ["relatedItems", "related_items", "accessories", "compatibleWith", "compatible_with", "crossSell", "cross_sell"])
        ?? "Sin relacionados configurados"
    }

    var v1cBundleSummary: String {
        let upperType = type.uppercased()
        if let bundle {
            let kind = bundle.kind?.trimmedOrNil ?? upperType
            let count = bundle.components.count
            let ready = bundle.isOperationallyReady == true ? "listo operativo" : "metadata preparada"
            return "\(kind.v1cReadableSnake): \(ready) · \(count) componente(s); sin descuento de componentes todavía"
        }
        if ["KIT", "COMBO", "PACK", "PACKAGE", "SERVICE_PACKAGE"].contains(upperType) {
            return "\(upperType.v1cReadableSnake): metadata comercial; sin descuento de componentes todavía"
        }
        if let value = v1cAttributeValue(for: ["bundle", "components", "combo"]) {
            return "Metadata preparada: \(value)"
        }
        return "No configurado como pack/combo"
    }

    var v1cCommercialSummary: String {
        if pricingMetadata.hasContent || commercialMetadata.hasContent || compareAtPrice != nil {
            return "Metadata comercial/precio preparada; sin motor de promociones automáticas"
        }
        return v1cAttributeValue(for: ["pricingMetadata", "pricing_metadata", "commercialMetadata", "commercial_metadata", "promotionReady", "promotion_ready", "compareAtPrice", "compare_at_price", "offer", "discountReadiness"])
        ?? "Preparado para metadata; sin motor de promociones automáticas"
    }

    var v1cCostMarginSummary: String {
        if cost != nil { return "Costo/margen presente; dato sensible solo con permisos" }
        if v1cAttributeValue(for: ["cost", "unitCost", "unit_cost", "margin", "marginPercent", "margin_percent", "costAmount"]) != nil {
            return "Metadata sensible presente; valores solo con permisos"
        }
        return "Costo/margen permission-gated; no expuesto sin permiso"
    }

    var v1cSellabilitySummary: String {
        if let canSell { return canSell ? "Vendible por backend; sale preview confirma totales" : "No vendible por backend" }
        if let effectiveStatus = effectiveStatus?.trimmedOrNil { return "Estado efectivo backend: \(effectiveStatus.readableSnakeCase)" }
        if isActive && hasUsefulPrice && hasTaxProfile { return "Vendible por backend si sale preview confirma" }
        if !isActive { return "No vendible: estado \(status.readableSnakeCase)" }
        if !hasUsefulPrice { return "No vendible: falta precio útil" }
        if !hasTaxProfile { return "No vendible: falta tax profile" }
        return "Requiere revisión"
    }

    private func v1cAttributeValue(for keys: [String]) -> String? {
        for key in keys {
            if let direct = attributes[key]?.trimmedOrNil { return direct }
            let folded = key.lowercased()
            if let match = attributes.first(where: { $0.key.lowercased() == folded })?.value.trimmedOrNil { return match }
        }
        return nil
    }
}

private extension String {
    var v1cReadableSnake: String {
        replacingOccurrences(of: "_", with: " ")
            .lowercased()
            .capitalized
    }
}
