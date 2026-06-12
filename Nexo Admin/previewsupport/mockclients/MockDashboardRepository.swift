//
//  MockDashboardRepository.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import Foundation

final class MockDashboardRepository: DashboardRepository, @unchecked Sendable {
    private let summary: DashboardSummary
    private let delayNanoseconds: UInt64

    init(
        summary: DashboardSummary = MockDashboardData.summary,
        delayNanoseconds: UInt64 = 250_000_000
    ) {
        self.summary = summary
        self.delayNanoseconds = delayNanoseconds
    }

    func summary(period: DashboardPeriod) async throws -> DashboardSummary {
        try await Task.sleep(nanoseconds: delayNanoseconds)
        return DashboardSummary(
            generatedAt: summary.generatedAt,
            businessDate: summary.businessDate,
            period: period,
            sales: summary.sales,
            cash: summary.cash,
            documents: summary.documents,
            tax: summary.tax,
            signature: summary.signature,
            pendingReceivables: summary.pendingReceivables,
            topItems: summary.topItems,
            alerts: summary.alerts,
            quickActions: summary.quickActions
        )
    }
}
