//
//  AdminOperationsAPI.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import Foundation

protocol AdminOperationsAPI: Sendable {
    func getOperationalToday(date: Date?, timezone: String) async throws -> AdminOperationalTodayReportDTO
    func getSalesSummary(range: AdminOperationsDateRange) async throws -> AdminSalesSummaryReportDTO
    func getCashSummary(range: AdminOperationsDateRange) async throws -> AdminCashSummaryReportDTO
    func getCurrentCashSession(branchId: String?) async throws -> AdminCashSessionEnvelopeResponseDTO
    func listCashSessions(range: AdminOperationsDateRange, status: String?, limit: Int) async throws -> AdminCashSessionsResponseDTO
    func searchAuditLogs(filter: AdminAuditFilter) async throws -> AdminAuditLogsResponseDTO
    func getAuditTimeline(filter: AdminAuditFilter) async throws -> AdminAuditTimelineResponseDTO
    func getSupportDiagnostics() async throws -> AdminSupportDiagnosticsResponseDTO
}

struct RemoteAdminOperationsAPI: AdminOperationsAPI {
    let apiClient: APIClient

    func getOperationalToday(date: Date?, timezone: String) async throws -> AdminOperationalTodayReportDTO {
        var queryItems = [URLQueryItem(name: "timezone", value: timezone)]
        if let date {
            queryItems.append(URLQueryItem(name: "date", value: Self.dayFormatter.string(from: date)))
        }
        return try await apiClient.send(
            APIEndpoint(path: "/api/v1/admin/reports/operational-today", method: .get, queryItems: queryItems, requiresOrganization: true)
        )
    }

    func getSalesSummary(range: AdminOperationsDateRange) async throws -> AdminSalesSummaryReportDTO {
        try await apiClient.send(
            APIEndpoint(path: "/api/v1/admin/reports/sales-summary", method: .get, queryItems: range.queryItems, requiresOrganization: true)
        )
    }

    func getCashSummary(range: AdminOperationsDateRange) async throws -> AdminCashSummaryReportDTO {
        try await apiClient.send(
            APIEndpoint(path: "/api/v1/admin/reports/cash-summary", method: .get, queryItems: range.queryItems, requiresOrganization: true)
        )
    }

    func getCurrentCashSession(branchId: String?) async throws -> AdminCashSessionEnvelopeResponseDTO {
        var queryItems: [URLQueryItem] = []
        append(&queryItems, "branchId", branchId)
        return try await apiClient.send(
            APIEndpoint(path: "/api/v1/admin/cash-sessions/current", method: .get, queryItems: queryItems, requiresOrganization: true)
        )
    }

    func listCashSessions(range: AdminOperationsDateRange, status: String?, limit: Int) async throws -> AdminCashSessionsResponseDTO {
        var items = range.queryItems
        append(&items, "status", status)
        append(&items, "limit", String(limit))
        return try await apiClient.send(
            APIEndpoint(path: "/api/v1/admin/cash-sessions", method: .get, queryItems: items, requiresOrganization: true)
        )
    }

    func searchAuditLogs(filter: AdminAuditFilter) async throws -> AdminAuditLogsResponseDTO {
        try await apiClient.send(
            APIEndpoint(path: "/api/v1/admin/audit/logs", method: .get, queryItems: filter.queryItems, requiresOrganization: true)
        )
    }

    func getAuditTimeline(filter: AdminAuditFilter) async throws -> AdminAuditTimelineResponseDTO {
        try await apiClient.send(
            APIEndpoint(path: "/api/v1/admin/audit/timeline", method: .get, queryItems: filter.queryItems, requiresOrganization: true)
        )
    }

    func getSupportDiagnostics() async throws -> AdminSupportDiagnosticsResponseDTO {
        try await apiClient.send(
            APIEndpoint(path: "/api/v1/admin/support/diagnostics", method: .get, requiresOrganization: true)
        )
    }

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private func append(_ items: inout [URLQueryItem], _ name: String, _ value: String?) {
        guard let value = value?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty else { return }
        items.append(URLQueryItem(name: name, value: value))
    }
}

private extension AdminOperationsDateRange {
    var queryItems: [URLQueryItem] {
        [
            URLQueryItem(name: "from", value: ISO8601DateFormatter.api.string(from: from)),
            URLQueryItem(name: "to", value: ISO8601DateFormatter.api.string(from: to)),
            URLQueryItem(name: "timezone", value: timezone),
        ]
    }
}

private extension AdminAuditFilter {
    var queryItems: [URLQueryItem] {
        var items = range.queryItems
        append(&items, "q", query)
        append(&items, "actorUserId", actorUserId)
        append(&items, "action", action)
        append(&items, "surface", surface)
        append(&items, "targetType", targetType)
        append(&items, "targetId", targetId)
        append(&items, "severity", severity)
        append(&items, "limit", String(limit))
        return items
    }

    private func append(_ items: inout [URLQueryItem], _ name: String, _ value: String) {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        items.append(URLQueryItem(name: name, value: trimmed))
    }
}

private extension ISO8601DateFormatter {
    static let api: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withDashSeparatorInDate, .withColonSeparatorInTime]
        return formatter
    }()
}
