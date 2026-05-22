//
//  DashboardView.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import SwiftUI

struct DashboardView: View {
    @StateObject private var viewModel: DashboardViewModel
    private let onQuickAction: (DashboardQuickActionDestination) -> Void

    init(
        viewModel: DashboardViewModel,
        onQuickAction: @escaping (DashboardQuickActionDestination) -> Void = { _ in }
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onQuickAction = onQuickAction
    }

    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.state {
                case .idle, .loading:
                    DashboardLoadingView()
                case .empty(let message):
                    emptyContent(message)
                case .failed(let message):
                    ErrorStateView(
                        title: "No se pudo cargar el dashboard",
                        message: message,
                        retry: { Task { await viewModel.refresh() } }
                    )
                case .loaded(let summary):
                    dashboardContent(summary)
                }
            }
            .navigationTitle("Inicio")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { Task { await viewModel.refresh() } } label: {
                        if viewModel.isRefreshing {
                            ProgressView()
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                    .disabled(viewModel.isRefreshing)
                    .accessibilityLabel("Actualizar dashboard")
                }
            }
            .task { await viewModel.load() }
            .onChange(of: viewModel.selectedPeriod) { _, newValue in
                Task { await viewModel.changePeriod(newValue) }
            }
        }
    }

    private func dashboardContent(_ summary: DashboardSummary) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: NexoTheme.cardSpacing) {
                DashboardHeaderCard(
                    userDisplayName: viewModel.userDisplayName,
                    organizationTitle: viewModel.organizationTitle,
                    periodSubtitle: viewModel.periodSubtitle,
                    criticalAlertCount: viewModel.criticalAlertCount,
                    isRefreshing: viewModel.isRefreshing
                )
                DashboardPeriodPicker(selection: $viewModel.selectedPeriod)
                SummaryMetricsGrid(summary: summary)
                AlertsSection(alerts: viewModel.visibleAlerts) { alert in
                    if let destination = alert.destination {
                        onQuickAction(destination)
                    }
                }
                DashboardOperationalStrip(summary: summary)
                CashSummaryCard(cash: summary.cash, pendingReceivables: summary.pendingReceivables)
                DocumentsSummaryCard(documents: summary.documents)
                SignatureStatusCard(signature: summary.signature) {
                    onQuickAction(.signature)
                }
                TopItemsSection(items: summary.topItems)
                QuickActionsSection(actions: viewModel.visibleQuickActions) { action in
                    onQuickAction(action.destination)
                }
            }
            .padding(NexoTheme.screenPadding)
        }
        .refreshable { await viewModel.refresh() }
    }

    private func emptyContent(_ message: String) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: NexoTheme.cardSpacing) {
                DashboardHeaderCard(
                    userDisplayName: viewModel.userDisplayName,
                    organizationTitle: viewModel.organizationTitle,
                    periodSubtitle: viewModel.periodSubtitle,
                    criticalAlertCount: 0,
                    isRefreshing: viewModel.isRefreshing
                )
                DashboardPeriodPicker(selection: $viewModel.selectedPeriod)
                EmptyStateView(
                    systemImage: "chart.bar.doc.horizontal",
                    title: "Sin movimiento todavía",
                    message: message
                )
                QuickActionsSection(actions: viewModel.visibleQuickActions) { action in
                    onQuickAction(action.destination)
                }
            }
            .padding(NexoTheme.screenPadding)
        }
        .refreshable { await viewModel.refresh() }
    }
}

private struct DashboardLoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Cargando estado del negocio…")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
