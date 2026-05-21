//
//  AdminBusinessComponents.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import SwiftUI

struct AdminBusinessStatusBadge: View {
    let title: String
    let systemImage: String
    let emphasis: Bool

    var body: some View {
        Label(title, systemImage: systemImage)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(emphasis ? Color.primary.opacity(0.12) : Color.secondary.opacity(0.12), in: Capsule())
            .foregroundStyle(emphasis ? .primary : .secondary)
    }
}

struct AdminBusinessMetricCard: View {
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

struct AdminBusinessSectionHeader: View {
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

struct AdminBusinessReasonField: View {
    @Binding var reason: String

    var body: some View {
        Section("Auditoría") {
            TextField("Motivo del cambio", text: $reason, axis: .vertical)
                .lineLimit(2...4)
            Text("El backend audita cambios críticos de configuración. Usa un motivo claro.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

struct AdminBusinessSaveButton: View {
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

struct AdminBusinessActionReasonDialog: View {
    let title: String
    let message: String
    @Binding var reason: String
    let isSaving: Bool
    let confirmTitle: String
    let onConfirm: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(title)
                .font(.title2.bold())
            Text(message)
                .foregroundStyle(.secondary)
            TextField("Motivo", text: $reason, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(2...4)
            AdminBusinessSaveButton(title: confirmTitle, isSaving: isSaving, action: onConfirm)
        }
        .padding()
    }
}
