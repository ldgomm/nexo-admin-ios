//
//  AdminSupportAPI.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import Foundation

protocol AdminSupportAPI: Sendable {
    func getHealth() async throws -> AdminHealthResponseDTO
    func listDevices() async throws -> AdminDevicesResponseDTO

    func getNotificationsSummary() async throws -> AdminSupportNotificationsResponseDTO
}

final class RemoteAdminSupportAPI: AdminSupportAPI, @unchecked Sendable {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func getHealth() async throws -> AdminHealthResponseDTO {
        try await apiClient.send(APIEndpoint(path: "/api/v1/admin/health", method: .get, requiresAuth: true, requiresOrganization: false))
    }

    func listDevices() async throws -> AdminDevicesResponseDTO {
        try await apiClient.send(APIEndpoint(path: "/api/v1/admin/devices", method: .get, requiresAuth: true, requiresOrganization: true))
    }


    func getNotificationsSummary() async throws -> AdminSupportNotificationsResponseDTO {
        try await apiClient.send(
            APIEndpoint(
                path: "/api/v1/admin/support/notifications",
                method: .get,
                requiresOrganization: true
            )
        )
    }
}


// MARK: - Support Notifications Basic DTOs (23H.6E)

struct AdminSupportNotificationsResponseDTO: Decodable, Sendable {
    let items: [AdminSupportNotificationDTO]
    let unreadCount: Int
    let limit: Int?
    let unreadOnly: Bool?

    private enum CodingKeys: String, CodingKey {
        case items
        case unreadCount
        case limit
        case unreadOnly
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        items = try container.decodeIfPresent([AdminSupportNotificationDTO].self, forKey: .items) ?? []
        unreadCount = max(0, try container.decodeIfPresent(Int.self, forKey: .unreadCount) ?? 0)
        limit = try container.decodeIfPresent(Int.self, forKey: .limit)
        unreadOnly = try container.decodeIfPresent(Bool.self, forKey: .unreadOnly)
    }

    func toDomain() -> AdminSupportNotificationsSummary {
        AdminSupportNotificationsSummary(
            items: items.map { $0.toDomain() },
            unreadCount: unreadCount,
            limit: limit,
            unreadOnly: unreadOnly
        )
    }
}

struct AdminSupportNotificationDTO: Decodable, Sendable {
    let id: String
    let type: String?
    let title: String?
    let summary: String?
    let createdAt: String?
    let readAt: String?

    private enum CodingKeys: String, CodingKey {
        case id
        case notificationId
        case type
        case eventType
        case title
        case summary
        case preview
        case message
        case createdAt
        case readAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = AdminSupportNotificationDTO.sanitized(
            try container.decodeIfPresent(String.self, forKey: .id)
            ?? container.decodeIfPresent(String.self, forKey: .notificationId)
            ?? "support_notification_unknown"
        ) ?? "support_notification_unknown"
        type = try container.decodeIfPresent(String.self, forKey: .type)
            ?? container.decodeIfPresent(String.self, forKey: .eventType)
        title = AdminSupportNotificationDTO.sanitized(
            try container.decodeIfPresent(String.self, forKey: .title)
        )
        summary = AdminSupportNotificationDTO.sanitized(
            try container.decodeIfPresent(String.self, forKey: .summary)
            ?? container.decodeIfPresent(String.self, forKey: .preview)
            ?? container.decodeIfPresent(String.self, forKey: .message)
        )
        createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt)
        readAt = try container.decodeIfPresent(String.self, forKey: .readAt)
    }

    func toDomain() -> AdminSupportNotificationItem {
        AdminSupportNotificationItem(
            id: id,
            type: type,
            title: title,
            summary: summary,
            createdAt: createdAt,
            readAt: readAt
        )
    }

    private static func sanitized(_ value: String?) -> String? {
        guard let value else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let lowered = trimmed.lowercased()
        let sensitive = ["authorization", "bearer ", "token", "password", "session", "secret", "firma", ".p12", ".pfx"]
        if sensitive.contains(where: { lowered.contains($0) }) { return "Contenido protegido." }
        return trimmed
    }
}
