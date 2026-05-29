//
//  AdminPublicProjectionView.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import SwiftUI

struct AdminPublicProjectionView: View {
    @StateObject var viewModel: AdminPublicProjectionViewModel
    @State private var showingSettings = false
    @State private var showingAction = false

    var body: some View {
        List { content }
            .navigationTitle("Public Projection")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { Task { await viewModel.refresh() } } label: { Image(systemName: "arrow.clockwise") }
                }
            }
            .task { await viewModel.load() }
            .refreshable { await viewModel.refresh() }
            .alert("Error", isPresented: errorBinding) {
                Button("OK") { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .alert("Listo", isPresented: successBinding) {
                Button("OK") { viewModel.successMessage = nil }
            } message: {
                Text(viewModel.successMessage ?? "")
            }
            .sheet(isPresented: $showingSettings) {
                NavigationStack {
                    AdminPublicProjectionSettingsView(viewModel: viewModel, onDone: { showingSettings = false })
                }
            }
            .sheet(isPresented: $showingAction) {
                NavigationStack {
                    AdminPublicProjectionActionView(viewModel: viewModel, onDone: { showingAction = false })
                }
            }
    }

    @ViewBuilder private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            Section { ProgressView("Cargando publicación pública…") }
        case .empty(let message):
            Section { EmptyStateView(systemImage: "globe", title: "Sin publicación", message: message) }
        case .failed(let message):
            Section { ErrorStateView(title: "No se pudo cargar", message: message, retry: { Task { await viewModel.refresh() } }) }
        case .loaded(let projection):
            Section {
                VStack(alignment: .leading, spacing: 10) {
                    Label(projection.visibilityTitle, systemImage: projection.visible ? "eye.fill" : "eye.slash.fill")
                        .font(.title3.bold())
                        .foregroundStyle(projection.visible ? .green : .secondary)
                    Text(projection.businessName)
                        .font(.headline)
                    Text("Estado: \(projection.statusTitle)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    LabeledContent("Store ID", value: projection.publicStoreId ?? "No generado")
                    LabeledContent("Actividades", value: projection.activityTypes.isEmpty ? "—" : projection.activityTypes.joined(separator: ", "))
                    LabeledContent("Items publicados", value: "\(projection.publishedItemCount)")
                    LabeledContent("Public catalog revision", value: projection.publicCatalogRevision ?? "—")
                    LabeledContent("Ubicación", value: projection.locationVisibility.nexoReadableKey)
                }
                .padding(.vertical, 6)
            }

            if projection.hasBlockers {
                Section("Bloqueos") {
                    ForEach(projection.blockers, id: \.self) { blocker in
                        Label(blocker, systemImage: "xmark.octagon.fill")
                            .foregroundStyle(.red)
                    }
                }
            }

            if projection.hasWarnings {
                Section("Advertencias") {
                    ForEach(projection.warnings, id: \.self) { warning in
                        Label(warning, systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                    }
                }
            }

            Section("Acciones") {
                Button { showingSettings = true } label: { Label("Editar configuración pública", systemImage: "square.and.pencil") }
                    .disabled(!viewModel.canManage)

                Button {
                    viewModel.prepareAction(projection.visible ? .hide : .publish)
                    showingAction = true
                } label: {
                    Label(projection.visible ? "Ocultar storefront" : "Publicar storefront", systemImage: projection.visible ? "eye.slash" : "eye")
                }
                .disabled(!viewModel.canManage || (!projection.visible && !projection.canPublish))

                Button(role: .destructive) {
                    viewModel.prepareAction(.suspend)
                    showingAction = true
                } label: {
                    Label("Suspender publicación", systemImage: "pause.octagon")
                }
                .disabled(!viewModel.canManage)
            }

            Section("Regla de seguridad") {
                Text("Nada se publica automáticamente. Ventas, caja, clientes, usuarios, firma electrónica, XML, errores SRI privados y auditoría nunca deben salir desde Public Projection.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var errorBinding: Binding<Bool> {
        Binding(get: { viewModel.errorMessage != nil }, set: { if !$0 { viewModel.errorMessage = nil } })
    }

    private var successBinding: Binding<Bool> {
        Binding(get: { viewModel.successMessage != nil }, set: { if !$0 { viewModel.successMessage = nil } })
    }
}

private struct AdminPublicProjectionSettingsView: View {
    @ObservedObject var viewModel: AdminPublicProjectionViewModel
    let onDone: () -> Void

    var body: some View {
        Form {
            Section("Datos públicos") {
                TextField("Nombre público", text: $viewModel.settingsInput.businessName)
                Picker("Ubicación", selection: $viewModel.settingsInput.locationVisibility) {
                    Text("Oculta").tag("hidden")
                    Text("Aproximada").tag("approximate")
                    Text("Exacta pública").tag("exact_public")
                }
            }
            Section("Auditoría") {
                TextField("Motivo", text: $viewModel.settingsInput.reason, axis: .vertical)
                    .lineLimit(2...4)
            }
        }
        .navigationTitle("Publicación")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("Cancelar", action: onDone) }
            ToolbarItem(placement: .confirmationAction) {
                Button("Guardar") {
                    Task {
                        await viewModel.saveSettings()
                        if viewModel.errorMessage == nil { onDone() }
                    }
                }
                .disabled(!viewModel.canSaveSettings || viewModel.isMutating)
            }
        }
    }
}

private struct AdminPublicProjectionActionView: View {
    @ObservedObject var viewModel: AdminPublicProjectionViewModel
    let onDone: () -> Void

    var body: some View {
        Form {
            Section {
                Text("Esta acción afecta lo que una app pública o storefront futuro podría mostrar. Revisa que no se publique información privada.")
                    .foregroundStyle(.secondary)
            }
            Section("Acción") {
                LabeledContent("Tipo", value: viewModel.actionDraft.action.title)
            }
            Section("Auditoría") {
                TextField("Motivo obligatorio", text: $viewModel.actionDraft.reason, axis: .vertical)
                    .lineLimit(2...4)
            }
        }
        .navigationTitle(viewModel.actionDraft.action.title)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("Cancelar", action: onDone) }
            ToolbarItem(placement: .confirmationAction) {
                Button(viewModel.actionDraft.action.title, role: viewModel.actionDraft.action == .publish ? nil : .destructive) {
                    Task {
                        await viewModel.runAction()
                        if viewModel.errorMessage == nil { onDone() }
                    }
                }
                .disabled(!viewModel.canRunAction || viewModel.isMutating)
            }
        }
    }
}
