//
//  DashboardAPI.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import Foundation

protocol DashboardAPI: Sendable {
    func operationalSummary(request: DashboardSummaryRequest) async throws -> DashboardOperationalReportResponseDTO
}

struct DashboardSummaryRequest: Equatable, Sendable {
    let period: DashboardPeriod
    let range: DashboardDateRange
    let branchId: String?
    let activityId: String?

    init(
        period: DashboardPeriod,
        range: DashboardDateRange,
        branchId: String? = nil,
        activityId: String? = nil
    ) {
        self.period = period
        self.range = range
        self.branchId = branchId
        self.activityId = activityId
    }
}

final class RemoteDashboardAPI: DashboardAPI, @unchecked Sendable {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func operationalSummary(request: DashboardSummaryRequest) async throws -> DashboardOperationalReportResponseDTO {
        var queryItems = [
            URLQueryItem(name: "date", value: request.range.businessDate),
            URLQueryItem(name: "from", value: request.range.from),
            URLQueryItem(name: "to", value: request.range.to),
            URLQueryItem(name: "timezone", value: request.range.timezone)
        ]

        if let branchId = request.branchId?.nilIfBlank {
            queryItems.append(URLQueryItem(name: "branchId", value: branchId))
        }
        if let activityId = request.activityId?.nilIfBlank {
            queryItems.append(URLQueryItem(name: "activityId", value: activityId))
        }

        return try await apiClient.send(
            APIEndpoint(
                path: "/api/v1/admin/reports/operational-today",
                method: .get,
                queryItems: queryItems,
                requiresAuth: true,
                requiresOrganization: true
            )
        )
    }
}
