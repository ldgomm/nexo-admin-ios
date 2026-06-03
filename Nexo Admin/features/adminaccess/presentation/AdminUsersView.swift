//
//  AdminUsersView.swift
//  Nexo Admin
//
//  Created by José Ruiz on 2/6/26.
//

import SwiftUI

struct AdminUsersView: View {
    @StateObject var viewModel: AdminUsersViewModel
    @State private var showingCreate = false

    var body: some View {
        List {
            Section {
                HTextField(title: "Buscar por nombre o correo", text: $viewModel.searchText, keyboardType: .emailAddress)
                Picker("Estado", selection: $viewModel.statusFilter) {
                    ForEach(AdminUserStatusFilter.allCases) { filter in
                        Text(filter.title).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                Button("Aplicar filtros") { Task { await viewModel.applyFilters() } }
            }

            content
        }
        .navigationTitle("Usuarios")
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
                CreateTemporaryUserView(viewModel: viewModel)
            }
        }
        .sheet(item: Binding(
            get: { viewModel.createdTemporaryUser.map(TemporaryUserSecretBox.init(result:)) },
            set: { _ in viewModel.dismissTemporaryUserSecret() }
        )) { box in
            NavigationStack {
                AdminAccessSecretCard(
                    title: "Contraseña temporal",
                    secret: box.result.temporaryPassword,
                    message: "Cópiala ahora. Por seguridad, el backend puede no volver a mostrarla."
                )
                .padding()
                .navigationTitle("Usuario creado")
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Listo") { viewModel.dismissTemporaryUserSecret() } } }
            }
            .presentationDetents([.medium])
        }
    }

    @ViewBuilder private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            Section { ProgressView("Cargando usuarios…") }
        case .empty(let message):
            Section { EmptyStateView(systemImage: "person.2.slash", title: "Sin usuarios", message: message) }
        case .failed(let message):
            Section { ErrorStateView(title: "No se pudo cargar usuarios", message: message, retry: { Task { await viewModel.refresh() } }) }
        case .loaded(let users):
            Section("Usuarios") {
                ForEach(users) { user in
                    NavigationLink {
                        AdminUserDetailView(viewModel: AdminUserDetailViewModel(userId: user.id, repository: viewModel.repository))
                    } label: {
                        AdminUserRow(user: user)
                    }
                }
            }
        }
    }
}

private struct AdminUserRow: View {
    let user: AdminAccessUser

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(alignment: .firstTextBaseline) {
                Text(user.displayName)
                    .font(.headline)
                Spacer()
                AdminAccessStatusBadge(text: user.statusLabel, systemImage: user.isBlocked ? "lock.fill" : "checkmark.circle.fill")
            }
            Text(user.email)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(user.roleSummary)
                .font(.caption)
                .foregroundStyle(.secondary)
            if user.activeSessionCount > 0 {
                Text("\(user.activeSessionCount) sesiones activas")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct CreateTemporaryUserView: View {
    @ObservedObject var viewModel: AdminUsersViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            Section("Datos") {
                TextField("Correo", text: $viewModel.createInput.email)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                TextField("Nombre", text: $viewModel.createInput.displayName)
                TextField("Teléfono opcional", text: $viewModel.createInput.phone)
                    .keyboardType(.phonePad)
                SecureField("Contraseña temporal opcional", text: $viewModel.createInput.temporaryPassword)
            }

            Section("Roles") {
                RoleSelectionList(roles: viewModel.activeRoles, selectedRoleIds: $viewModel.createInput.roleIds)
            }

            Section("Auditoría") {
                TextField("Motivo", text: $viewModel.createInput.reason, axis: .vertical)
                    .lineLimit(2...4)
            }
        }
        .navigationTitle("Usuario temporal")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { dismiss() } }
            ToolbarItem(placement: .confirmationAction) {
                Button("Crear") {
                    Task {
                        await viewModel.createTemporaryUser()
                        if viewModel.errorMessage == nil { dismiss() }
                    }
                }
                .disabled(!viewModel.canSubmitTemporaryUser || viewModel.isMutating)
            }
        }
    }
}

private struct TemporaryUserSecretBox: Identifiable {
    let id = UUID()
    let result: AdminTemporaryUserResult
}

