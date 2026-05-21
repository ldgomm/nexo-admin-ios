//
//  AdminCatalogRepository.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import Foundation

protocol AdminCatalogRepository: Sendable {
    func listLocalItems(search: AdminCatalogSearchInput) async throws -> [AdminCatalogLocalItem]
    func getLocalItem(id: String) async throws -> AdminCatalogLocalItem
    func updateLocalItem(_ input: SaveAdminCatalogLocalItemInput) async throws -> AdminCatalogLocalItem
    func activateLocalItem(_ input: AdminCatalogActionInput) async throws -> AdminCatalogLocalItem
    func deactivateLocalItem(_ input: AdminCatalogActionInput) async throws -> AdminCatalogLocalItem
    func removeLocalItem(_ input: AdminCatalogActionInput) async throws -> AdminCatalogLocalItem

    func searchMasterTemplates(search: AdminCatalogSearchInput) async throws -> [AdminCatalogMasterTemplate]
    func getMasterTemplate(id: String) async throws -> AdminCatalogMasterTemplate
    func copyFromTemplate(_ input: CopyAdminCatalogTemplateInput) async throws -> AdminCatalogLocalItem

    func listRequests(search: AdminCatalogSearchInput) async throws -> [AdminCatalogRequest]
    func getRequest(id: String) async throws -> AdminCatalogRequest
    func createRequest(_ input: CreateAdminCatalogRequestInput) async throws -> AdminCatalogRequest

    func listPriceHistory(organizationId: String, itemId: String, limit: Int) async throws -> [AdminCatalogPriceHistoryEntry]
}
