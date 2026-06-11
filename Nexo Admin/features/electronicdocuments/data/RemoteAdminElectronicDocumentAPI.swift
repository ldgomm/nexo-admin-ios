import Foundation

protocol AdminElectronicDocumentAPI: Sendable {
    func listDocuments(filter: AdminElectronicDocumentListFilter) async throws -> AdminElectronicDocumentListResponseDTO
    func getDocument(id: String) async throws -> AdminElectronicDocumentDetailResponseDTO
    func retryAuthorization(documentId: String, reason: String) async throws -> AdminDocumentRetryResponseDTO
    func resendEmail(documentId: String, recipientOverride: String?, reason: String) async throws -> AdminDocumentEmailResendResponseDTO
    func getRideArtifact(documentId: String) async throws -> AdminDocumentArtifactResponseDTO
    func getXmlArtifact(documentId: String, authorizedOnly: Bool) async throws -> AdminDocumentArtifactResponseDTO
}

enum AdminElectronicDocumentRoutes {
    static let base = "/api/v1/admin/electronic-documents"

    static func list() -> String {
        base
    }

    static func detail(documentId: String) -> String {
        "\(base)/\(documentId)"
    }

    static func retryAuthorization(documentId: String) -> String {
        "\(base)/\(documentId)/retry-authorization"
    }

    static func resendEmail(documentId: String) -> String {
        "\(base)/\(documentId)/resend-email"
    }

    static func ride(documentId: String) -> String {
        "\(base)/\(documentId)/ride"
    }

    static func xml(documentId: String) -> String {
        "\(base)/\(documentId)/xml"
    }
}

struct RemoteAdminElectronicDocumentAPI: AdminElectronicDocumentAPI {
    let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func listDocuments(filter: AdminElectronicDocumentListFilter) async throws -> AdminElectronicDocumentListResponseDTO {
        try await apiClient.send(
            endpoint(
                AdminElectronicDocumentRoutes.list(),
                .get,
                queryItems: filter.toQueryItems()
            )
        )
    }

    func getDocument(id: String) async throws -> AdminElectronicDocumentDetailResponseDTO {
        try await apiClient.send(
            endpoint(
                AdminElectronicDocumentRoutes.detail(documentId: id),
                .get
            )
        )
    }

    func retryAuthorization(documentId: String, reason: String) async throws -> AdminDocumentRetryResponseDTO {
        try await apiClient.send(
            endpoint(
                AdminElectronicDocumentRoutes.retryAuthorization(documentId: documentId),
                .post
            ),
            body: AdminDocumentActionRequestDTO(reason: reason)
        )
    }

    func resendEmail(documentId: String, recipientOverride: String?, reason: String) async throws -> AdminDocumentEmailResendResponseDTO {
        try await apiClient.send(
            endpoint(
                AdminElectronicDocumentRoutes.resendEmail(documentId: documentId),
                .post
            ),
            body: AdminDocumentEmailResendRequestDTO(
                recipientOverride: recipientOverride,
                reason: reason
            )
        )
    }

    func getRideArtifact(documentId: String) async throws -> AdminDocumentArtifactResponseDTO {
        try await apiClient.send(
            endpoint(
                AdminElectronicDocumentRoutes.ride(documentId: documentId),
                .get
            )
        )
    }

    func getXmlArtifact(documentId: String, authorizedOnly: Bool) async throws -> AdminDocumentArtifactResponseDTO {
        try await apiClient.send(
            endpoint(
                AdminElectronicDocumentRoutes.xml(documentId: documentId),
                .get,
                queryItems: authorizedOnly
                    ? [URLQueryItem(name: "authorizedOnly", value: "true")]
                    : []
            )
        )
    }

    private func endpoint(
        _ path: String,
        _ method: HTTPMethod,
        queryItems: [URLQueryItem] = []
    ) -> APIEndpoint {
        APIEndpoint(
            path: path,
            method: method,
            queryItems: queryItems,
            requiresAuth: true,
            requiresOrganization: true
        )
    }
}

private extension AdminElectronicDocumentListFilter {
    func toQueryItems() -> [URLQueryItem] {
        var items: [URLQueryItem] = []

        if status != .all {
            items.append(URLQueryItem(name: "status", value: status.rawValue))
        }

        return items
    }
}
