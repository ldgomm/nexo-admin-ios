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
        .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Actualizar") { Task { await viewModel.refresh() } } } }
    }
}
