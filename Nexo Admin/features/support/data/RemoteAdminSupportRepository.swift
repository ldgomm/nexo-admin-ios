//
//  RemoteAdminSupportRepository.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import Foundation

class RemoteAdminSupportRepository: AdminSupportRepository, @unchecked Sendable {
    let api: AdminSupportAPI

    init(api: AdminSupportAPI) {
        self.api = api
    }

    func makeSupportTicketRepository() -> (any AdminSupportTicketRepository)? {
        guard let remoteAPI = api as? RemoteAdminSupportAPI else { return nil }
        return RemoteAdminSupportTicketRepository(api: AdminSupportTicketAPI(apiClient: remoteAPI.apiClient))
    }

    func getHealth() async throws -> AdminHealthSummary {
        try await api.getHealth().toDomain()
    }

    func listDevices() async throws -> [AdminRegisteredDevice] {
        try await api.listDevices().devices.map { $0.toDomain() }
    }


    func getNotificationsSummary() async throws -> AdminSupportNotificationsSummary {
        try await api.getNotificationsSummary().toDomain()
    }
}
