//
//  AdminRolesView.swift
//  Nexo Admin
//
//  Created by José Ruiz on 2/6/26.
//

import SwiftUI

struct AdminRolesView: View {
    @StateObject var viewModel: AdminRolesViewModel
    @State private var showingCreate = false

    var body: some View {
        List {
            Section {
                Toggle("Incluir roles del sistema", isOn: $viewModel.includeSystemTemplates)
                    .onChange(of: viewModel.includeSystemTemplates) { _, _ in Task { await viewModel.refresh() } }
            } footer: {
                Text("Los roles del sistema pueden visualizarse y asignarse si el backend los permite, pero no se editan desde la organización.")
            }
            content
        }
        .navigationTitle("Roles")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showingCreate = true } label: { Image(systemName: "plus") }
            }
        }
        .refreshable { await viewModel.refresh() }
        .task { await viewModel.load() }
        .alert("No se pudo completar", isPresented: Binding(get: { viewModel.errorMessage != nil }, set: { _ in viewModel.errorMessage = nil })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .sheet(isPresented: $showingCreate) {
            NavigationStack {
                CreateRoleView(viewModel: viewModel, onDone: { showingCreate = false })
            }
        }
    }

    @ViewBuilder private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            Section { ProgressView("Cargando roles…") }
        case .empty(let message):
            Section { EmptyStateView(systemImage: "person.badge.key", title: "Sin roles", message: message) }
        case .failed(let message):
            Section { ErrorStateView(title: "No se pudo cargar roles", message: message, retry: { Task { await viewModel.refresh() } }) }
        case .loaded(let roles):
            Section("Roles") {
                ForEach(roles.sortedByName) { role in
                    NavigationLink {
                        AdminRoleDetailView(viewModel: AdminRoleDetailViewModel(roleId: role.id, repository: viewModel.repository))
                    } label: {
                        AdminRoleRow(role: role)
                    }
                }
            }
        }
    }
}

private struct AdminRoleRow: View {
    let role: AdminAccessRole

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(alignment: .firstTextBaseline) {
                Text(role.name)
                    .font(.headline)
                Spacer()
                AdminAccessStatusBadge(text: role.status.readableStatus, systemImage: role.isActive ? "checkmark.circle.fill" : "pause.circle.fill")
            }
            Text(role.code)
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)
            Text(role.description)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
            HStack {
                AdminAccessStatusBadge(text: role.type.readableStatus)
                if role.systemRole { AdminAccessStatusBadge(text: "Sistema") }
                if role.critical { AdminAccessStatusBadge(text: "Crítico") }
                if role.canBeEditedFromApp { AdminAccessStatusBadge(text: "Editable") }
                AdminAccessStatusBadge(text: role.permissionCountLabel)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct CreateRoleView: View {
    @ObservedObject var viewModel: AdminRolesViewModel
    let onDone: () -> Void

    var body: some View {
        Form {
            BusinessRoleTemplatePicker(
                previews: viewModel.templatePreviews,
                selectedTemplate: viewModel.selectedTemplate,
                apply: viewModel.applyTemplate,
                clear: viewModel.clearTemplate
            )

            Section("Datos") {
                TextField("Código: cajero, supervisor", text: $viewModel.createInput.code)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                TextField("Nombre", text: $viewModel.createInput.name)
                TextField("Descripción", text: $viewModel.createInput.description, axis: .vertical)
                    .lineLimit(2...4)
            }

            Section("Filtro de permisos") {
                Toggle("Solo permisos operativos Business", isOn: $viewModel.showOnlyBusinessPermissions)
                TextField("Buscar permiso", text: $viewModel.permissionSearchText)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                LabeledContent("Seleccionados", value: "\(viewModel.createInput.permissionKeys.count)")
            }

            PermissionSelectionList(
                permissions: viewModel.filteredPermissions,
                selectedPermissionKeys: $viewModel.createInput.permissionKeys
            )

            Section("Advertencias") {
                AdminAccessWarningCallout(messages: viewModel.createWarnings)
            }

            Section("Auditoría") {
                TextField("Motivo", text: $viewModel.createInput.reason, axis: .vertical)
                    .lineLimit(2...4)
            }
        }
        .navigationTitle("Crear rol")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("Cancelar", action: onDone) }
            ToolbarItem(placement: .confirmationAction) {
                Button("Crear") {
                    Task {
                        await viewModel.createRole()
                        if viewModel.errorMessage == nil { onDone() }
                    }
                }
                .disabled(!viewModel.canCreateRole || viewModel.isMutating)
            }
        }
    }
}
