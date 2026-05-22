//
//  RemoteAdminOperationsRepository.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import Foundation

struct RemoteAdminOperationsRepository: AdminOperationsRepository {
    let api: AdminOperationsAPI

    func getOperationalToday(date: Date?, timezone: String) async throws -> AdminOperationalTodayReport {
        try await api.getOperationalToday(date: date, timezone: timezone).toDomain()
    }

    func getSalesSummary(range: AdminOperationsDateRange) async throws -> AdminSalesSummaryReport {
        try await api.getSalesSummary(range: range).toDomain()
    }

    func getCashSummary(range: AdminOperationsDateRange) async throws -> AdminCashSummaryReport {
        try await api.getCashSummary(range: range).toDomain()
    }

    func getCurrentCashSession(branchId: String?) async throws -> AdminCashSession? {
        try await api.getCurrentCashSession(branchId: branchId).cashSession?.toDomain()
    }

    func listCashSessions(range: AdminOperationsDateRange, status: String?, limit: Int) async throws -> [AdminCashSession] {
        try await api.listCashSessions(range: range, status: status, limit: limit).cashSessions.map { $0.toDomain() }
    }

    func searchAuditLogs(filter: AdminAuditFilter) async throws -> [AdminAuditLogRecord] {
        try await api.searchAuditLogs(filter: filter).logs.map { $0.toDomain() }
    }

    func getAuditTimeline(filter: AdminAuditFilter) async throws -> [AdminAuditTimelineItem] {
        try await api.getAuditTimeline(filter: filter).items.map { $0.toDomain() }
    }

    func getSupportDiagnostics() async throws -> AdminSupportDiagnosticsReport {
        try await api.getSupportDiagnostics().report.toDomain()
    }
}
