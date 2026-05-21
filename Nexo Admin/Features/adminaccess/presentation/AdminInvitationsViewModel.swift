//
//  AdminInvitationsViewModel.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import Combine
import Foundation

@MainActor
final class AdminInvitationsViewModel: ObservableObject {
    @Published private(set) var state: LoadableViewState<[AdminAccessInvitation]> = .idle
    @Published private(set) var rolesState: LoadableViewState<[AdminAccessRole]> = .idle
    @Published private(set) var createdInvitation: AdminInvitationCreatedResult?
    @Published private(set) var resentInvitation: AdminInvitationResendResult?
    @Published private(set) var isMutating = false
    @Published var statusFilter: AdminInvitationStatusFilter = .all
    @Published var createInput = CreateAdminInvitationInput()
    @Published var actionReason = ""
    @Published var errorMessage: String?

    private let listInvitations: ListAdminInvitationsUseCase
    private let mutateInvitations: MutateAdminInvitationUseCase
    private let listRoles: ListAdminRolesUseCase

    init(repository: any AdminAccessRepository) {
        self.listInvitations = ListAdminInvitationsUseCase(repository: repository)
        self.mutateInvitations = MutateAdminInvitationUseCase(repository: repository)
        self.listRoles = ListAdminRolesUseCase(repository: repository)
    }

    var invitations: [AdminAccessInvitation] {
        guard case .loaded(let invitations) = state else { return [] }
        return invitations
    }

    var activeRoles: [AdminAccessRole] {
        guard case .loaded(let roles) = rolesState else { return [] }
        return roles.filter(\.isActive)
    }

    var canCreateInvitation: Bool {
        createInput.email.trimmed.contains("@") &&
        !createInput.displayName.trimmed.isEmpty &&
        !createInput.roleIds.isEmpty &&
        !createInput.reason.trimmed.isEmpty
    }

    var canRunAction: Bool { !actionReason.trimmed.isEmpty }

    func load() async {
        if case .loaded = state { return }
        await refresh()
    }

    func refresh() async {
        state = .loading
        async let invitationsTask = listInvitations.execute(status: statusFilter.backendValue, limit: 100)
        async let rolesTask = listRoles.execute(includeSystemTemplates: true)
        do {
            let (loadedInvitations, loadedRoles) = try await (invitationsTask, rolesTask)
            state = loadedInvitations.isEmpty ? .empty("No hay invitaciones para este filtro.") : .loaded(loadedInvitations)
            rolesState = loadedRoles.isEmpty ? .empty("No hay roles disponibles.") : .loaded(loadedRoles)
            if createInput.roleIds.isEmpty, let firstRole = loadedRoles.first(where: { $0.isActive }) {
                createInput.roleIds = [firstRole.id]
            }
        } catch {
            state = .failed(error.userFriendlyMessage)
        }
    }

    func createInvitation() async {
        guard canCreateInvitation else {
            errorMessage = "Completa correo, nombre, roles y motivo."
            return
        }
        isMutating = true
        errorMessage = nil
        do {
            createdInvitation = try await mutateInvitations.create(createInput)
            createInput = CreateAdminInvitationInput()
            if let firstRole = activeRoles.first { createInput.roleIds = [firstRole.id] }
            await refresh()
        } catch {
            errorMessage = error.userFriendlyMessage
        }
        isMutating = false
    }

    func resend(_ invitation: AdminAccessInvitation) async {
        guard canRunAction else {
            errorMessage = "Ingresa un motivo para reenviar la invitación."
            return
        }
        isMutating = true
        errorMessage = nil
        do {
            resentInvitation = try await mutateInvitations.resend(id: invitation.id, reason: actionReason)
            actionReason = ""
            await refresh()
        } catch {
            errorMessage = error.userFriendlyMessage
        }
        isMutating = false
    }

    func revoke(_ invitation: AdminAccessInvitation) async {
        guard canRunAction else {
            errorMessage = "Ingresa un motivo para revocar la invitación."
            return
        }
        isMutating = true
        errorMessage = nil
        do {
            _ = try await mutateInvitations.revoke(id: invitation.id, reason: actionReason)
            actionReason = ""
            await refresh()
        } catch {
            errorMessage = error.userFriendlyMessage
        }
        isMutating = false
    }

    func dismissSecret() {
        createdInvitation = nil
        resentInvitation = nil
    }
}

enum AdminInvitationStatusFilter: String, CaseIterable, Identifiable {
    case all
    case pending
    case accepted
    case revoked

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: return "Todas"
        case .pending: return "Pendientes"
        case .accepted: return "Aceptadas"
        case .revoked: return "Revocadas"
        }
    }

    var backendValue: String? {
        switch self {
        case .all: return nil
        case .pending: return "PENDING"
        case .accepted: return "ACCEPTED"
        case .revoked: return "REVOKED"
        }
    }
}

private extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
}
