//
//  AdminRoleDetailView.swift
//  Nexo Admin
//
//  Created by José Ruiz on 2/6/26.
//

import SwiftUI

struct AdminRoleDetailView: View {
    @StateObject var viewModel: AdminRoleDetailViewModel
    @State private var selectedSheet: AdminRoleDetailSheet?

    var body: some View {
        List { content }
            .navigationTitle("Rol")
            .refreshable { await viewModel.refresh() }
            .task { await viewModel.load() }
            .alert("No se pudo completar", isPresented: Binding(get: { viewModel.errorMessage != nil }, set: { _ in viewModel.errorMessage = nil })) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .sheet(item: $selectedSheet) { sheet in
                NavigationStack { sheetContent(sheet) }
            }
    }

    @ViewBuilder private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            Section { ProgressView("Cargando rol…") }
        case .empty(let message):
            Section { EmptyStateView(systemImage: "person.badge.key", title: "Sin rol", message: message) }
        case .failed(let message):
            Section { ErrorStateView(title: "No se pudo cargar", message: message, retry: { Task { await viewModel.refresh() } }) }
        case .loaded(let role):
            Section("Resumen") {
                LabeledContent("Nombre", value: role.name)
                LabeledContent("Código", value: role.code)
                LabeledContent("Estado", value: role.status.readableStatus)
                LabeledContent("Tipo", value: role.type.readableStatus)
                LabeledContent("Scope", value: role.scope.readableStatus)
                LabeledContent("Versión", value: "\(role.schemaVersion)")
                Text(role.description)
                    .foregroundStyle(.secondary)
            }

