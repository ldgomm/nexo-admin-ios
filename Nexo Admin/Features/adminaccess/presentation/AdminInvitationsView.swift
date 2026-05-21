//
//  AdminInvitationsView.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import SwiftUI

struct AdminInvitationsView: View {
    @StateObject var viewModel: AdminInvitationsViewModel
    @State private var showingCreate = false
    @State private var selectedInvitationForResend: AdminAccessInvitation?
    @State private var selectedInvitationForRevoke: AdminAccessInvitation?

    var body: some View {
        List {
            Section {
                Picker("Estado", selection: $viewModel.statusFilter) {
                    ForEach(AdminInvitationStatusFilter.allCases) { filter in
                        Text(filter.title).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                Button("Aplicar filtro") { Task { await viewModel.refresh() } }
            }
            content
        }
        .navigationTitle("Invitaciones")
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
            NavigationStack { CreateInvitationView(viewModel: viewModel, onDone: { showingCreate = false }) }
        }
        .sheet(item: $selectedInvitationForResend) { invitation in
            NavigationStack {
                InvitationReasonView(
                    title: "Reenviar invitación",
                    message: invitation.email,
                    reason: $viewModel.actionReason,
                    isMutating: viewModel.isMutating,
                    actionTitle: "Reenviar",
                    role: nil,
                    onCancel: { selectedInvitationForResend = nil },
                    onConfirm: {
                        await viewModel.resend(invitation)
                        if viewModel.errorMessage == nil { selectedInvitationForResend = nil }
                    }
                )
            }
        }
        .sheet(item: $selectedInvitationForRevoke) { invitation in
            NavigationStack {
                InvitationReasonView(
                    title: "Revocar invitación",
                    message: invitation.email,
                    reason: $viewModel.actionReason,
                    isMutating: viewModel.isMutating,
                    actionTitle: "Revocar",
                    role: .destructive,
                    onCancel: { selectedInvitationForRevoke = nil },
                    onConfirm: {
                        await viewModel.revoke(invitation)
                        if viewModel.errorMessage == nil { selectedInvitationForRevoke = nil }
                    }
                )
            }
        }
        .sheet(item: Binding(
            get: { viewModel.createdInvitation.map(InvitationSecretBox.created) ?? viewModel.resentInvitation.map(InvitationSecretBox.resent) },
            set: { _ in viewModel.dismissSecret() }
        )) { box in
            NavigationStack {
                AdminAccessSecretCard(
                    title: box.title,
                    secret: box.secret,
                    message: box.url ?? "Copia el token o enlace ahora."
                )
                .padding()
                .navigationTitle("Token de invitación")
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Listo") { viewModel.dismissSecret() } } }
            }
            .presentationDetents([.medium])
        }
    }

    @ViewBuilder private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            Section { ProgressView("Cargando invitaciones…") }
        case .empty(let message):
            Section { EmptyStateView(systemImage: "envelope.badge", title: "Sin invitaciones", message: message) }
        case .failed(let message):
            Section { ErrorStateView(title: "No se pudo cargar invitaciones", message: message, retry: { Task { await viewModel.refresh() } }) }
        case .loaded(let invitations):
            Section("Invitaciones") {
                ForEach(invitations) { invitation in
                    InvitationRow(invitation: invitation)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            if invitation.isPending {
                                Button("Revocar", role: .destructive) { selectedInvitationForRevoke = invitation }
                                Button("Reenviar") { selectedInvitationForResend = invitation }
                                    .tint(.blue)
                            }
                        }
                        .contextMenu {
                            if invitation.isPending {
                                Button("Reenviar") { selectedInvitationForResend = invitation }
                                Button("Revocar", role: .destructive) { selectedInvitationForRevoke = invitation }
                            }
                        }
                }
            }
        }
    }
}

private struct InvitationRow: View {
    let invitation: AdminAccessInvitation

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(alignment: .firstTextBaseline) {
                Text(invitation.email)
                    .font(.headline)
                Spacer()
                AdminAccessStatusBadge(text: invitation.statusLabel)
            }
            Text(invitation.roleSummary)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("Expira: \(invitation.expiresAt)")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

private struct CreateInvitationView: View {
    @ObservedObject var viewModel: AdminInvitationsViewModel
    let onDone: () -> Void

    var body: some View {
        Form {
            Section("Datos") {
                TextField("Correo", text: $viewModel.createInput.email)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                TextField("Nombre", text: $viewModel.createInput.displayName)
            }

            Section("Roles") {
                RoleSelectionList(roles: viewModel.activeRoles, selectedRoleIds: $viewModel.createInput.roleIds)
            }

            Section("Auditoría") {
                TextField("Motivo", text: $viewModel.createInput.reason, axis: .vertical)
                    .lineLimit(2...4)
            }
        }
        .navigationTitle("Crear invitación")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("Cancelar", action: onDone) }
            ToolbarItem(placement: .confirmationAction) {
                Button("Crear") {
                    Task {
                        await viewModel.createInvitation()
                        if viewModel.errorMessage == nil { onDone() }
                    }
                }
                .disabled(!viewModel.canCreateInvitation || viewModel.isMutating)
            }
        }
    }
}

private struct InvitationReasonView: View {
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

private struct InvitationSecretBox: Identifiable {
    let id = UUID()
    let title: String
    let secret: String
    let url: String?

    static func created(_ result: AdminInvitationCreatedResult) -> InvitationSecretBox {
        InvitationSecretBox(title: "Invitación creada", secret: result.rawInvitationToken, url: result.invitationUrl)
    }

    static func resent(_ result: AdminInvitationResendResult) -> InvitationSecretBox {
        InvitationSecretBox(title: "Invitación reenviada", secret: result.rawInvitationToken, url: result.invitationUrl)
    }
}
