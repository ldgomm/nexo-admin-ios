//
//  DashboardView.swift
//  Nexo Admin
//
//  Created by José Ruiz on 2/6/26.
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
                    NexoAdminUXLoadingState(
                        title: "Cargando inicio…",
                        message: "Estamos preparando ventas, caja, documentos, alertas y acciones rápidas."
                    )

                case .empty(let message):
                    emptyContent(message)

                case .failed(let message):
                    ScrollView {
                        NexoAdminUXEmptyState(
                            systemImage: "wifi.exclamationmark",
                            title: "No se pudo cargar el inicio",
                            message: message,
                            actionTitle: "Reintentar"
                        ) {
                            Task { await viewModel.refresh() }
                        }
                        .padding(16)
                    }

                case .loaded(let summary):
                    dashboardContent(summary)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Inicio")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NexoAdminUXRefreshButton(isLoading: viewModel.isRefreshing) {
                        Task { await viewModel.refresh() }
                    }
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
            LazyVStack(alignment: .leading, spacing: 16) {
                DashboardExecutiveHeader(
                    userDisplayName: viewModel.userDisplayName,
                    organizationTitle: viewModel.organizationTitle,
                    periodSubtitle: viewModel.periodSubtitle,
                    criticalAlertCount: viewModel.criticalAlertCount,
                    isRefreshing: viewModel.isRefreshing
                )

                DashboardPeriodPicker(selection: $viewModel.selectedPeriod)
                    .padding(.horizontal, 2)

                if viewModel.criticalAlertCount > 0 {
                    DashboardPriorityCard(alertCount: viewModel.criticalAlertCount) {
                        if let destination = viewModel.visibleAlerts.compactMap(\.destination).first {
                            onQuickAction(destination)
                        }
                    }
                }

                NexoAdminUXCard {
                    NexoAdminUXSectionHeader(
                        "Acciones rápidas",
                        subtitle: viewModel.visibleQuickActions.isEmpty ? "No hay acciones disponibles con los permisos actuales." : "Atajos claros para resolver lo más frecuente.",
                        systemImage: "bolt.fill"
                    )
                    QuickActionsSection(actions: viewModel.visibleQuickActions) { action in
                        onQuickAction(action.destination)
                    }
                }

                NexoAdminUXCard {
                    NexoAdminUXSectionHeader(
                        "Métricas del periodo",
                        subtitle: "Resumen rápido para saber si el negocio está sano sin abrir cinco pantallas.",
                        systemImage: "chart.bar.xaxis"
                    )
                    SummaryMetricsGrid(summary: summary)
                }

                NexoAdminUXCard {
                    NexoAdminUXSectionHeader(
                        "Operación",
                        subtitle: "Caja, cuentas por cobrar, documentos y firma; lo que puede bloquear el día.",
                        systemImage: "rectangle.3.group"
                    )
                    DashboardOperationalStrip(summary: summary)
                    CashSummaryCard(cash: summary.cash, pendingReceivables: summary.pendingReceivables)
                    DocumentsSummaryCard(documents: summary.documents)
                    SignatureStatusCard(signature: summary.signature) {
                        onQuickAction(.signature)
                    }
                }

                NexoAdminUXCard {
                    NexoAdminUXSectionHeader(
                        "Alertas",
                        subtitle: viewModel.visibleAlerts.isEmpty ? "Sin alertas críticas por ahora." : "Revisa primero lo que puede afectar ventas, caja o documentos.",
                        systemImage: viewModel.visibleAlerts.isEmpty ? "checkmark.seal" : "exclamationmark.triangle"
                    )
                    AlertsSection(alerts: viewModel.visibleAlerts) { alert in
                        if let destination = alert.destination {
                            onQuickAction(destination)
                        }
                    }
                }

                NexoAdminUXCard {
                    NexoAdminUXSectionHeader(
                        "Productos destacados",
                        subtitle: "Lo que más se mueve ayuda a decidir compras, stock y menú.",
                        systemImage: "star.square.on.square"
                    )
                    TopItemsSection(items: summary.topItems)
                }
            }
            .padding(16)
        }
        .refreshable { await viewModel.refresh() }
    }

    private func emptyContent(_ message: String) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                DashboardExecutiveHeader(
                    userDisplayName: viewModel.userDisplayName,
                    organizationTitle: viewModel.organizationTitle,
                    periodSubtitle: viewModel.periodSubtitle,
                    criticalAlertCount: 0,
                    isRefreshing: viewModel.isRefreshing
                )

                DashboardPeriodPicker(selection: $viewModel.selectedPeriod)
                    .padding(.horizontal, 2)

                NexoAdminUXEmptyState(
                    systemImage: "chart.bar.doc.horizontal",
                    title: "Todavía no hay movimiento",
                    message: message
                )

                NexoAdminUXCard {
                    NexoAdminUXSectionHeader(
                        "Acciones rápidas",
                        subtitle: viewModel.visibleQuickActions.isEmpty ? "No hay acciones disponibles con los permisos actuales." : "Atajos claros para empezar.",
                        systemImage: "bolt.fill"
                    )
                    QuickActionsSection(actions: viewModel.visibleQuickActions) { action in
                        onQuickAction(action.destination)
                    }
                }
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .refreshable { await viewModel.refresh() }
    }
}

private struct DashboardExecutiveHeader: View {
    let userDisplayName: String
    let organizationTitle: String
    let periodSubtitle: String
    let criticalAlertCount: Int
    let isRefreshing: Bool

    var body: some View {
        NexoAdminUXHeroCard(
            eyebrow: "Panel operativo",
            title: greetingTitle,
            subtitle: "\(organizationTitle) · \(periodSubtitle)",
            systemImage: "rectangle.grid.2x2.fill",
            badgeTitle: criticalAlertCount > 0 ? "\(criticalAlertCount) alerta\(criticalAlertCount == 1 ? "" : "s")" : "Todo claro",
            badgeSystemImage: criticalAlertCount > 0 ? "exclamationmark.triangle.fill" : "checkmark.seal.fill",
            isBusy: isRefreshing
        )
    }

    private var greetingTitle: String {
        let trimmed = userDisplayName.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return "Estado del negocio" }
        return "Hola, \(trimmed)"
    }
}

private struct DashboardPriorityCard: View {
    let alertCount: Int
    let action: () -> Void

    var body: some View {
        NexoAdminUXInlineMessage(
            title: "Hay algo que revisar ahora",
            message: "Tienes \(alertCount) alerta\(alertCount == 1 ? "" : "s") que puede afectar operación, documentos o configuración. Entra primero ahí antes de seguir navegando.",
            tone: .warning
        )
        .onTapGesture(perform: action)
        .accessibilityAddTraits(.isButton)
    }
}
