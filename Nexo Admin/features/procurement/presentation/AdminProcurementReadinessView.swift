//
//  AdminProcurementReadinessView.swift
//  Nexo Admin
//
//  27R.N.1B — Procurement readiness and health summary.
//

import SwiftUI

struct AdminProcurementReadinessView: View {
    @StateObject var viewModel: AdminProcurementReadinessViewModel

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                content
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Readiness de compras")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NexoAdminUXRefreshButton(isLoading: isLoading) {
                    Task { await viewModel.refresh() }
                }
            }
        }
        .task { await viewModel.load() }
        .refreshable { await viewModel.refresh() }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            NexoAdminUXLoadingState(
                title: "Verificando compras…",
                message: "Leyendo módulos, permisos, reportes reconciliados y hechos financieros desde el backend."
            )
            .frame(minHeight: 420)

        case .empty(let message):
            retryState(title: "Sin readiness", message: message, systemImage: "shippingbox")

        case .failed(let message):
            retryState(title: "No se pudo verificar", message: message, systemImage: "wifi.exclamationmark")

        case .loaded(let report):
            readinessContent(report)
        }
    }

    private func readinessContent(_ report: AdminProcurementReadinessReport) -> some View {
        Group {
            NexoAdminUXHeroCard(
                eyebrow: "Control purchase-to-pay",
                title: report.summaryTitle,
                subtitle: "\(report.organizationName) · \(report.branchName) · \(report.summaryMessage)",
                systemImage: "shippingbox.and.arrow.forward.fill",
                badgeTitle: report.overallStatus.title,
                badgeSystemImage: report.overallStatus.systemImage
            )

            NexoAdminUXCard {
                NexoAdminUXSectionHeader(
                    "Resumen backend",
                    subtitle: "Los conteos, saldos y comprobaciones vienen de contratos canónicos; iOS no los recalcula.",
                    systemImage: "gauge.with.dots.needle.bottom.50percent"
                )
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    NexoAdminUXMetricTile(
                        title: "Reportes",
                        value: report.reportCount.map(String.init) ?? "—",
                        subtitle: "catálogo 27R.L.v1",
                        systemImage: "doc.text.magnifyingglass",
                        tint: .blue
                    )
                    NexoAdminUXMetricTile(
                        title: "CxP visibles",
                        value: report.matchingPayableCount.map(String.init) ?? "—",
                        subtitle: "abiertas o vencidas",
                        systemImage: "calendar.badge.exclamationmark",
                        tint: .orange
                    )
                    NexoAdminUXMetricTile(
                        title: "Saldo abierto",
                        value: report.openPayableBalance?.formatted ?? "—",
                        subtitle: report.currency,
                        systemImage: "banknote",
                        tint: (report.openPayableBalance?.amount ?? .zero) == .zero ? .green : .orange
                    )
                    NexoAdminUXMetricTile(
                        title: "Hechos financieros",
                        value: report.financeFactCount.map(String.init) ?? "—",
                        subtitle: "versionados, no contabilizados",
                        systemImage: "point.3.connected.trianglepath.dotted",
                        tint: .purple
                    )
                }
            }

            NexoAdminUXInlineMessage(
                title: "Frontera honesta",
                message: "Esta pantalla muestra salud operativa y hechos reproducibles. No genera asientos, no declara contabilidad oficial y no reemplaza la revisión de 28R/29R.",
                tone: .info
            )

            ForEach(report.sections) { section in
                NexoAdminUXCard {
                    NexoAdminUXSectionHeader(
                        section.title,
                        subtitle: "Listo, revisar o bloqueado según hechos del backend y permisos efectivos.",
                        systemImage: "checklist.checked"
                    )
                    VStack(spacing: 10) {
                        ForEach(section.checks) { check in
                            AdminProcurementReadinessRow(check: check)
                            if check.id != section.checks.last?.id { Divider() }
                        }
                    }
                }
            }
        }
    }

    private func retryState(title: String, message: String, systemImage: String) -> some View {
        NexoAdminUXEmptyState(
            systemImage: systemImage,
            title: title,
            message: message,
            actionTitle: "Reintentar"
        ) {
            Task { await viewModel.refresh() }
        }
        .frame(minHeight: 420)
    }

    private var isLoading: Bool {
        switch viewModel.state {
        case .idle, .loading: return true
        default: return false
        }
    }
}

private struct AdminProcurementReadinessRow: View {
    let check: AdminProcurementReadinessCheck

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: check.status.systemImage)
                .font(.headline)
                .foregroundStyle(tint)
                .frame(width: 30, height: 30)
                .background(tint.opacity(0.10), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline) {
                    Text(check.title)
                        .font(.subheadline.weight(.semibold))
                    Spacer(minLength: 8)
                    NexoAdminUXStatusBadge(
                        title: check.status.title,
                        systemImage: check.status.systemImage,
                        tint: tint
                    )
                }
                Text(check.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 3)
    }

    private var tint: Color {
        switch check.status {
        case .ready: return .green
        case .warning: return .orange
        case .blocked: return .red
        }
    }
}
