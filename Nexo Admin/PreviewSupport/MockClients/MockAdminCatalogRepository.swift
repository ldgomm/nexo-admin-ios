//
//  MockAdminCatalogRepository.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import Foundation

final class MockAdminCatalogRepository: AdminCatalogRepository, @unchecked Sendable {
    private var items: [AdminCatalogLocalItem]
    private var templates: [AdminCatalogMasterTemplate]
    private var requests: [AdminCatalogRequest]
    private var history: [AdminCatalogPriceHistoryEntry]

    init(
        items: [AdminCatalogLocalItem] = MockAdminCatalogData.localItems,
        templates: [AdminCatalogMasterTemplate] = MockAdminCatalogData.masterTemplates,
        requests: [AdminCatalogRequest] = MockAdminCatalogData.requests,
        history: [AdminCatalogPriceHistoryEntry] = MockAdminCatalogData.priceHistory
    ) {
        self.items = items
        self.templates = templates
        self.requests = requests
        self.history = history
    }

    func listLocalItems(search: AdminCatalogSearchInput) async throws -> [AdminCatalogLocalItem] {
        filterItems(items, search: search)
    }

    func getLocalItem(id: String) async throws -> AdminCatalogLocalItem {
        guard let item = items.first(where: { $0.id == id }) else { throw AppError.notFound }
        return item
    }

    func updateLocalItem(_ input: SaveAdminCatalogLocalItemInput) async throws -> AdminCatalogLocalItem {
        guard let index = items.firstIndex(where: { $0.id == input.id }) else { throw AppError.notFound }
        let current = items[index]
        let nextPrice = input.localPrice ?? current.localPrice
        let updated = AdminCatalogLocalItem(
            id: current.id,
            organizationId: current.organizationId,
            branchId: current.branchId,
            activityId: current.activityId,
            templateId: current.templateId,
            globalCatalogId: current.globalCatalogId,
            localName: input.localName?.trimmedOrNil ?? current.localName,
            searchableText: current.searchableText,
            type: current.type,
            status: input.status?.trimmedOrNil ?? current.status,
            localPrice: nextPrice,
            taxProfileId: input.taxProfileCode?.trimmedOrNil ?? current.taxProfileId,
            publicDiscoveryStatus: current.publicDiscoveryStatus,
            productFamilyId: current.productFamilyId,
            variantAttributes: current.variantAttributes,
            identifiers: input.identifiers ?? current.identifiers,
            attributes: current.attributes,
            media: current.media
        )
        if input.localPrice != nil, input.localPrice != current.localPrice {
            history.insert(
                AdminCatalogPriceHistoryEntry(
                    id: "ph_\(history.count + 1)",
                    organizationId: current.organizationId,
                    catalogItemId: current.id,
                    oldPrice: current.localPrice,
                    newPrice: nextPrice,
                    changedByUserId: "usr_mock",
                    reason: input.reason,
                    changedAt: ISO8601DateFormatter().string(from: Date())
                ),
                at: 0
            )
        }
        items[index] = updated
        return updated
    }

    func activateLocalItem(_ input: AdminCatalogActionInput) async throws -> AdminCatalogLocalItem {
        try await changeStatus(id: input.id, status: "ACTIVE")
    }

    func deactivateLocalItem(_ input: AdminCatalogActionInput) async throws -> AdminCatalogLocalItem {
        try await changeStatus(id: input.id, status: "PAUSED")
    }

    func removeLocalItem(_ input: AdminCatalogActionInput) async throws -> AdminCatalogLocalItem {
        try await changeStatus(id: input.id, status: "REMOVED_FROM_ACCOUNT")
    }

