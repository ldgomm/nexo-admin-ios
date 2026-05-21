//
//  DashboardViewModel.swift
//  Nexo Admin
//
//  Created by José Ruiz on 20/5/26.
//

import Combine
import Foundation

@MainActor
final class DashboardViewModel: ObservableObject {
    @Published private(set) var state: LoadableViewState<DashboardSummary> = .idle
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

    func load() async {
        if case .loaded = state { return }
        await refresh()
    }

    func refresh() async {
        state = .loading
        do {
            let summary = try await getSummary.execute(period: selectedPeriod)
            if isEffectivelyEmpty(summary) {
                state = .empty("Todavía no hay datos operativos para este periodo.")
            } else {
                state = .loaded(summary)
            }
        } catch {
            state = .failed(error.userFriendlyMessage)
        }
    }

    func changePeriod(_ period: DashboardPeriod) async {
        guard selectedPeriod != period else { return }
        selectedPeriod = period
        await refresh()
    }

    private func isEffectivelyEmpty(_ summary: DashboardSummary) -> Bool {
        summary.sales.salesCount == 0
            && summary.sales.pendingCount == 0
            && summary.cash.status.lowercased() != "open"
            && summary.documents.pendingCount == 0
            && summary.documents.rejectedCount == 0
            && summary.alerts.isEmpty
    }
}

private extension String {
    var nonEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
