//
//  AdminOperationsViewModel.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import Combine
import Foundation

@MainActor
final class AdminOperationsViewModel: ObservableObject {
    enum Section: String, CaseIterable, Identifiable {
        case snapshot
        case overview
        case cash
        case reports
        case audit

        var id: String { rawValue }
        var title: String {
            switch self {
            case .snapshot: return "Snapshot"
            case .overview: return "Hoy"
            case .cash: return "Caja"
            case .reports: return "Reportes"
            case .audit: return "Auditoría"
            }
        }
    }

    @Published var selectedSection: Section = .snapshot
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var todayReport: AdminOperationalTodayReport?
    @Published private(set) var currentCashSession: AdminCashSession?
    @Published private(set) var cashSessions: [AdminCashSession] = []
    @Published private(set) var salesSummary: AdminSalesSummaryReport?
    @Published private(set) var cashSummary: AdminCashSummaryReport?
    @Published private(set) var auditLogs: [AdminAuditLogRecord] = []
    @Published private(set) var timeline: [AdminAuditTimelineItem] = []
    @Published private(set) var diagnostics: AdminSupportDiagnosticsReport?

    @Published var reportRange: AdminOperationsDateRange = .today()
    @Published var auditFilter = AdminAuditFilter()
    @Published var cashStatusFilter: String = ""

    let permissions: Set<String>
    private let repository: any AdminOperationsRepository

    init(repository: any AdminOperationsRepository, permissions: Set<String>) {
        self.repository = repository
        self.permissions = permissions
    }

    var canViewCash: Bool {
        canAny([PermissionCatalog.cashViewCurrent, PermissionCatalog.cashViewHistory, PermissionCatalog.cashView, PermissionCatalog.reportsCash, PermissionCatalog.reportsCashView])
    }

    var canViewReports: Bool {
        canAny([PermissionCatalog.reportsToday, PermissionCatalog.reportsSales, PermissionCatalog.reportsDashboardView, PermissionCatalog.reportsSalesView])
    }

    var canViewAudit: Bool {
        canAny([PermissionCatalog.auditView, PermissionCatalog.supportDiagnosticsView])
    }

    var hasAnyAccess: Bool { canViewCash || canViewReports || canViewAudit }

    var operationalCashSession: AdminCashSession? {
        currentCashSession ?? todayReport?.currentCashSession
    }

    var readinessTitle: String {
        guard let diagnostics else { return "Readiness operativo no cargado" }
        return diagnostics.status.nexoReadableKey
    }

    var readinessChecks: [AdminSupportDiagnosticCheck] {
        diagnostics?.checks ?? []
    }

    var readinessCounters: [AdminSupportCounter] {
        diagnostics?.counters ?? []
    }

    var recentSalesEvents: [AdminOperationalSnapshotEvent] {
        snapshotEvents(
            matching: ["sale", "sales", "venta", "ventas", "quick_sale", "sale.created", "sale.confirmed", "sale.cancelled"],
            icon: "cart.fill"
        )
    }

    var recentPaymentEvents: [AdminOperationalSnapshotEvent] {
        snapshotEvents(
            matching: ["payment", "payments", "pago", "pagos", "payment.registered", "receivable.payment_registered", "cash.movement"],
            icon: "creditcard.fill"
        )
    }

    var recentDocumentEvents: [AdminOperationalSnapshotEvent] {
        snapshotEvents(
            matching: ["document", "documents", "electronic_document", "invoice", "factura", "sri", "ride", "xml", "authorization"],
            excludingSeverities: ["error", "critical"],
            icon: "doc.text.fill"
        )
    }

    var documentErrorEvents: [AdminOperationalSnapshotEvent] {
        snapshotEvents(
            matching: ["document", "documents", "electronic_document", "invoice", "factura", "sri", "ride", "xml", "authorization", "rejected", "failed", "error"],
            requiringSeverities: ["warning", "error", "critical"],
            icon: "exclamationmark.triangle.fill"
        )
    }

