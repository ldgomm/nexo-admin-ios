//
//  AdminSupportDiagnosticsView.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import SwiftUI

struct AdminSupportDiagnosticsView: View {
    @StateObject var viewModel: AdminSupportDiagnosticsViewModel

    var body: some View {
        List { content }
            .navigationTitle("Soporte")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { Task { await viewModel.refresh() } } label: { Image(systemName: "arrow.clockwise") }
                }
            }
            .task { await viewModel.load() }
            .refreshable { await viewModel.refresh() }
    }

    @ViewBuilder private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            Section { ProgressView("Cargando diagnóstico…") }
        case .empty(let message):
            Section { EmptyStateView(systemImage: "stethoscope", title: "Sin diagnóstico", message: message) }
        case .failed(let message):
            Section { ErrorStateView(title: "No se pudo cargar", message: message, retry: { Task { await viewModel.refresh() } }) }
        case .loaded(let snapshot):
            Section {
                VStack(alignment: .leading, spacing: 10) {
                    Label(snapshot.summaryTitle, systemImage: snapshot.health?.healthy == true ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                        .font(.title3.bold())
                        .foregroundStyle(snapshot.health?.healthy == true ? .green : .orange)
                    Text(snapshot.summaryMessage)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 6)
            }

            Section("Build local") {
                LabeledContent("App", value: snapshot.buildInfo.appName)
                LabeledContent("Versión", value: snapshot.buildInfo.displayVersion)
                LabeledContent("Configuración", value: snapshot.buildInfo.configuration.rawValue)
                LabeledContent("API", value: snapshot.buildInfo.apiBaseURL)
                LabeledContent("Bundle", value: snapshot.buildInfo.bundleIdentifier)
            }

            if let health = snapshot.health {
                Section("API") {
                    LabeledContent("Estado", value: health.statusTitle)
                    LabeledContent("Entorno", value: health.environment)
                    LabeledContent("Versión", value: health.version)
                    LabeledContent("Commit", value: health.commit ?? "—")
                    LabeledContent("MongoDB", value: health.database)
                    LabeledContent("SRI", value: health.sri ?? "—")
                    LabeledContent("Outbox", value: health.outbox ?? "—")
                    LabeledContent("Generado", value: health.generatedAt ?? "—")
                }
            }

            Section("Dispositivos") {
                if snapshot.devices.isEmpty {
                    Text("No hay dispositivos registrados para esta organización o usuario.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(snapshot.devices) { device in
                        VStack(alignment: .leading, spacing: 5) {
                            Text(device.displayName)
                                .font(.headline)
                            Text(device.deviceId)
                                .font(.caption.monospaced())
                                .foregroundStyle(.secondary)
                            LabeledContent("Versión", value: device.appVersion)
                            LabeledContent("Estado", value: device.status.nexoReadableKey)
                            LabeledContent("Última vez", value: device.lastSeenAt ?? "—")
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
    }
}
