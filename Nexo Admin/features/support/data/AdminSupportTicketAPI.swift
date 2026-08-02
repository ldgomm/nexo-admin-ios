//
//  AdminSupportTicketAPI.swift
//  Nexo Admin
//
//  Created by José Ruiz on 1/7/26.
//

import Foundation

class AdminSupportTicketAPI {
    private let apiClient: APIClient?
    enum APIError: Error {
        case invalidBaseURL
        case invalidResponse
        case httpStatus(Int, String)
        case missingURL

        var userVisibleMessage: String {
            switch self {
            case .invalidBaseURL:
                return "No se pudo cargar tickets de soporte. Base URL inválida."
            case .invalidResponse:
                return "No se pudo cargar tickets de soporte. Respuesta HTTP inválida."
            case .httpStatus(let status, let message):
                let clean = message.trimmingCharacters(in: .whitespacesAndNewlines)
                if clean.isEmpty {
                    return "No se pudo cargar tickets de soporte. HTTP \(status)."
                }
                return "No se pudo cargar tickets de soporte. HTTP \(status): \(clean)"
            case .missingURL:
                return "No se pudo cargar tickets de soporte. URL inválida."
            }
        }
    }

    private let supportTicketsBasePath = "/api/v1/admin/support/tickets"
    private var supportTicketsPathComponent: String { String(supportTicketsBasePath.dropFirst()) }
    private let baseURL: URL
    private let session: URLSession
    private let bearerTokenProvider: @Sendable () async -> String?
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    init(
        baseURL: URL = AdminSupportTicketAPI.defaultBaseURL(),
        session: URLSession = .shared,
        bearerTokenProvider: @escaping @Sendable () async -> String? = { AdminSupportTicketAPI.defaultBearerToken() }
    ) {
        self.apiClient = nil
        self.baseURL = baseURL
        self.session = session
        self.bearerTokenProvider = bearerTokenProvider
        self.decoder = JSONDecoder()
        self.encoder = JSONEncoder()
    }

    init(apiClient: APIClient) {
        self.apiClient = apiClient
        self.baseURL = AdminSupportTicketAPI.defaultBaseURL()
        self.session = .shared
        self.bearerTokenProvider = { AdminSupportTicketAPI.defaultBearerToken() }
        self.decoder = JSONDecoder()
        self.encoder = JSONEncoder()
    }

    func listTickets(status: String?, priority: String?, organizationId: String?) async throws -> [AdminSupportTicketSummaryDTO] {
        var queryItems: [URLQueryItem] = []
        if let status, !status.isEmpty { queryItems.append(URLQueryItem(name: "status", value: status)) }
        if let priority, !priority.isEmpty { queryItems.append(URLQueryItem(name: "priority", value: priority)) }
        if let organizationId, !organizationId.isEmpty { queryItems.append(URLQueryItem(name: "organizationId", value: organizationId)) }

        if let apiClient {
            let path = Self.pathWithQuery(supportTicketsBasePath, queryItems: queryItems)
            return try await apiClient.send(APIEndpoint(path: path, method: .get, requiresOrganization: true))
        }

        var components = URLComponents(url: baseURL.appendingPathComponent(supportTicketsPathComponent), resolvingAgainstBaseURL: false)
        components?.queryItems = queryItems.isEmpty ? nil : queryItems
        guard let url = components?.url else { throw APIError.missingURL }

        return try await send(url: url, method: "GET", body: Optional<Data>.none)
    }

    func getTicketDetail(ticketId: String) async throws -> AdminSupportTicketDetailDTO {
        if let apiClient {
            return try await apiClient.send(APIEndpoint(path: "\(supportTicketsBasePath)/\(ticketId)", method: .get, requiresOrganization: true))
        }
        return try await send(path: "\(supportTicketsPathComponent)/\(ticketId)", method: "GET", body: Optional<Data>.none)
    }

    func replyToTicket(ticketId: String, body: String) async throws -> AdminSupportTicketDetailDTO {
        let payload = try encoder.encode(AdminSupportReplyRequestDTO(body: body))
        return try await send(path: "\(supportTicketsPathComponent)/\(ticketId)/reply", method: "POST", body: payload)
    }

    func addInternalNote(ticketId: String, body: String) async throws -> AdminSupportTicketDetailDTO {
        let payload = try encoder.encode(AdminSupportInternalNoteRequestDTO(body: body))
        return try await send(path: "\(supportTicketsPathComponent)/\(ticketId)/internal-note", method: "POST", body: payload)
    }

    func transitionTicket(ticketId: String, targetStatus: String) async throws -> AdminSupportTicketDetailDTO {
        let payload = try encoder.encode(AdminSupportTransitionRequestDTO(targetStatus: targetStatus))
        return try await send(path: "\(supportTicketsPathComponent)/\(ticketId)/transition", method: "POST", body: payload)
    }

    private static func pathWithQuery(_ path: String, queryItems: [URLQueryItem]) -> String {
        guard !queryItems.isEmpty else { return path }
        var components = URLComponents()
        components.path = path
        components.queryItems = queryItems
        return components.string ?? path
    }

    private func send<T: Decodable>(path: String, method: String, body: Data?) async throws -> T {
        let url = baseURL.appendingPathComponent(path)
        return try await send(url: url, method: method, body: body)
    }

    private func send<T: Decodable>(url: URL, method: String, body: Data?) async throws -> T {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("admin_ios", forHTTPHeaderField: "X-App-Type")
        request.setValue("NexoAdminIOS", forHTTPHeaderField: "X-Client-App")
        if let organizationId = Self.defaultOrganizationId(), !organizationId.isEmpty {
            request.setValue(organizationId, forHTTPHeaderField: "X-Organization-Id")
        }
        if let body {
            request.httpBody = body
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        if let token = await bearerTokenProvider(), !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        guard (200..<300).contains(http.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? ""
            throw APIError.httpStatus(http.statusCode, message)
        }
        return try decoder.decode(T.self, from: data)
    }

    private static func defaultBaseURL() -> URL {
        if let value = Bundle.main.object(forInfoDictionaryKey: "NEXO_BASE_URL") as? String,
           let url = URL(string: value), !value.isEmpty {
            return url
        }
        if let value = Bundle.main.object(forInfoDictionaryKey: "BASE_URL") as? String,
           let url = URL(string: value), !value.isEmpty {
            return url
        }
        if let url = URL(string: "http://localhost:8080") {
            return url
        }
        return URL(string: "http://localhost:8080")!
    }

    private static func defaultOrganizationId() -> String? {
        let defaults = UserDefaults.standard
        let keys = [
            "nexo.admin.organizationId",
            "nexo.activeOrganizationId",
            "activeOrganizationId",
            "organizationId",
            "selectedOrganizationId"
        ]
        for key in keys {
            if let value = defaults.string(forKey: key), !value.isEmpty { return value }
        }
        if let value = Bundle.main.object(forInfoDictionaryKey: "NEXO_ORGANIZATION_ID") as? String, !value.isEmpty {
            return value
        }
        return nil
    }

    private static func defaultBearerToken() -> String? {
        let defaults = UserDefaults.standard
        let keys = [
            "nexo.admin.accessToken",
            "nexo.admin.auth.accessToken",
            "nexo.admin.auth.access_token",
            "nexo_admin_access_token",
            "adminAccessToken",
            "access_token",
            "nexo.accessToken",
            "accessToken",
            "authToken",
            "jwt"
        ]
        for key in keys {
            if let token = defaults.string(forKey: key), !token.isEmpty { return token }
        }
        return nil
    }
}
