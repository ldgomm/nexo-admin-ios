//
//  AdminTaxSriComponents.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import SwiftUI

struct AdminTaxSriInfoRow: View {
    let title: String
    let value: String
    var systemImage: String = "info.circle"

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: systemImage).foregroundStyle(.secondary).frame(width: 24)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.caption).foregroundStyle(.secondary)
                Text(value.isEmpty ? "—" : value).font(.body.weight(.medium))
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 6)
    }
}

struct AdminTaxSriStatusBadge: View {
    let text: String

    private var normalizedText: String {
        text.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    }

    private var tint: Color {
        if normalizedText.contains("CORRECT")
            || normalizedText.contains("PASSED")
            || normalizedText.contains("OK")
            || normalizedText.contains("AUTORIZ") {
            return .green
        }
        if normalizedText.contains("FALL")
            || normalizedText.contains("FAILED")
            || normalizedText.contains("ERROR")
            || normalizedText.contains("RECHAZ")
            || normalizedText.contains("REJECT")
            || normalizedText.contains("NOT_AUTHORIZED") {
            return .red
        }
        if normalizedText.contains("PROCES")
            || normalizedText.contains("PENDING")
            || normalizedText.contains("RUNNING") {
            return .orange
        }
        if normalizedText.contains("OMIT")
            || normalizedText.contains("SKIPPED") {
            return .secondary
        }
        return .secondary
    }

    var body: some View {
        Text(text.uppercased())
            .font(.caption2.weight(.bold))
            .foregroundStyle(tint)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Capsule().fill(tint.opacity(0.12)))
    }
}

struct AdminTaxSriSectionCard<Content: View>: View {
    let title: String
    let subtitle: String?
    let systemImage: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: systemImage)
                    .font(.title3.weight(.semibold))
                    .frame(width: 32, height: 32)
                    .background(RoundedRectangle(cornerRadius: 10).fill(.thinMaterial))
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.headline)
                    if let subtitle { Text(subtitle).font(.caption).foregroundStyle(.secondary) }
                }
                Spacer()
            }
            content
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(.background)
                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
        )
    }
}

struct AdminTaxSriReasonSheet: View {
    let title: String
    let actionTitle: String
    var isSubmitting: Bool = false
    let onCancel: () -> Void
    let onSubmit: (String) -> Void
    @State private var reason = ""

    private var cleanReason: String {
        reason.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Motivo obligatorio") {
                    TextField("Ej. Actualización solicitada por el propietario", text: $reason, axis: .vertical)
                        .lineLimit(3, reservesSpace: true)
                        .disabled(isSubmitting)
                }
                if isSubmitting {
                    Section {
                        HStack(spacing: 10) {
                            ProgressView()
                            Text("Procesando solicitud…")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .interactiveDismissDisabled(isSubmitting)
            .navigationTitle(title)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar", action: onCancel)
                        .disabled(isSubmitting)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(actionTitle) { onSubmit(cleanReason) }
                        .disabled(cleanReason.isEmpty || isSubmitting)
                }
            }
        }
    }
}
