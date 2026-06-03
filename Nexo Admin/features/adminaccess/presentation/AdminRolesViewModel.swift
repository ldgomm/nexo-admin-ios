//
//  AdminRolesViewModel.swift
//  Nexo Admin
//
//  Created by José Ruiz on 2/6/26.
//

import Combine
import Foundation

@MainActor
final class AdminRolesViewModel: ObservableObject {
    @Published private(set) var state: LoadableViewState<[AdminAccessRole]> = .idle
    @Published private(set) var permissionsState: LoadableViewState<[AdminAccessPermission]> = .idle
    @Published private(set) var isMutating = false
    @Published private(set) var missingTemplatePermissions: Set<String> = []
    @Published var includeSystemTemplates = true
    @Published var selectedTemplate: BusinessRoleTemplate?
    @Published var showOnlyBusinessPermissions = true
    @Published var createInput = CreateAdminRoleInput()
    @Published var permissionSearchText = ""
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
        return permissions.activeWithoutWildcard
    }

    var filteredPermissions: [AdminAccessPermission] {
        var result = permissions
        if showOnlyBusinessPermissions {
            result = result.filter(\.isBusinessFacing)
        }
        let query = permissionSearchText.trimmed.lowercased()
        guard !query.isEmpty else { return result }
        return result.filter { permission in
            permission.code.lowercased().contains(query) ||
            permission.name.lowercased().contains(query) ||
            permission.description.lowercased().contains(query) ||
            permission.categoryLabel.lowercased().contains(query)
        }
    }

    var templatePreviews: [BusinessRoleTemplatePreview] {
        BusinessRoleTemplate.previews(availablePermissions: permissions)
    }

    var canCreateRole: Bool {
        !createInput.code.trimmed.isEmpty &&
        !createInput.name.trimmed.isEmpty &&
        !createInput.description.trimmed.isEmpty &&
        !createInput.permissionKeys.isEmpty &&
        !createInput.permissionKeys.contains(PermissionCatalog.all) &&
        !createInput.reason.trimmed.isEmpty
    }

    var createWarnings: [String] {
        var warnings: [String] = []
        if createInput.permissionKeys.contains(PermissionCatalog.all) {
            warnings.append("No uses wildcard (*) en roles de organización. El backend lo reserva para plataforma.")
        }
        if !missingTemplatePermissions.isEmpty {
            warnings.append("La plantilla tiene \(missingTemplatePermissions.count) permisos que este backend aún no publica. Se aplicaron solo los disponibles.")
        }
        let selected = permissions.filter { createInput.permissionKeys.contains($0.code) }
        if selected.contains(where: \.isHighRisk) {
            warnings.append("Este rol contiene permisos de alto riesgo o auditados. Usa un motivo claro para trazabilidad.")
        }
        if selected.contains(where: \.isCredentialPermission) {
            warnings.append("Este rol puede afectar usuarios, roles o sesiones. Asígnalo solo a administradores reales.")
        }
        return warnings
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
            let visiblePermissions = loadedPermissions.activeWithoutWildcard
            permissionsState = visiblePermissions.isEmpty ? .empty("No hay permisos disponibles.") : .loaded(visiblePermissions)
            reconcileSelectedPermissions(with: visiblePermissions)
        } catch {
            state = .failed(error.userFriendlyMessage)
            permissionsState = .failed(error.userFriendlyMessage)
        }
    }

    func applyTemplate(_ template: BusinessRoleTemplate) {
        selectedTemplate = template
        createInput.code = template.code
        createInput.name = template.title
        createInput.description = template.description
        createInput.reason = template.defaultReason
        let available = permissions.existingCodes(from: template.permissionKeys)
        createInput.permissionKeys = available
        missingTemplatePermissions = template.permissionKeys.subtracting(available)
    }

    func clearTemplate() {
        selectedTemplate = nil
        missingTemplatePermissions = []
    }

    func createRole() async {
        guard canCreateRole else {
            errorMessage = "Completa código, nombre, descripción, permisos y motivo. No uses wildcard (*)."
            return
        }
        isMutating = true
        errorMessage = nil
        do {
            _ = try await mutateRoles.create(createInput)
            createInput = CreateAdminRoleInput()
            selectedTemplate = nil
            missingTemplatePermissions = []
            permissionSearchText = ""
            await refresh()
        } catch {
            errorMessage = error.userFriendlyMessage
        }
        isMutating = false
    }

    private func reconcileSelectedPermissions(with loadedPermissions: [AdminAccessPermission]) {
        let valid = Set(loadedPermissions.map(\.code))
        createInput.permissionKeys = createInput.permissionKeys.intersection(valid)
    }
}

