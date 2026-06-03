//
//  AdminUserDetailViewModel.swift
//  Nexo Admin
//
//  Created by José Ruiz on 2/6/26.
//

import Combine
import Foundation

@MainActor
final class AdminUserDetailViewModel: ObservableObject {
    @Published private(set) var state: LoadableViewState<AdminAccessUser> = .idle
    @Published private(set) var rolesState: LoadableViewState<[AdminAccessRole]> = .idle
    @Published private(set) var resetPasswordResult: AdminResetPasswordResult?
    @Published private(set) var sessionRevocationResult: AdminUserSessionRevocationResult?
    @Published private(set) var isMutating = false
    @Published var updateInput = UpdateAdminUserInput()
    @Published var actionReason = ""
    @Published var resetTemporaryPassword = ""
    @Published var revokeSessionsOnReset = true
    @Published var errorMessage: String?

    private let userId: String
    private let getUser: GetAdminUserUseCase
    private let mutateUsers: MutateAdminUserUseCase
    private let listRoles: ListAdminRolesUseCase

    init(userId: String, repository: any AdminAccessRepository) {
        self.userId = userId
        self.getUser = GetAdminUserUseCase(repository: repository)
        self.mutateUsers = MutateAdminUserUseCase(repository: repository)
        self.listRoles = ListAdminRolesUseCase(repository: repository)
    }

    var user: AdminAccessUser? {
        guard case .loaded(let user) = state else { return nil }
        return user
    }

    var roles: [AdminAccessRole] {
        guard case .loaded(let roles) = rolesState else { return [] }
        return roles.assignableFromAdmin
    }

    var canSaveUpdate: Bool {
        !updateInput.displayName.trimmed.isEmpty &&
        !updateInput.roleIds.isEmpty &&
        !updateInput.reason.trimmed.isEmpty
    }

    var canRunAction: Bool {
        !actionReason.trimmed.isEmpty
    }

    func load() async {
        if case .loaded = state { return }
        await refresh()
    }

    func refresh() async {
        state = .loading
        async let userTask = getUser.execute(id: userId)
        async let rolesTask = listRoles.execute(includeSystemTemplates: true)
        do {
            let (loadedUser, loadedRoles) = try await (userTask, rolesTask)
            state = .loaded(loadedUser)
            rolesState = loadedRoles.isEmpty ? .empty("No hay roles disponibles.") : .loaded(loadedRoles)
            hydrateUpdateInput(from: loadedUser)
        } catch {
            state = .failed(error.userFriendlyMessage)
        }
    }

    func saveUpdate() async {
        guard canSaveUpdate else {
            errorMessage = "Completa nombre, roles y motivo."
            return
        }
        await mutate { try await mutateUsers.update(id: userId, input: updateInput) }
    }

    func blockUser() async {
        guard canRunAction else {
            errorMessage = "Ingresa un motivo para bloquear el usuario."
            return
        }
        await mutate { try await mutateUsers.block(id: userId, reason: actionReason) }
    }

    func unblockUser() async {
        guard canRunAction else {
            errorMessage = "Ingresa un motivo para desbloquear el usuario."
            return
        }
        await mutate { try await mutateUsers.unblock(id: userId, reason: actionReason) }
    }

    func resetPassword() async {
        guard canRunAction else {
            errorMessage = "Ingresa un motivo para resetear la contraseña."
            return
        }
        isMutating = true
        errorMessage = nil
        do {
            resetPasswordResult = try await mutateUsers.resetPassword(
                userId: userId,
                temporaryPassword: resetTemporaryPassword.trimmedOptional,
                revokeSessions: revokeSessionsOnReset,
                reason: actionReason
            )
            resetTemporaryPassword = ""
            actionReason = ""
            await refresh()
        } catch {
            errorMessage = error.userFriendlyMessage
        }
        isMutating = false
    }

    func revokeSessions() async {
        guard canRunAction else {
            errorMessage = "Ingresa un motivo para revocar sesiones."
            return
        }
        isMutating = true
        errorMessage = nil
        do {
            sessionRevocationResult = try await mutateUsers.revokeSessions(userId: userId, reason: actionReason)
            actionReason = ""
            await refresh()
        } catch {
            errorMessage = error.userFriendlyMessage
        }
        isMutating = false
    }

    func dismissSecret() {
        resetPasswordResult = nil
    }

    private func mutate(_ operation: () async throws -> AdminAccessUser) async {
        isMutating = true
        errorMessage = nil
        do {
            let updated = try await operation()
            state = .loaded(updated)
            hydrateUpdateInput(from: updated)
            actionReason = ""
        } catch {
            errorMessage = error.userFriendlyMessage
        }
        isMutating = false
    }

    private func hydrateUpdateInput(from user: AdminAccessUser) {
        updateInput.displayName = user.displayName
        updateInput.phone = user.phone ?? ""
        updateInput.clearPhone = user.phone == nil
        updateInput.roleIds = user.roleIds
        if updateInput.reason.trimmed.isEmpty {
            updateInput.reason = "Actualizar usuario desde Nexo Admin iOS"
        }
    }
}

private extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
    var trimmedOptional: String? {
        let value = trimmed
        return value.isEmpty ? nil : value
    }
}
