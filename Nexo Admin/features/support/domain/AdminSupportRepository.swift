//
//  AdminSupportRepository.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import Foundation

protocol AdminSupportRepository: Sendable {
    func getHealth() async throws -> AdminHealthSummary
    func listDevices() async throws -> [AdminRegisteredDevice]
}


// MARK: - Support Notifications Basic (23H.6E)

struct AdminSupportNotificationsSummary: Sendable, Equatable {
    let items: [AdminSupportNotificationItem]
    let unreadCount: Int
    let limit: Int?
    let unreadOnly: Bool?

    init(
        items: [AdminSupportNotificationItem],
        unreadCount: Int,
        limit: Int? = nil,
        unreadOnly: Bool? = nil
    ) {
        self.items = items
        self.unreadCount = max(0, unreadCount)
        self.limit = limit
        self.unreadOnly = unreadOnly
    }
}

struct AdminSupportNotificationItem: Identifiable, Sendable, Equatable {
    let id: String
    let type: String?
    let title: String?
    let summary: String?
    let createdAt: String?
    let readAt: String?
}

extension AdminSupportRepository {
    func getNotificationsSummary() async throws -> AdminSupportNotificationsSummary {
        AdminSupportNotificationsSummary(items: [], unreadCount: 0, limit: 50, unreadOnly: false)
    }
}
