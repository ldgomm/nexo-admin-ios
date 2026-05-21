//
//  RemoteDashboardRepository.swift
//  Nexo Admin
//
//  Created by José Ruiz on 20/5/26.
//

import Foundation

final class RemoteDashboardRepository: DashboardRepository, @unchecked Sendable {
    private let api: any DashboardAPI

    init(api: any DashboardAPI) {
        self.api = api
    }

    func summary(period: DashboardPeriod) async throws -> DashboardSummary {
        let dto = try await api.summary(period: period)
        return DashboardMapper.map(dto)
    }
}
