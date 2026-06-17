//
//  RemoteAdminElectronicDocumentAPI.swift
//  Nexo Admin
//
//  Created by José Ruiz on 2/6/26.
//

import Foundation

protocol AdminElectronicDocumentAPI: Sendable {
    func listDocuments(filter: AdminElectronicDocumentListFilter) async throws -> AdminElectronicDocumentListResponseDTO
    func getDocument(id: String) async throws -> AdminElectronicDocumentDetailResponseDTO
    func getTimeline(documentId: String, limit: Int) async throws -> AdminElectronicDocumentTimelineResponseDTO
    func retryReception(documentId: String, reason: String) async throws -> AdminDocumentRetryResponseDTO
    func retryAuthorization(documentId: String, reason: String) async throws -> AdminDocumentRetryResponseDTO
    func resendEmail(documentId: String, recipientOverride: String?, reason: String) async throws -> AdminDocumentEmailResendResponseDTO
    func regenerateRide(documentId: String, reason: String) async throws -> AdminDocumentRideRegenerationResponseDTO
    func getRideArtifact(documentId: String) async throws -> AdminDocumentArtifactResponseDTO
    func getXmlArtifact(documentId: String, authorizedOnly: Bool) async throws -> AdminDocumentArtifactResponseDTO
}

protocol AdminElectronicDocumentFileAPI: AdminElectronicDocumentAPI {
    func downloadRideFile(documentId: String) async throws -> APIDataResponse
    func downloadXmlFile(documentId: String, authorizedOnly: Bool) async throws -> APIDataResponse
}

enum AdminElectronicDocumentRoutes {
    static let base = "/api/v1/admin/electronic-documents"
    static let adminBase = base
    static let businessBase = "/api/v1/business/electronic-documents"

    static func list() -> String { adminBase }

    static func detail(documentId: String) -> String { "\(adminBase)/\(documentId)" }

    static func timeline(documentId: String) -> String { "\(adminBase)/\(documentId)/timeline" }

    static func retryReception(documentId: String) -> String { "\(adminBase)/\(documentId)/retry-reception" }

    static func retryAuthorization(documentId: String) -> String { "\(adminBase)/\(documentId)/retry-authorization" }

    static func resendEmail(documentId: String) -> String { "\(adminBase)/\(documentId)/resend-email" }

    static func regenerateRide(documentId: String) -> String { "\(adminBase)/\(documentId)/ride" }

    static func ride(documentId: String) -> String { "\(adminBase)/\(documentId)/ride" }

    static func rideFile(documentId: String) -> String { "\(businessBase)/\(documentId)/ride/file" }

    static func xml(documentId: String) -> String { "\(adminBase)/\(documentId)/xml" }

    static func xmlFile(documentId: String) -> String { "\(businessBase)/\(documentId)/xml/file" }
}

struct RemoteAdminElectronicDocumentAPI: AdminElectronicDocumentAPI, AdminElectronicDocumentFileAPI {
    let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func listDocuments(filter: AdminElectronicDocumentListFilter) async throws -> AdminElectronicDocumentListResponseDTO {
        try await apiClient.send(endpoint(AdminElectronicDocumentRoutes.list(), .get, queryItems: filter.toQueryItems()))
    }

    func getDocument(id: String) async throws -> AdminElectronicDocumentDetailResponseDTO {
        try await apiClient.send(endpoint(AdminElectronicDocumentRoutes.detail(documentId: id), .get))
    }

    func getTimeline(documentId: String, limit: Int) async throws -> AdminElectronicDocumentTimelineResponseDTO {
        try await apiClient.send(
            endpoint(
                AdminElectronicDocumentRoutes.timeline(documentId: documentId),
                .get,
                queryItems: [URLQueryItem(name: "limit", value: String(max(1, min(limit, 250))))]
            )
        )
    }

    func retryReception(documentId: String, reason: String) async throws -> AdminDocumentRetryResponseDTO {
        try await apiClient.send(
            endpoint(AdminElectronicDocumentRoutes.retryReception(documentId: documentId), .post),
            body: AdminDocumentActionRequestDTO(reason: reason)
        )
    }

