//
//  AdminBusinessAppReadinessView.swift
//  Nexo Admin
//
//  Created by José Ruiz on 2/6/26.
//

import SwiftUI

struct AdminBusinessAppReadinessView: View {
    @StateObject var viewModel: AdminBusinessAppReadinessViewModel

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                content
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Business App")
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
                title: "Evaluando readiness…",
                message: "Revisando si Business puede operar con organización, sucursal, caja, ventas, permisos y documentos."
            )
            .frame(minHeight: 420)

        case .empty(let message):
            NexoAdminUXEmptyState(
                systemImage: "iphone.gen2.badge.play",
                title: "Sin readiness",
                message: message,
                actionTitle: "Actualizar"
            ) {
                Task { await viewModel.refresh() }
            }

        case .failed(let message):
            NexoAdminUXEmptyState(
                systemImage: "wifi.exclamationmark",
                title: "No se pudo evaluar",
                message: message,
                actionTitle: "Reintentar"
            ) {
                Task { await viewModel.refresh() }
            }

        case .loaded(let report):
            AdminBusinessAppReadinessHero(report: report)
            AdminBusinessAppReadinessMetrics(report: report)

            if report.readyForBusinessApp {
                NexoAdminUXInlineMessage(
                    title: "Business puede operar",
                    message: "La base crítica está lista. Aun así, ejecuta un smoke real antes de TestFlight o piloto.",
                    tone: .success
                )
            } else {
                NexoAdminUXInlineMessage(
                    title: "Business todavía no está listo",
                    message: "Resuelve primero los bloqueantes obligatorios. No conviene avanzar a piloto si una operación básica puede fallar.",
                    tone: .danger
                )
            }

            ForEach(report.sections) { section in
                NexoAdminUXCard {
                    NexoAdminUXSectionHeader(
                        section.title,
                        subtitle: "Checks claros: listo, advertencia, bloqueo o no aplica.",
                        systemImage: "checklist"
                    )
                    VStack(spacing: 10) {
                        ForEach(section.checks) { check in
                            AdminBusinessAppReadinessRow(check: check)
                            if check.id != section.checks.last?.id { Divider() }
                        }
                    }
                }
            }
        }
    }

    private var isLoading: Bool {
        switch viewModel.state {
        case .idle, .loading: return true
        default: return false
        }
    }
}

private struct AdminBusinessAppReadinessHero: View {
    let report: AdminBusinessAppReadinessReport

    var body: some View {
        NexoAdminUXHeroCard(
            eyebrow: "Readiness operativo",
            title: report.summaryTitle,
            subtitle: "\(report.organizationName) · \(report.summaryMessage)",
            systemImage: "iphone.gen2.badge.play",
            badgeTitle: report.readyForBusinessApp ? "Listo" : "Bloqueado",
            badgeSystemImage: report.readyForBusinessApp ? "checkmark.seal.fill" : "xmark.octagon.fill"
        )
    }
}

private struct AdminBusinessAppReadinessMetrics: View {
    let report: AdminBusinessAppReadinessReport

    var body: some View {
        NexoAdminUXCard {
            NexoAdminUXSectionHeader(
                "Resumen",
                subtitle: "Lo mínimo para decidir si se puede avanzar o no.",
                systemImage: "gauge.with.dots.needle.bottom.50percent"
            )

            ProgressView(value: readinessProgress)
                .progressViewStyle(.linear)
                .accessibilityLabel("Progreso de readiness")

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                NexoAdminUXMetricTile(
                    title: "Checks listos",
                    value: "\(report.readyCount)/\(report.totalChecks)",
                    subtitle: "Configuración válida",
                    systemImage: "checkmark.seal",
                    tint: .green
                )
                NexoAdminUXMetricTile(
                    title: "Advertencias",
                    value: "\(report.warningCount)",
                    subtitle: "No bloquean, pero importan",
                    systemImage: "exclamationmark.triangle",
                    tint: .orange
                )
                NexoAdminUXMetricTile(
                    title: "Bloqueantes",
                    value: "\(report.blockedRequiredCount)",
                    subtitle: "Obligatorios pendientes",
                    systemImage: "xmark.octagon",
                    tint: report.blockedRequiredCount > 0 ? .red : .green
                )
                NexoAdminUXMetricTile(
                    title: "Estado",
                    value: report.readyForBusinessApp ? "Operable" : "No listo",
                    subtitle: "Para Business App",
                    systemImage: report.readyForBusinessApp ? "iphone.gen2.badge.checkmark" : "iphone.gen2.badge.exclamationmark",
                    tint: report.readyForBusinessApp ? .green : .red
                )
            }
        }
    }

    private var readinessProgress: Double {
        guard report.totalChecks > 0 else { return 0 }
        return Double(report.readyCount) / Double(report.totalChecks)
    }
}

private struct AdminBusinessAppReadinessRow: View {
    let check: AdminBusinessAppReadinessCheck

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: check.status.systemImage)
                .font(.title3.weight(.semibold))
                .foregroundStyle(color)
                .frame(width: 34, height: 34)
                .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 11, style: .continuous))

            VStack(alignment: .leading, spacing: 5) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(check.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    if check.required {
                        Text("Obligatorio")
                            .font(.caption2.weight(.bold))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Color.orange.opacity(0.14), in: Capsule(style: .continuous))
                            .foregroundStyle(.orange)
                    }
                    Spacer(minLength: 0)
                }

                Text(check.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                if let actionTitle = check.actionTitle {
                    Label(actionTitle, systemImage: "arrow.right.circle")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.accentColor)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var color: Color {
        switch check.status {
        case .ready: return .green
        case .warning: return .orange
        case .blocked: return .red
        case .notApplicable: return .secondary
        case .unknown: return .secondary
        }
    }
}
 