    var inventoryAlertEvents: [AdminOperationalSnapshotEvent] {
        let alertEvents = (todayReport?.alerts ?? [])
            .filter { $0.matchesAny(["inventory", "inventario", "stock", "low_stock", "adjustment", "movement"]) }
            .map { alert in
                AdminOperationalSnapshotEvent(
                    id: "alert-\(alert.code)",
                    title: alert.message,
                    subtitle: alert.actionHint ?? "Alerta operativa",
                    occurredAt: todayReport?.businessDate ?? "Hoy",
                    severity: alert.severity,
                    systemImage: "shippingbox.fill"
                )
            }

        return (alertEvents + snapshotEvents(
            matching: ["inventory", "inventario", "stock", "low_stock", "adjustment", "movement"],
            icon: "shippingbox.fill"
        )).deduplicatedById().prefixArray(5)
    }

    var recentExportEvents: [AdminOperationalSnapshotEvent] {
        snapshotEvents(
            matching: ["export", "exports", "export.daily", "csv", "zip", "downloaded", "generated"],
            icon: "square.and.arrow.down.fill"
        )
    }

    var basicAuditEvents: [AdminOperationalSnapshotEvent] {
        let timelineEvents = timeline.prefix(6).map { AdminOperationalSnapshotEvent(timeline: $0, systemImage: "list.bullet.rectangle.fill") }
        let logEvents = auditLogs.prefix(6).map { AdminOperationalSnapshotEvent(log: $0, systemImage: "list.bullet.rectangle.fill") }
        return Array((timelineEvents + logEvents).deduplicatedById().prefix(6))
    }

    private func snapshotEvents(
        matching keywords: [String],
        requiringSeverities: Set<String> = [],
        excludingSeverities: Set<String> = [],
        icon: String
    ) -> [AdminOperationalSnapshotEvent] {
        let normalizedRequired = Set(requiringSeverities.map { $0.lowercased() })
        let normalizedExcluded = Set(excludingSeverities.map { $0.lowercased() })

        let timelineEvents = timeline
            .filter { item in
                item.matchesAny(keywords)
                    && severityAllowed(item.severity, required: normalizedRequired, excluded: normalizedExcluded)
            }
            .map { AdminOperationalSnapshotEvent(timeline: $0, systemImage: icon) }

        let logEvents = auditLogs
            .filter { log in
                log.matchesAny(keywords)
                    && severityAllowed(log.severity, required: normalizedRequired, excluded: normalizedExcluded)
            }
            .map { AdminOperationalSnapshotEvent(log: $0, systemImage: icon) }

        return Array((timelineEvents + logEvents).deduplicatedById().prefix(5))
    }

    private func severityAllowed(_ severity: String, required: Set<String>, excluded: Set<String>) -> Bool {
        let normalized = severity.lowercased()
        if !required.isEmpty, !required.contains(normalized) { return false }
        if excluded.contains(normalized) { return false }
        return true
    }

    func loadInitial() async {
        await refresh()
    }

    func refresh() async {
        guard hasAnyAccess else {
            errorMessage = "Tu usuario no tiene permisos para caja, reportes o auditoría."
            return
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            if canViewReports {
                async let today = repository.getOperationalToday(date: nil, timezone: TimeZone.current.identifier)
                async let sales = repository.getSalesSummary(range: reportRange)
                async let cash = repository.getCashSummary(range: reportRange)
                todayReport = try await today
                salesSummary = try await sales
                cashSummary = try await cash
            }

            if canViewCash {
                async let current = repository.getCurrentCashSession(branchId: nil)
                async let history = repository.listCashSessions(
                    range: reportRange,
                    status: cashStatusFilter.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : cashStatusFilter,
                    limit: 50
                )
                currentCashSession = try await current
                cashSessions = try await history
            }

            if canViewAudit {
                async let logs = repository.searchAuditLogs(filter: auditFilter)
                async let timelineItems = repository.getAuditTimeline(filter: auditFilter)
                async let support = repository.getSupportDiagnostics()
                auditLogs = try await logs
                timeline = try await timelineItems
                diagnostics = try await support
            }
        } catch {
            errorMessage = error.userFriendlyMessage
        }
    }

