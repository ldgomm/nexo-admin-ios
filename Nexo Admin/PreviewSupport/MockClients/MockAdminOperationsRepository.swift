//
//  MockAdminOperationsRepository.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import Foundation

struct MockAdminOperationsRepository: AdminOperationsRepository {
    var fail = false

    func getOperationalToday(date: Date?, timezone: String) async throws -> AdminOperationalTodayReport {
        if fail { throw URLError(.badServerResponse) }
        return MockAdminOperationsData.todayReport
    }

    func getSalesSummary(range: AdminOperationsDateRange) async throws -> AdminSalesSummaryReport {
        if fail { throw URLError(.badServerResponse) }
        return MockAdminOperationsData.salesSummary
    }

    func getCashSummary(range: AdminOperationsDateRange) async throws -> AdminCashSummaryReport {
        if fail { throw URLError(.badServerResponse) }
        return MockAdminOperationsData.cashSummary
    }

    func getCurrentCashSession(branchId: String?) async throws -> AdminCashSession? {
        if fail { throw URLError(.badServerResponse) }
        return MockAdminOperationsData.currentCashSession
    }

    func listCashSessions(range: AdminOperationsDateRange, status: String?, limit: Int) async throws -> [AdminCashSession] {
        if fail { throw URLError(.badServerResponse) }
        return [MockAdminOperationsData.currentCashSession, MockAdminOperationsData.closedCashSession]
    }

    func searchAuditLogs(filter: AdminAuditFilter) async throws -> [AdminAuditLogRecord] {
        if fail { throw URLError(.badServerResponse) }
        return MockAdminOperationsData.auditLogs.filter { log in
            filter.surface.isEmpty || log.surface.localizedCaseInsensitiveContains(filter.surface)
        }
    }

    func getAuditTimeline(filter: AdminAuditFilter) async throws -> [AdminAuditTimelineItem] {
        if fail { throw URLError(.badServerResponse) }
        return MockAdminOperationsData.timeline
    }

    func getSupportDiagnostics() async throws -> AdminSupportDiagnosticsReport {
        if fail { throw URLError(.badServerResponse) }
        return MockAdminOperationsData.diagnostics
    }
}
