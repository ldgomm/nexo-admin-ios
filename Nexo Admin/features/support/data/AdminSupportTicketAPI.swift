//
//  AdminSupportTicketAPI.swift
//  Nexo Admin
//
//  Created by José Ruiz on 1/7/26.
//

import Foundation

final class AdminSupportTicketAPI {
    enum APIError: Error {
        case invalidBaseURL
        case invalidResponse
        case httpStatus(Int, String)
        case missingURL
    }

    private let supportTicketsBasePath = "/admin/support/tickets"
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
        self.baseURL = baseURL
        self.session = session
        self.bearerTokenProvider = bearerTokenProvider
        self.decoder = JSONDecoder()
        self.encoder = JSONEncoder()
    }

    func listTickets(status: String?, priority: String?, organizationId: String?) async throws -> [AdminSupportTicketSummaryDTO] {
        var components = URLComponents(url: baseURL.appendingPathComponent(supportTicketsPathComponent), resolvingAgainstBaseURL: false)
        var queryItems: [URLQueryItem] = []
        if let status, !status.isEmpty { queryItems.append(URLQueryItem(name: "status", value: status)) }
        if let priority, !priority.isEmpty { queryItems.append(URLQueryItem(name: "priority", value: priority)) }
        if let organizationId, !organizationId.isEmpty { queryItems.append(URLQueryItem(name: "organizationId", value: organizationId)) }
        components?.queryItems = queryItems.isEmpty ? nil : queryItems
        guard let url = components?.url else { throw APIError.missingURL }

        return try await send(url: url, method: "GET", body: Optional<Data>.none)
    }

    func getTicketDetail(ticketId: String) async throws -> AdminSupportTicketDetailDTO {
        try await send(path: "\(supportTicketsPathComponent)/\(ticketId)", method: "GET", body: Optional<Data>.none)
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

    private func send<T: Decodable>(path: String, method: String, body: Data?) async throws -> T {
        let url = baseURL.appendingPathComponent(path)
        return try await send(url: url, method: method, body: body)
    }

    private func send<T: Decodable>(url: URL, method: String, body: Data?) async throws -> T {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")
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

    private static func defaultBearerToken() -> String? {
        let defaults = UserDefaults.standard
        let keys = [
            "nexo.admin.accessToken",
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
