//
//  GetDashboardSummaryUseCase.swift
//  Nexo Admin
//
//  Created by José Ruiz on 20/5/26.
//

import Foundation

struct GetDashboardSummaryUseCase: Sendable {
    private let repository: any DashboardRepository

    init(repository: any DashboardRepository) {
        self.repository = repository
    }

    func execute(period: DashboardPeriod) async throws -> DashboardSummary {
        try await repository.summary(period: period)
    }
}
