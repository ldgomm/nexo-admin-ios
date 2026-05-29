//
//  AdminPublicProjectionViewModel.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import Combine
import Foundation

@MainActor
final class AdminPublicProjectionViewModel: ObservableObject {
    @Published private(set) var state: LoadableViewState<AdminPublicStoreProjection> = .idle
    @Published private(set) var isMutating = false
    @Published var settingsInput = AdminPublicProjectionSettingsInput()
    @Published var actionDraft = AdminPublicProjectionActionDraft()
    @Published var errorMessage: String?
    @Published var successMessage: String?

    private let repository: any AdminPublicProjectionRepository
    private let permissions: Set<String>

    init(repository: any AdminPublicProjectionRepository, permissions: Set<String>) {
        self.repository = repository
        self.permissions = permissions
    }

    var projection: AdminPublicStoreProjection? {
        guard case .loaded(let projection) = state else { return nil }
        return projection
    }

    var canView: Bool {
        PermissionSet(permissions).canAny([
            PermissionCatalog.publicProjectionView,
            PermissionCatalog.publicProjectionManage,
            PermissionCatalog.publicStorefrontView,
            PermissionCatalog.publicStorefrontManage
        ])
    }

    var canManage: Bool {
        PermissionSet(permissions).canAny([
            PermissionCatalog.publicProjectionManage,
            PermissionCatalog.publicStorefrontManage
        ])
    }

    var canSaveSettings: Bool {
        canManage &&
        !settingsInput.businessName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !settingsInput.locationVisibility.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !settingsInput.reason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var canRunAction: Bool {
        canManage && !actionDraft.reason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func load() async {
        if case .loaded = state { return }
        await refresh()
    }

    func refresh() async {
        guard canView else {
            state = .failed("Tu usuario no tiene permisos para ver Public Projection.")
            return
        }

        state = .loading
        errorMessage = nil

        do {
            let projection = try await repository.getProjection()
            hydrateSettings(from: projection)
            state = .loaded(projection)
        } catch {
            state = .failed(error.userFriendlyMessage)
        }
    }

    func prepareAction(_ action: AdminPublicProjectionAction) {
        actionDraft = AdminPublicProjectionActionDraft(action: action, reason: action.defaultReason)
    }

    func saveSettings() async {
        guard canSaveSettings else {
            errorMessage = "Completa nombre público, visibilidad y motivo."
            return
        }
        await mutate(success: "Configuración pública actualizada.") {
            try await repository.updateSettings(settingsInput)
        }
    }

    func runAction() async {
        guard canRunAction else {
            errorMessage = "Ingresa un motivo para la acción pública."
            return
        }

        await mutate(success: "Acción aplicada.") {
            switch actionDraft.action {
            case .publish:
                return try await repository.publish(reason: actionDraft.reason)
            case .hide:
                return try await repository.hide(reason: actionDraft.reason)
            case .suspend:
                return try await repository.suspend(reason: actionDraft.reason)
            }
        }
    }

    private func mutate(success: String, operation: () async throws -> AdminPublicStoreProjection) async {
        isMutating = true
        errorMessage = nil
        successMessage = nil
        do {
            let updated = try await operation()
            hydrateSettings(from: updated)
            state = .loaded(updated)
            successMessage = success
        } catch {
            errorMessage = error.userFriendlyMessage
        }
        isMutating = false
    }

    private func hydrateSettings(from projection: AdminPublicStoreProjection) {
        settingsInput.businessName = projection.businessName
        settingsInput.locationVisibility = projection.locationVisibility
        if settingsInput.reason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            settingsInput.reason = "Actualizar publicación pública desde Nexo Admin iOS"
        }
    }
}
