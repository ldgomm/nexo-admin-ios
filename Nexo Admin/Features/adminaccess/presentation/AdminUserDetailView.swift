//
//  AdminUserDetailView.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import SwiftUI

struct AdminUserDetailView: View {
    @StateObject var viewModel: AdminUserDetailViewModel
    @State private var selectedSheet: AdminUserDetailSheet?

    var body: some View {
        List {
            content
        }
        .navigationTitle("Usuario")
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
        .sheet(item: Binding(
            get: { viewModel.resetPasswordResult.map(PasswordSecretBox.init(result:)) },
            set: { _ in viewModel.dismissSecret() }
        )) { box in
            NavigationStack {
                AdminAccessSecretCard(
                    title: "Nueva contraseña temporal",
                    secret: box.result.temporaryPassword,
                    message: "Cópiala ahora. El usuario deberá cambiarla al iniciar sesión."
                )
                .padding()
                .navigationTitle("Contraseña reseteada")
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Listo") { viewModel.dismissSecret() } } }
            }
            .presentationDetents([.medium])
        }
    }

    @ViewBuilder private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            Section { ProgressView("Cargando usuario…") }
        case .empty(let message):
            Section { EmptyStateView(systemImage: "person.crop.circle.badge.questionmark", title: "Sin usuario", message: message) }
        case .failed(let message):
            Section { ErrorStateView(title: "No se pudo cargar", message: message, retry: { Task { await viewModel.refresh() } }) }
        case .loaded(let user):
            Section("Resumen") {
                LabeledContent("Nombre", value: user.displayName)
                LabeledContent("Correo", value: user.email)
                if let phone = user.phone { LabeledContent("Teléfono", value: phone) }
                LabeledContent("Estado", value: user.statusLabel)
                LabeledContent("Membresía", value: user.membershipStatus.readableStatus)
                LabeledContent("Sesiones activas", value: "\(user.activeSessionCount)")
            }

            Section("Roles") {
                if user.roleNames.isEmpty {
                    Text("Sin roles asignados")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(user.roleNames, id: \.self) { name in
                        Label(name, systemImage: "person.badge.key")
                    }
                }
            }

            if !user.effectivePermissions.isEmpty {
                Section("Permisos efectivos") {
                    ForEach(user.effectivePermissions.sorted(), id: \.self) { permission in
                        Text(permission)
                            .font(.caption.monospaced())
                    }
                }
            }

            Section("Acciones") {
                Button { selectedSheet = .edit } label: { Label("Editar datos y roles", systemImage: "square.and.pencil") }
                if user.isBlocked {
                    Button { selectedSheet = .unblock } label: { Label("Desbloquear usuario", systemImage: "lock.open") }
                } else {
                    Button(role: .destructive) { selectedSheet = .block } label: { Label("Bloquear usuario", systemImage: "lock") }
                }
                Button { selectedSheet = .resetPassword } label: { Label("Resetear contraseña", systemImage: "key") }
                Button(role: .destructive) { selectedSheet = .revokeSessions } label: { Label("Revocar sesiones", systemImage: "rectangle.portrait.and.arrow.right") }
            }

            if let blockedReason = user.blockedReason {
                Section("Motivo de bloqueo") {
                    Text(blockedReason)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    @ViewBuilder private func sheetContent(_ sheet: AdminUserDetailSheet) -> some View {
        switch sheet {
        case .edit:
            AdminUserEditView(viewModel: viewModel, onDone: { selectedSheet = nil })
        case .block:
            AdminUserReasonActionView(
                title: "Bloquear usuario",
                message: "El backend validará que no sea el último administrador activo y revocará sesiones si corresponde.",
                reason: $viewModel.actionReason,
                isMutating: viewModel.isMutating,
                actionTitle: "Bloquear",
                role: .destructive,
                onCancel: { selectedSheet = nil },
                onConfirm: { await viewModel.blockUser(); if viewModel.errorMessage == nil { selectedSheet = nil } }
            )
        case .unblock:
            AdminUserReasonActionView(
                title: "Desbloquear usuario",
                message: "Restaurará el acceso del usuario en la organización activa.",
                reason: $viewModel.actionReason,
                isMutating: viewModel.isMutating,
                actionTitle: "Desbloquear",
                role: nil,
                onCancel: { selectedSheet = nil },
                onConfirm: { await viewModel.unblockUser(); if viewModel.errorMessage == nil { selectedSheet = nil } }
            )
        case .resetPassword:
            AdminResetPasswordView(viewModel: viewModel, onDone: { selectedSheet = nil })
        case .revokeSessions:
            AdminUserReasonActionView(
                title: "Revocar sesiones",
                message: "El usuario deberá iniciar sesión nuevamente.",
                reason: $viewModel.actionReason,
                isMutating: viewModel.isMutating,
                actionTitle: "Revocar",
                role: .destructive,
                onCancel: { selectedSheet = nil },
                onConfirm: { await viewModel.revokeSessions(); if viewModel.errorMessage == nil { selectedSheet = nil } }
            )
        }
    }
}

private enum AdminUserDetailSheet: Identifiable {
    case edit
    case block
    case unblock
    case resetPassword
    case revokeSessions

    var id: String { String(describing: self) }
}

private struct AdminUserEditView: View {
    @ObservedObject var viewModel: AdminUserDetailViewModel
    let onDone: () -> Void

    var body: some View {
        Form {
            Section("Datos") {
                TextField("Nombre", text: $viewModel.updateInput.displayName)
                Toggle("Quitar teléfono", isOn: $viewModel.updateInput.clearPhone)
                if !viewModel.updateInput.clearPhone {
                    TextField("Teléfono", text: $viewModel.updateInput.phone)
                        .keyboardType(.phonePad)
                }
            }

            Section("Roles") {
                RoleSelectionList(roles: viewModel.roles, selectedRoleIds: $viewModel.updateInput.roleIds)
            }

            Section("Auditoría") {
                TextField("Motivo", text: $viewModel.updateInput.reason, axis: .vertical)
                    .lineLimit(2...4)
            }
        }
        .navigationTitle("Editar usuario")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("Cancelar", action: onDone) }
            ToolbarItem(placement: .confirmationAction) {
                Button("Guardar") {
                    Task {
                        await viewModel.saveUpdate()
                        if viewModel.errorMessage == nil { onDone() }
                    }
                }
                .disabled(!viewModel.canSaveUpdate || viewModel.isMutating)
            }
        }
    }
}

private struct AdminResetPasswordView: View {
    @ObservedObject var viewModel: AdminUserDetailViewModel
    let onDone: () -> Void

    var body: some View {
        Form {
            Section("Nueva contraseña") {
                SecureField("Opcional: dejar vacío para generar", text: $viewModel.resetTemporaryPassword)
                Toggle("Revocar sesiones activas", isOn: $viewModel.revokeSessionsOnReset)
            }
            Section("Auditoría") {
                TextField("Motivo", text: $viewModel.actionReason, axis: .vertical)
                    .lineLimit(2...4)
            }
        }
        .navigationTitle("Reset password")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("Cancelar", action: onDone) }
            ToolbarItem(placement: .confirmationAction) {
                Button("Resetear") {
                    Task {
                        await viewModel.resetPassword()
                        if viewModel.errorMessage == nil { onDone() }
                    }
                }
                .disabled(!viewModel.canRunAction || viewModel.isMutating)
            }
        }
    }
}

private struct AdminUserReasonActionView: View {
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
            Section {
                Text(message)
                    .foregroundStyle(.secondary)
            }
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

private struct PasswordSecretBox: Identifiable {
    let id = UUID()
    let result: AdminResetPasswordResult
}
