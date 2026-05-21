//
//  Archivo: MockDashboardRepository.swift
//  Proyecto: Nexo Admin
//  Autor: José Ruiz
//  Fecha: 21/5/26
//
//  Sprint 13iOS-B — Dashboard administrativo
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
        return summary
    }
}