    func applyTodayRange() {
        reportRange = .today()
        auditFilter.range = reportRange
    }

    func applyLastSevenDaysRange() {
        reportRange = .lastSevenDays()
        auditFilter.range = reportRange
    }

    func applyLastThirtyDaysRange() {
        reportRange = .lastThirtyDays()
        auditFilter.range = reportRange
    }

    func applyAuditQuickFilter(surface: String) {
        auditFilter.surface = surface
    }

    private func canAny(_ required: Set<String>) -> Bool {
        permissions.contains(PermissionCatalog.all) || !permissions.isDisjoint(with: required)
    }
}

struct AdminOperationalSnapshotEvent: Identifiable, Equatable, Sendable {
    let id: String
    let title: String
    let subtitle: String
    let occurredAt: String
    let severity: String
    let systemImage: String

    init(
        id: String,
        title: String,
        subtitle: String,
        occurredAt: String,
        severity: String,
        systemImage: String
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.occurredAt = occurredAt
        self.severity = severity
        self.systemImage = systemImage
    }

    init(timeline: AdminAuditTimelineItem, systemImage: String) {
        self.id = "timeline-\(timeline.id)"
        self.title = timeline.title
        self.subtitle = timeline.description
        self.occurredAt = timeline.occurredAt
        self.severity = timeline.severity
        self.systemImage = systemImage
    }

    init(log: AdminAuditLogRecord, systemImage: String) {
        self.id = "audit-\(log.id)"
        self.title = log.title
        self.subtitle = log.subtitle.nexo21g_ifBlank(log.message ?? log.reason ?? "Evento de auditoría")
        self.occurredAt = log.createdAt
        self.severity = log.severity
        self.systemImage = systemImage
    }
}

private extension AdminAuditTimelineItem {
    func matchesAny(_ keywords: [String]) -> Bool {
        [title, description, source, surface, targetType, targetId, reason]
            .compactMap { $0 }
            .joined(separator: " ")
            .nexo21g_containsAnyKeyword(keywords)
            || metadata.values.compactMap { $0 }.joined(separator: " ").nexo21g_containsAnyKeyword(keywords)
    }
}

private extension AdminAuditLogRecord {
    func matchesAny(_ keywords: [String]) -> Bool {
        [action, source, surface, targetType, targetId, reason, message]
            .compactMap { $0 }
            .joined(separator: " ")
            .nexo21g_containsAnyKeyword(keywords)
            || before.values.compactMap { $0 }.joined(separator: " ").nexo21g_containsAnyKeyword(keywords)
            || after.values.compactMap { $0 }.joined(separator: " ").nexo21g_containsAnyKeyword(keywords)
            || metadata.values.compactMap { $0 }.joined(separator: " ").nexo21g_containsAnyKeyword(keywords)
    }
}

private extension AdminOperationalAlert {
    func matchesAny(_ keywords: [String]) -> Bool {
        [code, severity, message, actionHint]
            .compactMap { $0 }
            .joined(separator: " ")
            .nexo21g_containsAnyKeyword(keywords)
    }
}

private extension String {
    func nexo21g_containsAnyKeyword(_ keywords: [String]) -> Bool {
        let normalized = lowercased()
        return keywords.contains { normalized.contains($0.lowercased()) }
    }

    func nexo21g_ifBlank(_ fallback: String) -> String {
        trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? fallback : self
    }
}

private extension Array where Element == AdminOperationalSnapshotEvent {
    func deduplicatedById() -> [AdminOperationalSnapshotEvent] {
        var seen = Set<String>()
        return filter { event in
            if seen.contains(event.id) { return false }
            seen.insert(event.id)
            return true
        }
    }

    func prefixArray(_ maxLength: Int) -> [AdminOperationalSnapshotEvent] {
        Array(prefix(maxLength))
    }
}