    func retryAuthorization(documentId: String, reason: String) async throws -> AdminDocumentRetryResponseDTO {
        try await apiClient.send(
            endpoint(AdminElectronicDocumentRoutes.retryAuthorization(documentId: documentId), .post),
            body: AdminDocumentActionRequestDTO(reason: reason)
        )
    }

    func resendEmail(documentId: String, recipientOverride: String?, reason: String) async throws -> AdminDocumentEmailResendResponseDTO {
        try await apiClient.send(
            endpoint(AdminElectronicDocumentRoutes.resendEmail(documentId: documentId), .post),
            body: AdminDocumentEmailResendRequestDTO(recipientOverride: recipientOverride, reason: reason)
        )
    }

    func regenerateRide(documentId: String, reason: String) async throws -> AdminDocumentRideRegenerationResponseDTO {
        try await apiClient.send(
            endpoint(AdminElectronicDocumentRoutes.regenerateRide(documentId: documentId), .post)
                .withIdempotencyKey(Self.idempotencyKey(action: "admin-regenerate-ride", documentId: documentId)),
            body: AdminDocumentRideRegenerationRequestDTO(reason: reason, forceRegenerateRide: true)
        )
    }

    func getRideArtifact(documentId: String) async throws -> AdminDocumentArtifactResponseDTO {
        try await apiClient.send(endpoint(AdminElectronicDocumentRoutes.ride(documentId: documentId), .get))
    }

    func getXmlArtifact(documentId: String, authorizedOnly: Bool) async throws -> AdminDocumentArtifactResponseDTO {
        try await apiClient.send(
            endpoint(
                AdminElectronicDocumentRoutes.xml(documentId: documentId),
                .get,
                queryItems: [URLQueryItem(name: "authorizedOnly", value: authorizedOnly ? "true" : "false")]
            )
        )
    }

    func downloadRideFile(documentId: String) async throws -> APIDataResponse {
        guard let dataClient = apiClient as? APIDataClient else {
            throw AppError.transport("El cliente HTTP no soporta descarga de archivos.")
        }

        return try await dataClient.sendData(
            endpoint(
                AdminElectronicDocumentRoutes.rideFile(documentId: documentId),
                .get,
                headers: ["Accept": "*/*"]
            )
        )
    }

    func downloadXmlFile(documentId: String, authorizedOnly: Bool) async throws -> APIDataResponse {
        guard let dataClient = apiClient as? APIDataClient else {
            throw AppError.transport("El cliente HTTP no soporta descarga de archivos.")
        }

        return try await dataClient.sendData(
            endpoint(
                AdminElectronicDocumentRoutes.xmlFile(documentId: documentId),
                .get,
                queryItems: [URLQueryItem(name: "authorizedOnly", value: authorizedOnly ? "true" : "false")],
                headers: ["Accept": "*/*"]
            )
        )
    }

    private func endpoint(
        _ path: String,
        _ method: HTTPMethod,
        queryItems: [URLQueryItem] = [],
        headers: [String: String] = [:]
    ) -> APIEndpoint {
        APIEndpoint(path: path, method: method, queryItems: queryItems, headers: headers, requiresAuth: true, requiresOrganization: true)
    }

    private static func idempotencyKey(action: String, documentId: String) -> String {
        let safeDocumentId = documentId
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: " ", with: "-")
        return "\(action)-\(safeDocumentId)-\(UUID().uuidString.lowercased())"
    }
}

private extension AdminElectronicDocumentListFilter {
    func toQueryItems() -> [URLQueryItem] {
        var items: [URLQueryItem] = []
        if !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { items.append(URLQueryItem(name: "query", value: query)) }
        if status != .all { items.append(URLQueryItem(name: "status", value: status.rawValue)) }
        if sriStatus != .all { items.append(URLQueryItem(name: "sriStatus", value: sriStatus.rawValue)) }
        if !documentType.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { items.append(URLQueryItem(name: "documentType", value: documentType)) }
        if !customer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { items.append(URLQueryItem(name: "customer", value: customer)) }
        if !number.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { items.append(URLQueryItem(name: "number", value: number)) }
        items.append(URLQueryItem(name: "limit", value: String(max(1, min(limit, 250)))))
        return items
    }
}
