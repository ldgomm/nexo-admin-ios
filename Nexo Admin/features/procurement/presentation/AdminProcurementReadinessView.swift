//
//  AdminProcurementReadinessView.swift
//  Nexo Admin
//
//  Created by José Ruiz on 29/7/26.
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
                        subtitle: "legado reconciliado",
                        systemImage: "point.3.connected.trianglepath.dotted",
                        tint: .purple
                    )
                    NexoAdminUXMetricTile(
                        title: "Replay V1",
                        value: report.financeSourceFactSchemaVersion.map { "v\($0)" } ?? "—",
                        subtitle: report.financeSourceFactTypeCount.map { "\($0) familias · snapshot keyset" } ?? "No consultado",
                        systemImage: "arrow.triangle.2.circlepath.circle.fill",
                        tint: .indigo
                    )
                    NexoAdminUXMetricTile(
                        title: "Matriz contable",
                        value: report.accountingCompletenessMatrix.map { String($0.totalItemCount) } ?? "—",
                        subtitle: report.accountingCompletenessMatrix.map {
                            "\($0.passExistingCount) fuentes · \($0.futureGapCount) brechas · \($0.notApplicableCount) fuera de 27R"
                        } ?? "No consultada",
                        systemImage: "tablecells.badge.ellipsis",
                        tint: .teal
                    )
                }
            }

            NexoAdminUXInlineMessage(
                title: "Frontera honesta",
                message: "Esta pantalla verifica hechos y replay reproducibles sin exponer payloads. No genera asientos, no declara contabilidad oficial y no reemplaza la revisión de 28R/29R.",
                tone: .info
            )

            if let matrix = report.accountingCompletenessMatrix {
                AdminProcurementAccountingCompletenessCard(matrix: matrix)
            }

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

private struct AdminProcurementAccountingCompletenessCard: View {
    let matrix: AdminProcurementAccountingCompletenessMatrix

    var body: some View {
        NexoAdminUXCard {
            NexoAdminUXSectionHeader(
                "Matriz de completitud contable",
                subtitle: "Proyección runtime de la matriz aceptada en 27R.L.7; las brechas futuras permanecen visibles y no se reconstruyen.",
                systemImage: "tablecells.badge.ellipsis"
            )

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                NexoAdminUXMetricTile(
                    title: "Fuentes listas",
                    value: String(matrix.passExistingCount),
                    subtitle: "PASS_EXISTING",
                    systemImage: "checkmark.circle.fill",
                    tint: .green
                )
                NexoAdminUXMetricTile(
                    title: "Brechas futuras",
                    value: String(matrix.futureGapCount),
                    subtitle: "DOCUMENT_FUTURE_GAP",
                    systemImage: "exclamationmark.triangle.fill",
                    tint: .orange
                )
                NexoAdminUXMetricTile(
                    title: "Fuera de 27R",
                    value: String(matrix.notApplicableCount),
                    subtitle: "NOT_APPLICABLE",
                    systemImage: "arrow.forward.circle.fill",
                    tint: .secondary
                )
                NexoAdminUXMetricTile(
                    title: "Contrato",
                    value: matrix.matrixVersion,
                    subtitle: matrix.acceptedStage,
                    systemImage: "checkmark.seal.fill",
                    tint: .teal
                )
            }

            NexoAdminUXInlineMessage(
                title: "Sin inferencias",
                message: "Servicio, deducibilidad, capitalización, retenciones, ajustes, settlement no monetario, cuenta bancaria y FX siguen como brechas explícitas hasta que exista una fuente operativa aceptada.",
                tone: .info
            )

            VStack(spacing: 8) {
                ForEach(matrix.items) { item in
                    AdminProcurementAccountingCompletenessRow(item: item)
                    if item.id != matrix.items.last?.id { Divider() }
                }
            }
        }
    }
}

private struct AdminProcurementAccountingCompletenessRow: View {
    let item: AdminProcurementAccountingCompletenessItem

    var body: some View {
        DisclosureGroup {
            VStack(alignment: .leading, spacing: 8) {
                Text(item.authoritativeEvidence)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("Replay V1: \(item.v1ReplayStatus)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("Siguiente responsable: \(item.futureOwnerAction)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if let note = item.classificationNote, !note.isEmpty {
                    Text("Alcance: \(note)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(tint)
                }
            }
            .padding(.top, 6)
        } label: {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Image(systemName: item.classification.systemImage)
                    .foregroundStyle(tint)
                Text(item.displayTitle)
                    .font(.subheadline.weight(.semibold))
                Spacer(minLength: 8)
                NexoAdminUXStatusBadge(
                    title: item.classification.title,
                    systemImage: item.classification.systemImage,
                    tint: tint
                )
            }
        }
        .padding(.vertical, 3)
    }

    private var tint: Color {
        switch item.classification {
        case .passExisting: return .green
        case .documentFutureGap: return .orange
        case .notApplicable: return .secondary
        }
    }
}
