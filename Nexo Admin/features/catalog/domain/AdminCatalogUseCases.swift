//
//  AdminCatalogUseCases.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import Foundation

struct LoadAdminCatalogHomeUseCase: Sendable {
    let repository: any AdminCatalogRepository

    func execute(search: AdminCatalogSearchInput = AdminCatalogSearchInput()) async throws -> AdminCatalogSummary {
        async let localItems = repository.listLocalItems(search: search)
        async let requests = repository.listRequests(search: AdminCatalogSearchInput(limit: 25))
        return try await AdminCatalogSummary(localItems: localItems, masterTemplates: [], requests: requests)
    }
}

struct SearchAdminCatalogLocalItemsUseCase: Sendable {
    let repository: any AdminCatalogRepository
    func execute(search: AdminCatalogSearchInput) async throws -> [AdminCatalogLocalItem] {
        try await repository.listLocalItems(search: search)
    }
}

struct GetAdminCatalogLocalItemUseCase: Sendable {
    let repository: any AdminCatalogRepository
    func execute(id: String) async throws -> AdminCatalogLocalItem {
        try await repository.getLocalItem(id: id)
    }
}

struct UpdateAdminCatalogLocalItemUseCase: Sendable {
    let repository: any AdminCatalogRepository
    func execute(_ input: SaveAdminCatalogLocalItemInput) async throws -> AdminCatalogLocalItem {
        try await repository.updateLocalItem(input)
    }
}

struct ChangeAdminCatalogLocalItemStatusUseCase: Sendable {
    let repository: any AdminCatalogRepository

    func activate(id: String, reason: String) async throws -> AdminCatalogLocalItem {
        try await repository.activateLocalItem(AdminCatalogActionInput(id: id, reason: reason))
    }

    func deactivate(id: String, reason: String) async throws -> AdminCatalogLocalItem {
        try await repository.deactivateLocalItem(AdminCatalogActionInput(id: id, reason: reason))
    }

    func remove(id: String, reason: String) async throws -> AdminCatalogLocalItem {
        try await repository.removeLocalItem(AdminCatalogActionInput(id: id, reason: reason))
    }
}

struct SearchAdminCatalogMasterTemplatesUseCase: Sendable {
    let repository: any AdminCatalogRepository
    func execute(search: AdminCatalogSearchInput) async throws -> [AdminCatalogMasterTemplate] {
        try await repository.searchMasterTemplates(search: search)
    }
}

struct GetAdminCatalogMasterTemplateUseCase: Sendable {
    let repository: any AdminCatalogRepository
    func execute(id: String) async throws -> AdminCatalogMasterTemplate {
        try await repository.getMasterTemplate(id: id)
    }
}

struct CopyAdminCatalogTemplateUseCase: Sendable {
    let repository: any AdminCatalogRepository
    func execute(_ input: CopyAdminCatalogTemplateInput) async throws -> AdminCatalogLocalItem {
        try await repository.copyFromTemplate(input)
    }
}

struct ListAdminCatalogRequestsUseCase: Sendable {
    let repository: any AdminCatalogRepository
    func execute(search: AdminCatalogSearchInput = AdminCatalogSearchInput(limit: 100)) async throws -> [AdminCatalogRequest] {
        try await repository.listRequests(search: search)
    }
}

struct CreateAdminCatalogRequestUseCase: Sendable {
    let repository: any AdminCatalogRepository
    func execute(_ input: CreateAdminCatalogRequestInput) async throws -> AdminCatalogRequest {
        try await repository.createRequest(input)
    }
}

struct ListAdminCatalogPriceHistoryUseCase: Sendable {
    let repository: any AdminCatalogRepository
    func execute(organizationId: String, itemId: String, limit: Int = 50) async throws -> [AdminCatalogPriceHistoryEntry] {
        try await repository.listPriceHistory(organizationId: organizationId, itemId: itemId, limit: limit)
    }
}
