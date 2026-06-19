//
//  AdminCatalogComponents.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import SwiftUI

struct AdminCatalogStatusBadge: View {
    let status: String

    var body: some View {
        Text(status.readableSnakeCase)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(background, in: Capsule())
            .foregroundStyle(foreground)
    }

    private var background: Color {
        switch status.uppercased() {
        case "ACTIVE", "APPROVED", "LINKED_TO_TEMPLATE": Color.green.opacity(0.16)
        case "PENDING", "NEEDS_MORE_INFO", "DRAFT": Color.orange.opacity(0.16)
        case "REJECTED", "REMOVED_FROM_ACCOUNT", "PAUSED": Color.red.opacity(0.14)
        default: Color.secondary.opacity(0.14)
        }
    }

    private var foreground: Color {
        switch status.uppercased() {
        case "ACTIVE", "APPROVED", "LINKED_TO_TEMPLATE": .green
        case "PENDING", "NEEDS_MORE_INFO", "DRAFT": .orange
        case "REJECTED", "REMOVED_FROM_ACCOUNT", "PAUSED": .red
        default: .secondary
        }
    }
}

struct AdminCatalogMetricCard: View {
    let title: String
    let value: String
    let subtitle: String
    let systemImage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: systemImage)
                    .font(.headline)
                Spacer()
                Text(value)
                    .font(.title2.bold())
            }
            Text(title)
                .font(.headline)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

struct AdminCatalogSectionHeader: View {
    let title: String
    let subtitle: String
    let systemImage: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: systemImage)
                .font(.title3.weight(.semibold))
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct AdminCatalogMoneyField: View {
    let title: String
    @Binding var amount: String
    @Binding var currency: String

    var body: some View {
        HStack {
            TextField(title, text: $amount)
                .keyboardType(.decimalPad)
            TextField("Moneda", text: $currency)
                .frame(width: 70)
                .textInputAutocapitalization(.characters)
                .multilineTextAlignment(.trailing)
        }
    }
}

struct AdminCatalogReasonSection: View {
    @Binding var reason: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField("Motivo del cambio", text: $reason, axis: .vertical)
                .lineLimit(2...4)
            Text("Las acciones de catálogo quedan auditadas para proteger precios, tax profiles y catálogo maestro.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

struct AdminCatalogSaveButton: View {
    let title: String
    let isSaving: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                if isSaving { ProgressView().controlSize(.small) }
                Text(title)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .disabled(isSaving)
    }
}

struct AdminCatalogItemRow: View {
    let item: AdminCatalogLocalItem

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.localName)
                        .font(.headline)
                    Text(item.primaryIdentifier ?? item.globalCatalogId ?? item.id)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(item.localPrice.formatted)
                    .font(.subheadline.weight(.semibold))
            }
            HStack {
                AdminCatalogStatusBadge(status: item.status)
                AdminCatalogSourceBadge(item: item)
                Text(item.type.readableSnakeCase)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(item.taxProfileId)
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct AdminCatalogRequestRow: View {
    let request: AdminCatalogRequest

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Text(request.requestedName)
                    .font(.headline)
                Spacer()
                AdminCatalogStatusBadge(status: request.status)
            }
            Text(request.description ?? "Sin descripción")
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
            HStack {
                Text(request.requestedType.readableSnakeCase)
                Spacer()
                Text(request.createdAt)
            }
            .font(.caption2)
            .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }
}

struct AdminCatalogDiagnosticsCard: View {
    let diagnostics: AdminCatalogDiagnostics
    let catalogRevision: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: diagnostics.status.systemImage)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(statusColor)
                    .frame(width: 32, height: 32)
                    .background(statusColor.opacity(0.14), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text(diagnostics.status.title)
                        .font(.headline)
                    Text(statusSubtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 8)

                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(diagnostics.score)%")
                        .font(.title3.bold())
                    Text("readiness")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                AdminCatalogMiniMetric(title: "Privados", value: "\(diagnostics.totalItems)", subtitle: "ítems del negocio", systemImage: "shippingbox")
                AdminCatalogMiniMetric(title: "Activos", value: "\(diagnostics.activeItems)", subtitle: "listos para vender", systemImage: "checkmark.seal")
                AdminCatalogMiniMetric(title: "Origen", value: "\(diagnostics.adoptedItems + diagnostics.seedItems)", subtitle: diagnostics.sourceSummary, systemImage: "doc.on.doc")
                AdminCatalogMiniMetric(title: "Revisión", value: catalogRevision?.trimmedOrNil ?? "—", subtitle: "catalogRevision", systemImage: "tag")
            }

            if !diagnostics.blockers.isEmpty || !diagnostics.warnings.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(diagnostics.blockers, id: \.self) { message in
                        AdminCatalogDiagnosticIssueRow(message: message, systemImage: "xmark.octagon.fill", tint: .red)
                    }
                    ForEach(diagnostics.warnings, id: \.self) { message in
                        AdminCatalogDiagnosticIssueRow(message: message, systemImage: "exclamationmark.triangle.fill", tint: .orange)
                    }
                }
            } else {
                AdminCatalogDiagnosticIssueRow(
                    message: "El catálogo privado tiene precio, tax profile y origen suficientes para el piloto.",
                    systemImage: "checkmark.circle.fill",
                    tint: .green
                )
            }
        }
        .padding(14)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var statusColor: Color {
        switch diagnostics.status {
        case .ready: .green
        case .review: .orange
        case .incomplete: .red
        }
    }

    private var statusSubtitle: String {
        switch diagnostics.status {
        case .ready:
            return "El negocio puede operar catálogo sin bloqueos visibles."
        case .review:
            return "Hay detalles que conviene revisar antes del smoke de piloto."
        case .incomplete:
            return "Faltan datos mínimos para vender con seguridad desde Business."
        }
    }
}

private struct AdminCatalogMiniMetric: View {
    let title: String
    let value: String
    let subtitle: String
    let systemImage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.caption.weight(.semibold))
                Text(title)
                    .font(.caption.weight(.semibold))
                Spacer(minLength: 0)
            }
            Text(value)
                .font(.headline)
            Text(subtitle)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct AdminCatalogDiagnosticIssueRow: View {
    let message: String
    let systemImage: String
    let tint: Color

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: systemImage)
                .foregroundStyle(tint)
                .frame(width: 18)
            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer(minLength: 0)
        }
    }
}

struct AdminCatalogSourceBadge: View {
    let item: AdminCatalogLocalItem

    var body: some View {
        Label(item.sourceDisplayTitle, systemImage: item.sourceSystemImage)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.secondary.opacity(0.10), in: Capsule())
            .foregroundStyle(.secondary)
    }
}
