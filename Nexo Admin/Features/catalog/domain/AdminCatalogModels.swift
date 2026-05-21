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
    let templateId: String
    let globalCatalogId: String
    let localName: String
    let searchableText: String
    let type: String
    let status: String
    let localPrice: AdminCatalogMoney
    let taxProfileId: String
    let publicDiscoveryStatus: String
    let productFamilyId: String?
    let variantAttributes: [String: String]
    let identifiers: [AdminCatalogIdentifier]
    let attributes: [String: String]
    let media: [AdminCatalogMediaAsset]

    var isActive: Bool { status.uppercased() == "ACTIVE" }
    var isRemoved: Bool { status.uppercased() == "REMOVED_FROM_ACCOUNT" }
    var primaryIdentifier: String? {
        identifiers.first(where: { $0.isPrimary })?.value ?? identifiers.first?.value
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
