//
//  RemoteAdminCatalogRepository.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import Foundation

final class RemoteAdminCatalogRepository: AdminCatalogRepository, @unchecked Sendable {
    private let api: AdminCatalogAPI

    init(api: AdminCatalogAPI) {
        self.api = api
    }

    func listLocalItems(search: AdminCatalogSearchInput) async throws -> [AdminCatalogLocalItem] {
        try await api.listLocalItems(search: search).items.map { $0.toDomain() }
    }

    func getLocalItem(id: String) async throws -> AdminCatalogLocalItem {
        try await api.getLocalItem(id: id).toDomain()
    }

    func updateLocalItem(_ input: SaveAdminCatalogLocalItemInput) async throws -> AdminCatalogLocalItem {
        try await api.updateLocalItem(id: input.id, request: input.toRequestDTO()).toDomain()
    }

    func activateLocalItem(_ input: AdminCatalogActionInput) async throws -> AdminCatalogLocalItem {
        try await api.activateLocalItem(id: input.id, request: AdminCatalogLocalItemActionRequestDTO(reason: input.reason)).toDomain()
    }

    func deactivateLocalItem(_ input: AdminCatalogActionInput) async throws -> AdminCatalogLocalItem {
        try await api.deactivateLocalItem(id: input.id, request: AdminCatalogLocalItemActionRequestDTO(reason: input.reason)).toDomain()
    }

    func removeLocalItem(_ input: AdminCatalogActionInput) async throws -> AdminCatalogLocalItem {
        try await api.removeLocalItem(id: input.id, request: AdminCatalogLocalItemActionRequestDTO(reason: input.reason)).toDomain()
    }

    func searchMasterTemplates(search: AdminCatalogSearchInput) async throws -> [AdminCatalogMasterTemplate] {
        try await api.searchMasterTemplates(search: search).templates.map { $0.toDomain() }
    }

    func getMasterTemplate(id: String) async throws -> AdminCatalogMasterTemplate {
        try await api.getMasterTemplate(id: id).toDomain()
    }

    func copyFromTemplate(_ input: CopyAdminCatalogTemplateInput) async throws -> AdminCatalogLocalItem {
        try await api.copyFromTemplate(input.toRequestDTO()).toDomain()
    }

    func listRequests(search: AdminCatalogSearchInput) async throws -> [AdminCatalogRequest] {
        try await api.listRequests(search: search).requests.map { $0.toDomain() }
    }

    func getRequest(id: String) async throws -> AdminCatalogRequest {
        try await api.getRequest(id: id).toDomain()
    }

    func createRequest(_ input: CreateAdminCatalogRequestInput) async throws -> AdminCatalogRequest {
        try await api.createRequest(input.toRequestDTO()).toDomain()
    }

    func listPriceHistory(organizationId: String, itemId: String, limit: Int) async throws -> [AdminCatalogPriceHistoryEntry] {
        try await api.listPriceHistory(organizationId: organizationId, itemId: itemId, limit: limit).history.map { $0.toDomain() }
    }
}
