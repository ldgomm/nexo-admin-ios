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
        case overview
        case cash
        case reports
        case audit

        var id: String { rawValue }
        var title: String {
            switch self {
            case .overview: return "Hoy"
            case .cash: return "Caja"
            case .reports: return "Reportes"
            case .audit: return "Auditoría"
            }
        }
    }

    @Published var selectedSection: Section = .overview
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
