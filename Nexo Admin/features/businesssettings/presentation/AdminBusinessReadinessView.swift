//
//  AdminBusinessReadinessView.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import SwiftUI

struct AdminBusinessReadinessView: View {
    @ObservedObject var viewModel: AdminBusinessViewModel

    var body: some View {
        List {
            restaurantReadinessSection

            if let readiness = viewModel.readiness {
                Section {
                    HStack {
                        Image(systemName: readiness.ready ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                            .font(.title2)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(readiness.ready ? "Negocio operable" : "Configuración incompleta")
                                .font(.headline)
                            Text("Generado: \(readiness.generatedAt)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                Section("Checks") {
                    ForEach(readiness.checks) { check in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(check.code.readableSnakeCase)
                                    .font(.subheadline.weight(.semibold))
                                Spacer()
                                AdminBusinessStatusBadge(
                                    title: check.status.title,
                                    systemImage: check.status == .ready ? "checkmark.circle.fill" : "exclamationmark.circle.fill",
                                    emphasis: check.status != .ready
                                )
                            }
                            Text(check.message)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            if let action = check.action {
                                Text(action)
                                    .font(.caption.weight(.semibold))
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            } else {
                EmptyStateView(systemImage: "checklist.checked", title: "Sin readiness", message: "Carga la configuración del negocio para revisar el checklist operativo.")
            }
        }
        .navigationTitle("Readiness")
        .task { await viewModel.loadRestaurantReadiness(branchId: viewModel.primaryBranchId) }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Actualizar") {
                    Task {
                        await viewModel.refresh()
                        await viewModel.refreshRestaurantReadiness(branchId: viewModel.primaryBranchId)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var restaurantReadinessSection: some View {
        Section("Restaurante v1") {
            if viewModel.isLoadingRestaurantReadiness && viewModel.restaurantReadiness == nil {
                HStack(spacing: 10) {
                    ProgressView()
                    Text("Leyendo readiness restaurante…")
                        .foregroundStyle(.secondary)
                }
            } else if let readiness = viewModel.restaurantReadiness {
                AdminRestaurantReadinessSummaryView(readiness: readiness)

                if let tables = readiness.tables {
                    AdminRestaurantTablesSummaryView(summary: tables)
                }

                if readiness.hasBlockers {
                    AdminRestaurantReadinessMessageList(
                        title: "Blockers",
                        systemImage: "xmark.octagon.fill",
                        messages: readiness.blockers
                    )
                }

                if readiness.hasWarnings {
                    AdminRestaurantReadinessMessageList(
                        title: "Warnings",
                        systemImage: "exclamationmark.triangle.fill",
                        messages: readiness.warnings
                    )
                }
            } else if let error = viewModel.restaurantReadinessErrorMessage {
                VStack(alignment: .leading, spacing: 8) {
                    Label("No se pudo cargar Restaurante v1", systemImage: "wifi.exclamationmark")
                        .font(.subheadline.weight(.semibold))
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                Text("Readiness restaurante pendiente de cargar.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }

        if let readiness = viewModel.restaurantReadiness {
            Section("Checks restaurante") {
                ForEach(readiness.checks) { check in
                    AdminRestaurantReadinessCheckRow(check: check)
                }
            }

            Section("Componentes de soporte") {
                ForEach(readiness.components) { component in
                    AdminRestaurantReadinessComponentRow(component: component)
                }
            }

            if !readiness.supportLinks.isEmpty {
                Section("Links de evidencia") {
                    ForEach(readiness.supportLinks) { link in
                        AdminRestaurantSupportLinkRow(link: link)
                    }
                }
            }
        }
    }
}

private struct AdminRestaurantReadinessSummaryView: View {
    let readiness: AdminRestaurantReadiness

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                Image(systemName: readiness.overallStatus.systemImage)
                    .font(.title2)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Restaurante v1 \(readiness.overallStatus.title.lowercased())")
                        .font(.headline)
                    Text(readiness.ready ? "Puede avanzar a smoke si no hay blockers." : "No avanzar a smoke hasta resolver blockers.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                AdminBusinessStatusBadge(
                    title: readiness.overallStatus.title,
                    systemImage: readiness.overallStatus.systemImage,
                    emphasis: readiness.overallStatus.isEmphasis
                )
            }

            Label("Admin es solo diagnóstico: no abre, cierra, cancela mesas, cobra ni factura.", systemImage: "eye")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            if !readiness.capabilities.isEmpty {
                Text("Capabilities: \(readiness.capabilities.joined(separator: ", "))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct AdminRestaurantTablesSummaryView: View {
    let summary: AdminRestaurantTableSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Mesas opcionales")
                .font(.subheadline.weight(.semibold))
            HStack(spacing: 10) {
                AdminRestaurantMetricPill(title: "Total", value: "\(summary.total)")
                AdminRestaurantMetricPill(title: "Libres", value: "\(summary.available)")
                AdminRestaurantMetricPill(title: "Ocupadas", value: "\(summary.occupied)")
                AdminRestaurantMetricPill(title: "Abiertas", value: "\(summary.openSessions)")
            }
            if summary.hasOpenSessions {
                Label("Hay sesiones abiertas. Es normal en operación; validar antes del smoke.", systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct AdminRestaurantMetricPill: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.subheadline.weight(.bold))
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

private struct AdminRestaurantReadinessCheckRow: View {
    let check: AdminRestaurantReadinessCheck

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(check.code.readableSnakeCase)
                    .font(.subheadline.weight(.semibold))
                Spacer()
                AdminBusinessStatusBadge(
                    title: check.status.title,
                    systemImage: check.status.systemImage,
                    emphasis: check.status.isEmphasis
                )
            }
            Text(check.message)
                .font(.caption)
                .foregroundStyle(.secondary)
            if check.blocking {
                Label("Bloqueante", systemImage: "lock.fill")
                    .font(.caption2.weight(.semibold))
            }
            if !check.details.isEmpty {
                Text(check.details.map { "\($0.key): \($0.value)" }.sorted().joined(separator: " • "))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct AdminRestaurantReadinessComponentRow: View {
    let component: AdminRestaurantReadinessComponent

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(component.code.readableSnakeCase)
                    .font(.subheadline.weight(.semibold))
                Spacer()
                AdminBusinessStatusBadge(
                    title: component.status.title,
                    systemImage: component.status.systemImage,
                    emphasis: component.status.isEmphasis
                )
            }
            if let path = component.path {
                Text(path)
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
            }
            if component.supportOnly {
                Label("Support-only", systemImage: "eye")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct AdminRestaurantSupportLinkRow: View {
    let link: AdminRestaurantSupportLink

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(link.label)
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text(link.method)
                    .font(.caption.monospaced().weight(.semibold))
            }
            Text(link.path)
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)
            if link.supportOnly {
                Text("Solo soporte / diagnóstico")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct AdminRestaurantReadinessMessageList: View {
    let title: String
    let systemImage: String
    let messages: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: systemImage)
                .font(.subheadline.weight(.semibold))
            ForEach(messages, id: \.self) { message in
                Text("• \(message.readableSnakeCase)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