            Section("Seguridad") {
                Toggle("Rol del sistema", isOn: .constant(role.systemRole)).disabled(true)
                Toggle("Crítico", isOn: .constant(role.critical)).disabled(true)
                Toggle("Editable", isOn: .constant(role.editable)).disabled(true)
                if let message = role.editRestrictionMessage {
                    Label(message, systemImage: "lock.shield")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            if let diagnostics = viewModel.diagnostics {
                Section("Diagnóstico") {
                    AdminRoleDiagnosticsCallout(diagnostics: diagnostics)
                }

                Section("Capacidades humanas") {
                    if diagnostics.matchedCapabilityGroups.isEmpty {
                        Text("Este rol no coincide con ningún grupo humano publicado por el backend.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(diagnostics.matchedCapabilityGroups) { group in
                            AdminCapabilityGroupCard(
                                group: group,
                                matchedPermissionKeys: group.matchedPermissionKeys(for: role)
                            )
                        }
                    }
                }

                if !diagnostics.highRiskPermissions.isEmpty {
                    Section("Permisos sensibles") {
                        ForEach(diagnostics.highRiskPermissions) { permission in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(permission.name)
                                    .font(.subheadline.weight(.semibold))
                                Text(permission.code)
                                    .font(.caption.monospaced())
                                    .foregroundStyle(.secondary)
                                HStack(spacing: 6) {
                                    AdminAccessStatusBadge(text: permission.riskLabel)
                                    if permission.requiresReason { AdminAccessStatusBadge(text: "Motivo") }
                                    if permission.requiresAudit { AdminAccessStatusBadge(text: "Auditado") }
                                    if permission.requiresStepUp { AdminAccessStatusBadge(text: "Crítico") }
                                }
                            }
                            .padding(.vertical, 3)
                        }
                    }
                }

                Section("Permisos técnicos") {
                    if role.usesWildcardPermission {
                        Label("Este rol usa wildcard (*). Trátalo como acceso total protegido por backend.", systemImage: "exclamationmark.shield")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    if diagnostics.uncoveredPermissionKeys.isEmpty && !role.permissionKeys.isEmpty {
                        Text("Todos los permisos técnicos visibles están cubiertos por grupos humanos o por wildcard.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    } else if role.permissionKeys.isEmpty {
                        Text("Sin permisos")
                            .foregroundStyle(.secondary)
                    } else {
                        DisclosureGroup("Permisos sin grupo humano") {
                            ForEach(diagnostics.uncoveredPermissionKeys, id: \.self) { permission in
                                Text(permission)
                                    .font(.caption.monospaced())
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }

            Section("Acciones") {
                if role.canBeEditedFromApp {
                    Button { selectedSheet = .edit } label: { Label("Editar rol", systemImage: "square.and.pencil") }
                    if role.isActive {
                        Button(role: .destructive) { selectedSheet = .deactivate } label: { Label("Desactivar", systemImage: "pause.circle") }
                    } else {
                        Button { selectedSheet = .activate } label: { Label("Activar", systemImage: "play.circle") }
                    }
                } else {
                    Text("Este rol no puede editarse desde la administración de la organización. El backend conserva la regla final.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    @ViewBuilder private func sheetContent(_ sheet: AdminRoleDetailSheet) -> some View {
        switch sheet {
        case .edit:
            AdminRoleEditView(viewModel: viewModel, onDone: { selectedSheet = nil })
        case .activate:
            AdminRoleReasonActionView(
                title: "Activar rol",
                message: "El rol volverá a poder asignarse y usarse según reglas del backend.",
                reason: $viewModel.actionReason,
                isMutating: viewModel.isMutating,
                actionTitle: "Activar",
                role: nil,
                onCancel: { selectedSheet = nil },
                onConfirm: { await viewModel.activate(); if viewModel.errorMessage == nil { selectedSheet = nil } }
            )
        case .deactivate:
            AdminRoleReasonActionView(
                title: "Desactivar rol",
                message: "El backend rechazará la operación si deja a la organización sin administrador o sin gestor de roles.",
                reason: $viewModel.actionReason,
                isMutating: viewModel.isMutating,
                actionTitle: "Desactivar",
                role: .destructive,
                onCancel: { selectedSheet = nil },
                onConfirm: { await viewModel.deactivate(); if viewModel.errorMessage == nil { selectedSheet = nil } }
            )
        }
    }
}

private enum AdminRoleDetailSheet: Identifiable {
    case edit
    case activate
    case deactivate

    var id: String { String(describing: self) }
}

private struct AdminRoleEditView: View {
    @ObservedObject var viewModel: AdminRoleDetailViewModel
    let onDone: () -> Void

    var body: some View {
        Form {
            Section("Datos") {
                TextField("Nombre", text: $viewModel.updateInput.name)
                TextField("Descripción", text: $viewModel.updateInput.description, axis: .vertical)
                    .lineLimit(2...4)
            }

            Section("Filtro de permisos") {
                Toggle("Solo permisos operativos Business", isOn: $viewModel.showOnlyBusinessPermissions)
                TextField("Buscar permiso", text: $viewModel.permissionSearchText)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                LabeledContent("Seleccionados", value: "\(viewModel.updateInput.permissionKeys.count)")
            }

            PermissionSelectionList(
                permissions: viewModel.filteredPermissions,
                selectedPermissionKeys: $viewModel.updateInput.permissionKeys
            )

            Section("Advertencias") {
                AdminAccessWarningCallout(messages: viewModel.updateWarnings)
            }

            Section("Auditoría") {
                TextField("Motivo", text: $viewModel.updateInput.reason, axis: .vertical)
                    .lineLimit(2...4)
            }
        }
        .navigationTitle("Editar rol")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("Cancelar", action: onDone) }
            ToolbarItem(placement: .confirmationAction) {
                Button("Guardar") {
                    Task {
                        await viewModel.save()
                        if viewModel.errorMessage == nil { onDone() }
                    }
                }
                .disabled(!viewModel.canSave || viewModel.isMutating)
            }
        }
    }
}

private struct AdminRoleReasonActionView: View {
    let title: String
    let message: String
    @Binding var reason: String
    let isMutating: Bool
    let actionTitle: String
    let role: ButtonRole?
    let onCancel: () -> Void
    let onConfirm: () async -> Void

    var body: some View {
        Form {
            Section { Text(message).foregroundStyle(.secondary) }
            Section("Auditoría") {
                TextField("Motivo", text: $reason, axis: .vertical)
                    .lineLimit(2...4)
            }
        }
        .navigationTitle(title)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("Cancelar", action: onCancel) }
            ToolbarItem(placement: .confirmationAction) {
                Button(actionTitle, role: role) { Task { await onConfirm() } }
                    .disabled(reason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isMutating)
            }
        }
    }
}
