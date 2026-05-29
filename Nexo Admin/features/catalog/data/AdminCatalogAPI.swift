//
//  AdminCatalogAPI.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import Foundation

protocol AdminCatalogAPI: Sendable {
    func listLocalItems(search: AdminCatalogSearchInput) async throws -> AdminCatalogLocalItemsResponseDTO
    func getLocalItem(id: String) async throws -> AdminCatalogLocalItemResponseDTO
    func updateLocalItem(id: String, request: UpdateAdminCatalogLocalItemRequestDTO) async throws -> AdminCatalogLocalItemResponseDTO
    func activateLocalItem(id: String, request: AdminCatalogLocalItemActionRequestDTO) async throws -> AdminCatalogLocalItemResponseDTO
    func deactivateLocalItem(id: String, request: AdminCatalogLocalItemActionRequestDTO) async throws -> AdminCatalogLocalItemResponseDTO
    func removeLocalItem(id: String, request: AdminCatalogLocalItemActionRequestDTO) async throws -> AdminCatalogLocalItemResponseDTO

    func searchMasterTemplates(search: AdminCatalogSearchInput) async throws -> AdminCatalogMasterTemplatesResponseDTO
    func getMasterTemplate(id: String) async throws -> AdminCatalogMasterTemplateResponseDTO
    func copyFromTemplate(_ request: CopyAdminCatalogItemFromTemplateRequestDTO) async throws -> AdminCatalogLocalItemResponseDTO

    func listRequests(search: AdminCatalogSearchInput) async throws -> AdminCatalogRequestsResponseDTO
    func getRequest(id: String) async throws -> AdminCatalogRequestResponseDTO
    func createRequest(_ request: CreateAdminCatalogRequestRequestDTO) async throws -> AdminCatalogRequestResponseDTO

    func listPriceHistory(organizationId: String, itemId: String, limit: Int) async throws -> AdminCatalogPriceHistoryResponseDTO
}

final class RemoteAdminCatalogAPI: AdminCatalogAPI, @unchecked Sendable {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func listLocalItems(search: AdminCatalogSearchInput) async throws -> AdminCatalogLocalItemsResponseDTO {
        try await apiClient.send(adminEndpoint(path: "/api/v1/admin/catalog/local/items", method: .get, queryItems: queryItems(from: search)))
    }

    func getLocalItem(id: String) async throws -> AdminCatalogLocalItemResponseDTO {
        try await apiClient.send(adminEndpoint(path: "/api/v1/admin/catalog/local/items/\(id)", method: .get))
    }

    func updateLocalItem(id: String, request: UpdateAdminCatalogLocalItemRequestDTO) async throws -> AdminCatalogLocalItemResponseDTO {
        try await apiClient.send(adminEndpoint(path: "/api/v1/admin/catalog/local/items/\(id)", method: .put), body: request)
    }

    func activateLocalItem(id: String, request: AdminCatalogLocalItemActionRequestDTO) async throws -> AdminCatalogLocalItemResponseDTO {
        try await apiClient.send(adminEndpoint(path: "/api/v1/admin/catalog/local/items/\(id)/activate", method: .post), body: request)
    }

    func deactivateLocalItem(id: String, request: AdminCatalogLocalItemActionRequestDTO) async throws -> AdminCatalogLocalItemResponseDTO {
        try await apiClient.send(adminEndpoint(path: "/api/v1/admin/catalog/local/items/\(id)/deactivate", method: .post), body: request)
    }

    func removeLocalItem(id: String, request: AdminCatalogLocalItemActionRequestDTO) async throws -> AdminCatalogLocalItemResponseDTO {
        try await apiClient.send(adminEndpoint(path: "/api/v1/admin/catalog/local/items/\(id)/remove", method: .post), body: request)
    }

    func searchMasterTemplates(search: AdminCatalogSearchInput) async throws -> AdminCatalogMasterTemplatesResponseDTO {
        try await apiClient.send(adminEndpoint(path: "/api/v1/admin/catalog/master/templates", method: .get, queryItems: queryItems(from: search)))
    }

    func getMasterTemplate(id: String) async throws -> AdminCatalogMasterTemplateResponseDTO {
        try await apiClient.send(adminEndpoint(path: "/api/v1/admin/catalog/master/templates/\(id)", method: .get))
    }

    func copyFromTemplate(_ request: CopyAdminCatalogItemFromTemplateRequestDTO) async throws -> AdminCatalogLocalItemResponseDTO {
        try await apiClient.send(adminEndpoint(path: "/api/v1/admin/catalog/local/items/copy-from-template", method: .post), body: request)
    }

    func listRequests(search: AdminCatalogSearchInput) async throws -> AdminCatalogRequestsResponseDTO {
        try await apiClient.send(adminEndpoint(path: "/api/v1/admin/catalog/requests", method: .get, queryItems: requestQueryItems(from: search)))
    }

    func getRequest(id: String) async throws -> AdminCatalogRequestResponseDTO {
        try await apiClient.send(adminEndpoint(path: "/api/v1/admin/catalog/requests/\(id)", method: .get))
    }

    func createRequest(_ request: CreateAdminCatalogRequestRequestDTO) async throws -> AdminCatalogRequestResponseDTO {
        try await apiClient.send(adminEndpoint(path: "/api/v1/admin/catalog/requests", method: .post), body: request)
    }

    func listPriceHistory(organizationId: String, itemId: String, limit: Int) async throws -> AdminCatalogPriceHistoryResponseDTO {
        try await apiClient.send(
            adminEndpoint(
                path: "/organizations/\(organizationId)/catalog/items/\(itemId)/price-history",
                method: .get,
                queryItems: [URLQueryItem(name: "limit", value: "\(limit)")]
            )
        )
    }

    private func adminEndpoint(path: String, method: HTTPMethod, queryItems: [URLQueryItem] = []) -> APIEndpoint {
        APIEndpoint(path: path, method: method, queryItems: queryItems, requiresAuth: true, requiresOrganization: true)
    }

    private func queryItems(from search: AdminCatalogSearchInput) -> [URLQueryItem] {
        var items: [URLQueryItem] = [URLQueryItem(name: "limit", value: "\(search.limit)")]
        if let value = search.query.trimmedOrNil { items.append(URLQueryItem(name: "q", value: value)) }
        if let value = search.identifier.trimmedOrNil { items.append(URLQueryItem(name: "identifier", value: value)) }
        if let value = search.type.trimmedOrNil { items.append(URLQueryItem(name: "type", value: value)) }
        if let value = search.statuses.trimmedOrNil { items.append(URLQueryItem(name: "statuses", value: value)) }
        return items
    }

    private func requestQueryItems(from search: AdminCatalogSearchInput) -> [URLQueryItem] {
        var items: [URLQueryItem] = [URLQueryItem(name: "limit", value: "\(search.limit)")]
        if let value = search.query.trimmedOrNil { items.append(URLQueryItem(name: "q", value: value)) }
        if let value = search.type.trimmedOrNil { items.append(URLQueryItem(name: "requestedType", value: value)) }
        if let value = search.statuses.trimmedOrNil { items.append(URLQueryItem(name: "statuses", value: value)) }
        return items
    }
}
