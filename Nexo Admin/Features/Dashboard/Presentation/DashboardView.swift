//
//  DashboardView.swift
//  Nexo Admin
//
//  Created by José Ruiz on 20/5/26.
//

import SwiftUI

struct DashboardView: View {
    @StateObject var viewModel: DashboardViewModel

    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.state {
                case .idle, .loading:
                    DashboardLoadingView()
                case .empty(let message):
                    ScrollView {
                        VStack(alignment: .leading, spacing: NexoTheme.cardSpacing) {
                            header
                            EmptyStateView(
                                systemImage: "chart.bar.doc.horizontal",
                                title: "Sin movimiento todavía",
                                message: message
                            )
                            quickActionsSection(actions: viewModel.visibleQuickActions)
                        }
                        .padding(NexoTheme.screenPadding)
                    }
                    .refreshable { await viewModel.refresh() }
                case .failed(let message):
                    ErrorStateView(
                        title: "No se pudo cargar el dashboard",
                        message: message,
                        retry: { Task { await viewModel.refresh() } }
                    )
                case .loaded(let summary):
                    dashboardContent(summary)
                        .refreshable { await viewModel.refresh() }
                }
            }
            .navigationTitle("Inicio")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { Task { await viewModel.refresh() } } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .accessibilityLabel("Actualizar dashboard")
                }
            }
            .task { await viewModel.load() }
        }
    }

    private func dashboardContent(_ summary: DashboardSummary) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: NexoTheme.cardSpacing) {
                header
                periodPicker
                SummaryMetricsGrid(summary: summary)
                AlertsSection(alerts: viewModel.visibleAlerts)
                SignatureStatusCard(signature: summary.signature)
                quickActionsSection(actions: viewModel.visibleQuickActions)
            }
            .padding(NexoTheme.screenPadding)
        }
    }

    private var header: some View {
        HCard {
            Text("Hola, \(viewModel.userDisplayName)")
                .font(.title2.bold())
            Text(viewModel.organizationTitle)
                .font(.headline)
                .foregroundStyle(Color.accentColor)
            Text("Ventas, caja, comprobantes, firma y alertas críticas en una sola vista.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var periodPicker: some View {
        Picker("Periodo", selection: $viewModel.selectedPeriod) {
            ForEach(DashboardPeriod.allCases) { period in
                Text(period.title).tag(period)
            }
        }
        .pickerStyle(.segmented)
        .onChange(of: viewModel.selectedPeriod) { newValue in
            Task { await viewModel.changePeriod(newValue) }
        }
    }

    private func quickActionsSection(actions: [DashboardQuickAction]) -> some View {
        HCard {
            Text("Accesos rápidos")
                .font(.headline)
            if actions.isEmpty {
                Text("No hay accesos disponibles con tus permisos actuales.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(actions) { action in
                        DashboardQuickActionCard(action: action)
                    }
                }
            }
        }
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
