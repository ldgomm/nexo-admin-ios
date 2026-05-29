//
//  AdminOperationsRepository.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import Foundation

protocol AdminOperationsRepository: Sendable {
    func getOperationalToday(date: Date?, timezone: String) async throws -> AdminOperationalTodayReport
    func getSalesSummary(range: AdminOperationsDateRange) async throws -> AdminSalesSummaryReport
    func getCashSummary(range: AdminOperationsDateRange) async throws -> AdminCashSummaryReport
    func getCurrentCashSession(branchId: String?) async throws -> AdminCashSession?
    func listCashSessions(range: AdminOperationsDateRange, status: String?, limit: Int) async throws -> [AdminCashSession]
    func searchAuditLogs(filter: AdminAuditFilter) async throws -> [AdminAuditLogRecord]
    func getAuditTimeline(filter: AdminAuditFilter) async throws -> [AdminAuditTimelineItem]
    func getSupportDiagnostics() async throws -> AdminSupportDiagnosticsReport
}
