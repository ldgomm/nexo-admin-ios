//
//  AdminRolesViewModel.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import Combine
import Foundation

@MainActor
final class AdminRolesViewModel: ObservableObject {
    @Published private(set) var state: LoadableViewState<[AdminAccessRole]> = .idle
    @Published private(set) var permissionsState: LoadableViewState<[AdminAccessPermission]> = .idle
    @Published private(set) var isMutating = false
    @Published var includeSystemTemplates = true
    @Published var createInput = CreateAdminRoleInput()
    @Published var errorMessage: String?

    let repository: any AdminAccessRepository
    private let listRoles: ListAdminRolesUseCase
    private let mutateRoles: MutateAdminRoleUseCase
    private let listPermissions: ListAdminPermissionsUseCase

    init(repository: any AdminAccessRepository) {
        self.repository = repository
        self.listRoles = ListAdminRolesUseCase(repository: repository)
        self.mutateRoles = MutateAdminRoleUseCase(repository: repository)
        self.listPermissions = ListAdminPermissionsUseCase(repository: repository)
    }

    var roles: [AdminAccessRole] {
        guard case .loaded(let roles) = state else { return [] }
        return roles
    }

    var permissions: [AdminAccessPermission] {
        guard case .loaded(let permissions) = permissionsState else { return [] }
        return permissions
    }

    var canCreateRole: Bool {
        !createInput.code.trimmed.isEmpty &&
        !createInput.name.trimmed.isEmpty &&
        !createInput.description.trimmed.isEmpty &&
        !createInput.permissionKeys.isEmpty &&
        !createInput.reason.trimmed.isEmpty
    }

    func load() async {
        if case .loaded = state { return }
        await refresh()
    }

    func refresh() async {
        state = .loading
        async let rolesTask = listRoles.execute(includeSystemTemplates: includeSystemTemplates)
        async let permissionsTask = listPermissions.execute(includeReserved: false)
        do {
            let (loadedRoles, loadedPermissions) = try await (rolesTask, permissionsTask)
            state = loadedRoles.isEmpty ? .empty("No hay roles configurados.") : .loaded(loadedRoles)
            permissionsState = loadedPermissions.isEmpty ? .empty("No hay permisos disponibles.") : .loaded(loadedPermissions)
        } catch {
            state = .failed(error.userFriendlyMessage)
        }
    }

    func createRole() async {
        guard canCreateRole else {
            errorMessage = "Completa código, nombre, descripción, permisos y motivo."
            return
        }
        isMutating = true
        errorMessage = nil
        do {
            _ = try await mutateRoles.create(createInput)
            createInput = CreateAdminRoleInput()
            await refresh()
        } catch {
            errorMessage = error.userFriendlyMessage
        }
        isMutating = false
    }
}

@MainActor
final class AdminRoleDetailViewModel: ObservableObject {
    @Published private(set) var state: LoadableViewState<AdminAccessRole> = .idle
    @Published private(set) var permissionsState: LoadableViewState<[AdminAccessPermission]> = .idle
    @Published private(set) var isMutating = false
    @Published var updateInput = UpdateAdminRoleInput()
    @Published var actionReason = ""
    @Published var errorMessage: String?

    private let roleId: String
    private let getRole: GetAdminRoleUseCase
    private let mutateRoles: MutateAdminRoleUseCase
    private let listPermissions: ListAdminPermissionsUseCase

    init(roleId: String, repository: any AdminAccessRepository) {
        self.roleId = roleId
        self.getRole = GetAdminRoleUseCase(repository: repository)
        self.mutateRoles = MutateAdminRoleUseCase(repository: repository)
        self.listPermissions = ListAdminPermissionsUseCase(repository: repository)
    }

    var role: AdminAccessRole? {
        guard case .loaded(let role) = state else { return nil }
        return role
    }

    var permissions: [AdminAccessPermission] {
        guard case .loaded(let permissions) = permissionsState else { return [] }
        return permissions
    }

    var canSave: Bool {
        !updateInput.name.trimmed.isEmpty &&
        !updateInput.description.trimmed.isEmpty &&
        !updateInput.permissionKeys.isEmpty &&
        !updateInput.reason.trimmed.isEmpty
    }

    var canRunAction: Bool { !actionReason.trimmed.isEmpty }

    func load() async {
        if case .loaded = state { return }
        await refresh()
    }

    func refresh() async {
        state = .loading
        async let roleTask = getRole.execute(id: roleId)
        async let permissionsTask = listPermissions.execute(includeReserved: false)
        do {
            let (loadedRole, loadedPermissions) = try await (roleTask, permissionsTask)
            state = .loaded(loadedRole)
            permissionsState = loadedPermissions.isEmpty ? .empty("No hay permisos disponibles.") : .loaded(loadedPermissions)
            hydrateUpdateInput(from: loadedRole)
        } catch {
            state = .failed(error.userFriendlyMessage)
        }
    }

    func save() async {
        guard canSave else {
            errorMessage = "Completa nombre, descripción, permisos y motivo."
            return
        }
        await mutate { try await mutateRoles.update(id: roleId, input: updateInput) }
    }

    func activate() async {
        guard canRunAction else {
            errorMessage = "Ingresa un motivo para activar el rol."
            return
        }
        await mutate { try await mutateRoles.activate(id: roleId, reason: actionReason) }
    }

    func deactivate() async {
        guard canRunAction else {
            errorMessage = "Ingresa un motivo para desactivar el rol."
            return
        }
        await mutate { try await mutateRoles.deactivate(id: roleId, reason: actionReason) }
    }

    private func mutate(_ operation: () async throws -> AdminAccessRole) async {
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

    private func hydrateUpdateInput(from role: AdminAccessRole) {
        updateInput.name = role.name
        updateInput.description = role.description
        updateInput.permissionKeys = role.permissionKeys
        if updateInput.reason.trimmed.isEmpty {
            updateInput.reason = "Actualizar rol desde Nexo Admin iOS"
        }
    }
}

private extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
}
