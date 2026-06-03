//
//  AdminUsersViewModel.swift
//  Nexo Admin
//
//  Created by José Ruiz on 2/6/26.
//

import Combine
import Foundation

@MainActor
final class AdminUsersViewModel: ObservableObject {
    @Published private(set) var state: LoadableViewState<[AdminAccessUser]> = .idle
    @Published private(set) var rolesState: LoadableViewState<[AdminAccessRole]> = .idle
    @Published private(set) var createdTemporaryUser: AdminTemporaryUserResult?
    @Published private(set) var isMutating = false
    @Published var searchText = ""
    @Published var statusFilter: AdminUserStatusFilter = .all
    @Published var createInput = CreateTemporaryAdminUserInput()
    @Published var errorMessage: String?

    let repository: any AdminAccessRepository
    private let listUsers: ListAdminUsersUseCase
    private let mutateUsers: MutateAdminUserUseCase
    private let listRoles: ListAdminRolesUseCase

    init(repository: any AdminAccessRepository) {
        self.repository = repository
        self.listUsers = ListAdminUsersUseCase(repository: repository)
        self.mutateUsers = MutateAdminUserUseCase(repository: repository)
        self.listRoles = ListAdminRolesUseCase(repository: repository)
    }

    var users: [AdminAccessUser] {
        guard case .loaded(let users) = state else { return [] }
        return users
    }

    var activeRoles: [AdminAccessRole] {
        guard case .loaded(let roles) = rolesState else { return [] }
        return roles.assignableFromAdmin
    }

    var canSubmitTemporaryUser: Bool {
        createInput.email.trimmed.contains("@") &&
        !createInput.displayName.trimmed.isEmpty &&
        !createInput.roleIds.isEmpty &&
        !createInput.reason.trimmed.isEmpty
    }

    func load() async {
        if case .loaded = state { return }
        await refresh()
    }

    func refresh() async {
        state = .loading
        async let usersTask = listUsers.execute(query: searchText, status: statusFilter.backendValue, limit: 100)
        async let rolesTask = listRoles.execute(includeSystemTemplates: true)
        do {
            let (loadedUsers, loadedRoles) = try await (usersTask, rolesTask)
            state = loadedUsers.isEmpty ? .empty("No hay usuarios para este filtro.") : .loaded(loadedUsers)
            rolesState = loadedRoles.isEmpty ? .empty("No hay roles disponibles.") : .loaded(loadedRoles)
            if createInput.roleIds.isEmpty, let firstRole = loadedRoles.assignableFromAdmin.first {
                createInput.roleIds = [firstRole.id]
            }
        } catch {
            state = .failed(error.userFriendlyMessage)
        }
    }

    func applyFilters() async {
        await refresh()
    }

    func createTemporaryUser() async {
        guard canSubmitTemporaryUser else {
            errorMessage = "Completa correo, nombre, roles y motivo."
            return
        }
        isMutating = true
        errorMessage = nil
        do {
            let result = try await mutateUsers.createTemporary(createInput)
            createdTemporaryUser = result
            createInput = CreateTemporaryAdminUserInput()
            if let firstRole = activeRoles.first { createInput.roleIds = [firstRole.id] }
            await refresh()
        } catch {
            errorMessage = error.userFriendlyMessage
        }
        isMutating = false
    }

    func dismissTemporaryUserSecret() {
        createdTemporaryUser = nil
    }
}

enum AdminUserStatusFilter: String, CaseIterable, Identifiable {
    case all
    case active
    case blocked
    case suspended
    case pending

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: return "Todos"
        case .active: return "Activos"
        case .blocked: return "Bloqueados"
        case .suspended: return "Suspendidos"
        case .pending: return "Pendientes"
        }
    }

    var backendValue: String? {
        switch self {
        case .all: return nil
        case .active: return "ACTIVE"
        case .blocked: return "BLOCKED"
        case .suspended: return "SUSPENDED"
        case .pending: return "PENDING"
        }
    }
}

private extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
}
