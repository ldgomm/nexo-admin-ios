//
//  RemoteDashboardRepository.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import Foundation

final class RemoteDashboardRepository: DashboardRepository, @unchecked Sendable {
    private let api: any DashboardAPI
    private let nowProvider: @Sendable () -> Date
    private let calendar: Calendar

    init(
        api: any DashboardAPI,
        nowProvider: @escaping @Sendable () -> Date = { Date() },
        calendar: Calendar = .autoupdatingCurrent
    ) {
        self.api = api
        self.nowProvider = nowProvider
        self.calendar = calendar
    }

    func summary(period: DashboardPeriod) async throws -> DashboardSummary {
        let request = DashboardSummaryRequest(
            period: period,
            range: period.dateRange(now: nowProvider(), calendar: calendar)
        )
        let response = try await api.operationalSummary(request: request)
        return DashboardMapper.map(response, period: period)
    }
}
