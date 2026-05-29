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
                    Text(item.primaryIdentifier ?? item.globalCatalogId)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(item.localPrice.formatted)
                    .font(.subheadline.weight(.semibold))
            }
            HStack {
                AdminCatalogStatusBadge(status: item.status)
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
