//
//  AdminCatalogTestRepository.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import Foundation
@testable import Nexo_Admin

final class AdminCatalogTestRepository: AdminCatalogRepository, @unchecked Sendable {
    var localItems: [AdminCatalogLocalItem]
    var templates: [AdminCatalogMasterTemplate]
    var requests: [AdminCatalogRequest]
    var priceHistory: [AdminCatalogPriceHistoryEntry]
    var failNext = false

    init(
        localItems: [AdminCatalogLocalItem] = MockAdminCatalogData.localItems,
        templates: [AdminCatalogMasterTemplate] = MockAdminCatalogData.masterTemplates,
        requests: [AdminCatalogRequest] = MockAdminCatalogData.requests,
        priceHistory: [AdminCatalogPriceHistoryEntry] = MockAdminCatalogData.priceHistory
    ) {
        self.localItems = localItems
        self.templates = templates
        self.requests = requests
        self.priceHistory = priceHistory
    }

    func listLocalItems(search: AdminCatalogSearchInput) async throws -> [AdminCatalogLocalItem] {
        try maybeFail()
        return localItems
    }

    func getLocalItem(id: String) async throws -> AdminCatalogLocalItem {
        try maybeFail()
        return localItems.first { $0.id == id }!
    }

    func updateLocalItem(_ input: SaveAdminCatalogLocalItemInput) async throws -> AdminCatalogLocalItem {
        try maybeFail()
        let index = localItems.firstIndex { $0.id == input.id }!
        let current = localItems[index]
        let updated = AdminCatalogLocalItem(
            id: current.id,
            organizationId: current.organizationId,
            branchId: current.branchId,
            activityId: current.activityId,
            templateId: current.templateId,
            globalCatalogId: current.globalCatalogId,
            sourceType: current.sourceType,
            localName: input.localName ?? current.localName,
            searchableText: current.searchableText,
            type: current.type,
            status: input.status ?? current.status,
            localPrice: input.localPrice ?? current.localPrice,
            taxProfileId: input.taxProfileCode ?? current.taxProfileId,
            publicDiscoveryStatus: current.publicDiscoveryStatus,
            productFamilyId: current.productFamilyId,
            variantAttributes: current.variantAttributes,
            identifiers: input.identifiers ?? current.identifiers,
            attributes: current.attributes,
            media: current.media
        )
        localItems[index] = updated
        return updated
    }

    func activateLocalItem(_ input: AdminCatalogActionInput) async throws -> AdminCatalogLocalItem { try await change(input.id, "ACTIVE") }
    func deactivateLocalItem(_ input: AdminCatalogActionInput) async throws -> AdminCatalogLocalItem { try await change(input.id, "PAUSED") }
    func removeLocalItem(_ input: AdminCatalogActionInput) async throws -> AdminCatalogLocalItem { try await change(input.id, "REMOVED_FROM_ACCOUNT") }

    func searchMasterTemplates(search: AdminCatalogSearchInput) async throws -> [AdminCatalogMasterTemplate] {
        try maybeFail()
        return templates
    }

    func getMasterTemplate(id: String) async throws -> AdminCatalogMasterTemplate {
        try maybeFail()
        return templates.first { $0.id == id }!
    }

    func copyFromTemplate(_ input: CopyAdminCatalogTemplateInput) async throws -> AdminCatalogLocalItem {
        try maybeFail()
        let template = templates.first { $0.id == input.templateId }!
        let item = AdminCatalogLocalItem(
            id: "ocat_new",
            organizationId: "org_altos",
            branchId: input.branchId,
            activityId: input.activityId,
            templateId: template.id,
            globalCatalogId: template.globalCatalogId,
            sourceType: "ADOPTED",
            localName: template.canonicalName,
            searchableText: template.normalizedName,
            type: template.type,
            status: "ACTIVE",
            localPrice: input.localPrice,
            taxProfileId: input.taxProfileCode,
            publicDiscoveryStatus: "PRIVATE",
            productFamilyId: template.productFamilyId,
            variantAttributes: template.variantAttributes,
            identifiers: template.identifiers,
            attributes: template.attributes,
            media: template.media
        )
        localItems.insert(item, at: 0)
        return item
    }

    func listRequests(search: AdminCatalogSearchInput) async throws -> [AdminCatalogRequest] {
        try maybeFail()
        return requests
    }

    func getRequest(id: String) async throws -> AdminCatalogRequest {
        try maybeFail()
        return requests.first { $0.id == id }!
    }

    func createRequest(_ input: CreateAdminCatalogRequestInput) async throws -> AdminCatalogRequest {
        try maybeFail()
        let request = AdminCatalogRequest(
            id: "creq_new",
            organizationId: "org_altos",
            requestedByUserId: "usr_admin",
            requestedName: input.requestedName,
            requestedType: input.requestedType,
            description: input.description,
            suggestedCategoryId: input.suggestedCategoryId,
            suggestedTaxProfileCode: input.suggestedTaxProfileCode,
            identifiers: input.identifiers,
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
        requests.insert(request, at: 0)
        return request
    }

    func listPriceHistory(organizationId: String, itemId: String, limit: Int) async throws -> [AdminCatalogPriceHistoryEntry] {
        try maybeFail()
        return priceHistory
    }

    private func change(_ id: String, _ status: String) async throws -> AdminCatalogLocalItem {
        try maybeFail()
        let current = localItems.first { $0.id == id }!
        let updated = AdminCatalogLocalItem(
            id: current.id,
            organizationId: current.organizationId,
            branchId: current.branchId,
            activityId: current.activityId,
            templateId: current.templateId,
            globalCatalogId: current.globalCatalogId,
            sourceType: current.sourceType,
            localName: current.localName,
            searchableText: current.searchableText,
            type: current.type,
            status: status,
            localPrice: current.localPrice,
            taxProfileId: current.taxProfileId,
            publicDiscoveryStatus: current.publicDiscoveryStatus,
            productFamilyId: current.productFamilyId,
            variantAttributes: current.variantAttributes,
            identifiers: current.identifiers,
            attributes: current.attributes,
            media: current.media
        )
        localItems[localItems.firstIndex { $0.id == id }!] = updated
        return updated
    }

    private func maybeFail() throws {
        if failNext {
            failNext = false
            throw AppError.server("Fallo controlado")
        }
    }
}
