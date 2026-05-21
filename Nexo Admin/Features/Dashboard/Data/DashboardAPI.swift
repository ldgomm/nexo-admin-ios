//
//  DashboardAPI.swift
//  Nexo Admin
//
//  Created by José Ruiz on 20/5/26.
//

import Foundation

protocol DashboardAPI: Sendable {
    func summary(period: DashboardPeriod) async throws -> DashboardSummaryResponseDTO
}

final class RemoteDashboardAPI: DashboardAPI, @unchecked Sendable {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func summary(period: DashboardPeriod) async throws -> DashboardSummaryResponseDTO {
        try await apiClient.send(
            APIEndpoint(
                path: "/admin/dashboard/summary",
                method: .get,
                queryItems: [URLQueryItem(name: "period", value: period.rawValue)],
                requiresAuth: true,
                requiresOrganization: true
            )
        )
    }
}