@MainActor
final class AdminRoleDetailViewModel: ObservableObject {
    @Published private(set) var state: LoadableViewState<AdminAccessRole> = .idle
    @Published private(set) var permissionsState: LoadableViewState<[AdminAccessPermission]> = .idle
    @Published private(set) var isMutating = false
    @Published var updateInput = UpdateAdminRoleInput()
    @Published var actionReason = ""
    @Published var showOnlyBusinessPermissions = true
    @Published var permissionSearchText = ""
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
        return permissions.activeWithoutWildcard
    }

    var filteredPermissions: [AdminAccessPermission] {
        var result = permissions
        if showOnlyBusinessPermissions {
            result = result.filter(\.isBusinessFacing)
        }
        let query = permissionSearchText.trimmed.lowercased()
        guard !query.isEmpty else { return result }
        return result.filter { permission in
            permission.code.lowercased().contains(query) ||
            permission.name.lowercased().contains(query) ||
            permission.description.lowercased().contains(query) ||
            permission.categoryLabel.lowercased().contains(query)
        }
    }

    var canSave: Bool {
        guard role?.canBeEditedFromApp == true else { return false }
        return !updateInput.name.trimmed.isEmpty &&
        !updateInput.description.trimmed.isEmpty &&
        !updateInput.permissionKeys.isEmpty &&
        !updateInput.permissionKeys.contains(PermissionCatalog.all) &&
        !updateInput.reason.trimmed.isEmpty
    }

    var canRunAction: Bool { !actionReason.trimmed.isEmpty }

    var updateWarnings: [String] {
        var warnings: [String] = []
        if updateInput.permissionKeys.contains(PermissionCatalog.all) {
            warnings.append("No uses wildcard (*) en roles de organización.")
        }
        let selected = permissions.filter { updateInput.permissionKeys.contains($0.code) }
        if selected.contains(where: \.isHighRisk) {
            warnings.append("Este rol contiene permisos de alto riesgo o auditados.")
        }
        if selected.contains(where: \.isCredentialPermission) {
            warnings.append("Cambiar estos permisos puede afectar administración de usuarios, roles o sesiones.")
        }
        return warnings
    }

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
            let visiblePermissions = loadedPermissions.activeWithoutWildcard
            permissionsState = visiblePermissions.isEmpty ? .empty("No hay permisos disponibles.") : .loaded(visiblePermissions)
            hydrateUpdateInput(from: loadedRole, availablePermissions: visiblePermissions)
        } catch {
            state = .failed(error.userFriendlyMessage)
            permissionsState = .failed(error.userFriendlyMessage)
        }
    }

    func save() async {
        guard canSave else {
            errorMessage = "Completa nombre, descripción, permisos y motivo. No puedes editar roles protegidos ni usar wildcard (*)."
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
            hydrateUpdateInput(from: updated, availablePermissions: permissions)
            actionReason = ""
        } catch {
            errorMessage = error.userFriendlyMessage
        }
        isMutating = false
    }

    private func hydrateUpdateInput(from role: AdminAccessRole, availablePermissions: [AdminAccessPermission]) {
        updateInput.name = role.name
        updateInput.description = role.description
        let validCodes = Set(availablePermissions.map(\.code))
        updateInput.permissionKeys = role.permissionKeys.intersection(validCodes)
        if updateInput.reason.trimmed.isEmpty {
            updateInput.reason = "Actualizar rol desde Nexo Admin iOS"
        }
    }
}

private extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
}
