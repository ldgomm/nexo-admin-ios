//
//  DashboardViewModel.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import Combine
import Foundation

@MainActor
final class DashboardViewModel: ObservableObject {
    @Published private(set) var state: LoadableViewState<DashboardSummary> = .idle
    @Published private(set) var isRefreshing = false
    @Published var selectedPeriod: DashboardPeriod = .today

    private let getSummary: GetDashboardSummaryUseCase
    private let sessionStore: AuthSessionStore

    init(getSummary: GetDashboardSummaryUseCase, sessionStore: AuthSessionStore) {
        self.getSummary = getSummary
        self.sessionStore = sessionStore
    }

    var organizationTitle: String {
        sessionStore.activeOrganization?.commercialName.nonEmpty
            ?? sessionStore.activeOrganization?.legalName.nonEmpty
            ?? "Organización activa"
    }

    var userDisplayName: String {
        sessionStore.currentUser?.displayName.nonEmpty ?? "admin"
    }

    var periodSubtitle: String {
        switch selectedPeriod {
        case .today: return "Estado operativo de hoy"
        case .week: return "Resumen acumulado de la semana"
        case .month: return "Resumen acumulado del mes"
        }
    }

    var currentSummary: DashboardSummary? {
        guard case .loaded(let summary) = state else { return nil }
        return summary
    }

    var visibleQuickActions: [DashboardQuickAction] {
        let actions: [DashboardQuickAction]
        if case .loaded(let summary) = state {
            actions = summary.quickActions
        } else {
            actions = DashboardQuickActionsFactory.actions
        }
        return actions.filter { $0.isVisible(for: sessionStore.effectivePermissions) }
    }

    var visibleAlerts: [DashboardAlert] {
        guard case .loaded(let summary) = state else { return [] }
        return summary.alerts
    }

    var criticalAlertCount: Int {
        visibleAlerts.filter { $0.severity == .critical }.count
    }

    func load() async {
        if case .loaded = state { return }
        await refresh()
    }

    func refresh() async {
        let hadLoadedContent: Bool
        if case .loaded = state {
            hadLoadedContent = true
            isRefreshing = true
        } else {
            hadLoadedContent = false
            state = .loading
        }

        do {
            let summary = try await getSummary.execute(period: selectedPeriod)
            isRefreshing = false
            if isEffectivelyEmpty(summary) {
                state = .empty(selectedPeriod.emptyMessage)
            } else {
                state = .loaded(summary)
            }
        } catch {
            isRefreshing = false
            if hadLoadedContent {
                state = .failed(error.userFriendlyMessage)
            } else {
                state = .failed(error.userFriendlyMessage)
            }
        }
    }

    func changePeriod(_ period: DashboardPeriod) async {
        selectedPeriod = period
        await refresh()
    }

    private func isEffectivelyEmpty(_ summary: DashboardSummary) -> Bool {
        summary.sales.salesCount == 0
            && summary.sales.pendingCount == 0
            && summary.cash.status.lowercased() != "open"
            && summary.cash.openSessionCount == 0
            && summary.documents.pendingCount == 0
            && summary.documents.rejectedCount == 0
            && summary.pendingReceivables.amount == 0
            && summary.topItems.isEmpty
            && summary.alerts.isEmpty
    }
}

private extension String {
    var nonEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
