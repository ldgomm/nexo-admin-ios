//
//  RemoteAdminElectronicDocumentAPI.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import Foundation

protocol AdminElectronicDocumentAPI: Sendable {
    func listDocuments(filter: AdminElectronicDocumentListFilter) async throws -> AdminElectronicDocumentListResponseDTO
    func getDocument(id: String) async throws -> AdminElectronicDocumentDetailResponseDTO
    func retryAuthorization(documentId: String, reason: String) async throws -> AdminDocumentRetryResponseDTO
    func resendEmail(documentId: String, recipientOverride: String?, reason: String) async throws -> AdminDocumentEmailResendResponseDTO
    func getRideArtifact(documentId: String) async throws -> AdminDocumentArtifactResponseDTO
    func getXmlArtifact(documentId: String, authorizedOnly: Bool) async throws -> AdminDocumentArtifactResponseDTO
}

struct RemoteAdminElectronicDocumentAPI: AdminElectronicDocumentAPI {
    let apiClient: APIClient

    func listDocuments(filter: AdminElectronicDocumentListFilter) async throws -> AdminElectronicDocumentListResponseDTO {
        try await apiClient.send(
            APIEndpoint(
                path: "/api/v1/admin/electronic-documents",
                method: .get,
                queryItems: filter.queryItems,
                requiresOrganization: true
            )
        )
    }

    func getDocument(id: String) async throws -> AdminElectronicDocumentDetailResponseDTO {
        try await apiClient.send(
            APIEndpoint(
                path: "/api/v1/admin/electronic-documents/\(id)",
                method: .get,
                requiresOrganization: true
            )
        )
    }

    func retryAuthorization(documentId: String, reason: String) async throws -> AdminDocumentRetryResponseDTO {
        try await apiClient.send(
            APIEndpoint(
                path: "/api/v1/admin/electronic-documents/\(documentId)/retry-authorization",
                method: .post,
                requiresOrganization: true
            ),
            body: AdminDocumentActionRequestDTO(reason: reason)
        )
    }

    func resendEmail(documentId: String, recipientOverride: String?, reason: String) async throws -> AdminDocumentEmailResendResponseDTO {
        try await apiClient.send(
            APIEndpoint(
                path: "/api/v1/admin/electronic-documents/\(documentId)/resend-email",
                method: .post,
                requiresOrganization: true
            ),
            body: AdminDocumentEmailResendRequestDTO(recipientOverride: recipientOverride, reason: reason)
        )
    }

    func getRideArtifact(documentId: String) async throws -> AdminDocumentArtifactResponseDTO {
        try await apiClient.send(
            APIEndpoint(
                path: "/api/v1/admin/electronic-documents/\(documentId)/ride",
                method: .get,
                requiresOrganization: true
            )
        )
    }

    func getXmlArtifact(documentId: String, authorizedOnly: Bool) async throws -> AdminDocumentArtifactResponseDTO {
        try await apiClient.send(
            APIEndpoint(
                path: "/api/v1/admin/electronic-documents/\(documentId)/xml",
                method: .get,
                queryItems: [URLQueryItem(name: "authorizedOnly", value: authorizedOnly ? "true" : "false")],
                requiresOrganization: true
            )
        )
    }
}

private extension AdminElectronicDocumentListFilter {
    var queryItems: [URLQueryItem] {
        var items: [URLQueryItem] = []
        append(&items, "q", query.trimmed.nilIfBlank)
        append(&items, "status", status.apiValue)
        append(&items, "sriStatus", sriStatus.apiValue)
        append(&items, "documentType", documentType.trimmed.nilIfBlank)
        append(&items, "customer", customer.trimmed.nilIfBlank)
        append(&items, "number", number.trimmed.nilIfBlank)
        append(&items, "fromDate", fromDate.map(Self.apiDateFormatter.string(from:)))
        append(&items, "toDate", toDate.map(Self.apiDateFormatter.string(from:)))
        append(&items, "limit", String(limit))
        return items
    }

    private static let apiDateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withDashSeparatorInDate, .withColonSeparatorInTime]
        return formatter
    }()

    private func append(_ items: inout [URLQueryItem], _ name: String, _ value: String?) {
        guard let value, !value.isEmpty else { return }
        items.append(URLQueryItem(name: name, value: value))
    }
}

private extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
}