    func searchMasterTemplates(search: AdminCatalogSearchInput) async throws -> [AdminCatalogMasterTemplate] {
        var result = templates
        if let query = search.query.trimmedOrNil?.lowercased() {
            result = result.filter { $0.canonicalName.lowercased().contains(query) || $0.globalCatalogId.lowercased().contains(query) }
        }
        if let type = search.type.trimmedOrNil {
            result = result.filter { $0.type.uppercased() == type.uppercased() }
        }
        return Array(result.prefix(search.limit))
    }

    func getMasterTemplate(id: String) async throws -> AdminCatalogMasterTemplate {
        guard let template = templates.first(where: { $0.id == id }) else { throw AppError.notFound }
        return template
    }

    func copyFromTemplate(_ input: CopyAdminCatalogTemplateInput) async throws -> AdminCatalogLocalItem {
        guard let template = templates.first(where: { $0.id == input.templateId }) else { throw AppError.notFound }
        let item = AdminCatalogLocalItem(
            id: "ocat_\(UUID().uuidString.prefix(8))",
            organizationId: "org_altos",
            branchId: input.branchId,
            activityId: input.activityId,
            templateId: template.id,
            globalCatalogId: template.globalCatalogId,
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
        items.insert(item, at: 0)
        return item
    }

    func listRequests(search: AdminCatalogSearchInput) async throws -> [AdminCatalogRequest] {
        var result = requests
        if let status = search.statuses.trimmedOrNil {
            result = result.filter { $0.status.uppercased() == status.uppercased() }
        }
        if let query = search.query.trimmedOrNil?.lowercased() {
            result = result.filter { $0.requestedName.lowercased().contains(query) }
        }
        return Array(result.prefix(search.limit))
    }

    func getRequest(id: String) async throws -> AdminCatalogRequest {
        guard let request = requests.first(where: { $0.id == id }) else { throw AppError.notFound }
        return request
    }

    func createRequest(_ input: CreateAdminCatalogRequestInput) async throws -> AdminCatalogRequest {
        let request = AdminCatalogRequest(
            id: "creq_\(UUID().uuidString.prefix(8))",
            organizationId: "org_altos",
            requestedByUserId: "usr_mock",
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
            createdAt: ISO8601DateFormatter().string(from: Date()),
            updatedAt: ISO8601DateFormatter().string(from: Date()),
            version: 1
        )
        requests.insert(request, at: 0)
        return request
    }

    func listPriceHistory(organizationId: String, itemId: String, limit: Int) async throws -> [AdminCatalogPriceHistoryEntry] {
        Array(history.filter { $0.organizationId == organizationId && $0.catalogItemId == itemId }.prefix(limit))
    }

    private func changeStatus(id: String, status: String) async throws -> AdminCatalogLocalItem {
        guard let index = items.firstIndex(where: { $0.id == id }) else { throw AppError.notFound }
        let current = items[index]
        let updated = AdminCatalogLocalItem(
            id: current.id,
            organizationId: current.organizationId,
            branchId: current.branchId,
            activityId: current.activityId,
            templateId: current.templateId,
            globalCatalogId: current.globalCatalogId,
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
        items[index] = updated
        return updated
    }

    private func filterItems(_ source: [AdminCatalogLocalItem], search: AdminCatalogSearchInput) -> [AdminCatalogLocalItem] {
        var result = source
        if let query = search.query.trimmedOrNil?.lowercased() {
            result = result.filter { item in
                item.localName.lowercased().contains(query) ||
                item.globalCatalogId.lowercased().contains(query) ||
                item.identifiers.contains { $0.value.lowercased().contains(query) }
            }
        }
        if let identifier = search.identifier.trimmedOrNil?.lowercased() {
            result = result.filter { $0.identifiers.contains { $0.value.lowercased().contains(identifier) } }
        }
        if let type = search.type.trimmedOrNil {
            result = result.filter { $0.type.uppercased() == type.uppercased() }
        }
        if let status = search.statuses.trimmedOrNil {
            result = result.filter { $0.status.uppercased() == status.uppercased() }
        }
        return Array(result.prefix(search.limit))
    }
}
