//
//  RemoteAdminSupportRepository.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import Foundation

final class RemoteAdminSupportRepository: AdminSupportRepository, @unchecked Sendable {
    private let api: AdminSupportAPI

    init(api: AdminSupportAPI) {
        self.api = api
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
