//
//  AdminPermissionsView.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import SwiftUI

struct AdminPermissionsView: View {
    @StateObject var viewModel: AdminPermissionsViewModel

    var body: some View {
        List {
            Section {
                HTextField(title: "Buscar permiso", text: $viewModel.searchText)
                Toggle("Incluir reservados", isOn: $viewModel.includeReserved)
                    .onChange(of: viewModel.includeReserved) { _ in Task { await viewModel.refresh() } }
                Picker("Categoría", selection: $viewModel.selectedCategory) {
                    ForEach(viewModel.categories, id: \.self) { category in
                        Text(category).tag(category)
                    }
                }
            }

            content
        }
        .navigationTitle("Permisos")
        .refreshable { await viewModel.refresh() }
        .task { await viewModel.load() }
    }

    @ViewBuilder private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            Section { ProgressView("Cargando permisos…") }
        case .empty(let message):
            Section { EmptyStateView(systemImage: "checkmark.shield", title: "Sin permisos", message: message) }
        case .failed(let message):
            Section { ErrorStateView(title: "No se pudo cargar permisos", message: message, retry: { Task { await viewModel.refresh() } }) }
        case .loaded:
            if viewModel.filteredPermissions.isEmpty {
                Section { EmptyStateView(systemImage: "magnifyingglass", title: "Sin resultados", message: "Prueba con otro texto o categoría.") }
            } else {
                let groups = Dictionary(grouping: viewModel.filteredPermissions, by: \.categoryLabel)
                ForEach(groups.keys.sorted(), id: \.self) { category in
                    Section(category) {
                        ForEach(groups[category] ?? []) { permission in
                            PermissionRow(permission: permission)
                        }
                    }
                }
            }
        }
    }
}

private struct PermissionRow: View {
    let permission: AdminAccessPermission

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(alignment: .firstTextBaseline) {
                Text(permission.name)
                    .font(.headline)
                Spacer()
                AdminAccessStatusBadge(text: permission.riskLabel)
            }
            Text(permission.code)
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)
            Text(permission.description)
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack {
                AdminAccessStatusBadge(text: permission.scope.readableStatus)
                if permission.requiresReason { AdminAccessStatusBadge(text: "Motivo") }
                if permission.requiresAudit { AdminAccessStatusBadge(text: "Auditado") }
                if permission.requiresStepUp { AdminAccessStatusBadge(text: "Step-up") }
            }
        }
        .padding(.vertical, 4)
    }
}
