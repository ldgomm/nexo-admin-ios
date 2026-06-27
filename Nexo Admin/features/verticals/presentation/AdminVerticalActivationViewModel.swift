//
//  AdminVerticalActivationViewModel.swift
//  Nexo Admin
//
//  Created by Nexo on 26/6/26.
//

import Combine
import Foundation

@MainActor
final class AdminVerticalActivationViewModel: ObservableObject {
    @Published private(set) var state: LoadableViewState<AdminVerticalActivationPresentation> = .idle
    @Published private(set) var isMutating = false
    @Published var activationReason = "Activar restaurante v1 desde Nexo Admin iOS"
    @Published var deactivationReason = "Desactivar restaurante v1 desde Nexo Admin iOS"
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published private(set) var tablesReadiness: AdminRestaurantTablesReadiness?
    @Published private(set) var tablesReadinessErrorMessage: String?
    @Published private(set) var isLoadingTablesReadiness = false

    let permissions: Set<String>
    private let repository: any AdminVerticalsRepository
    private let loadActivation: LoadAdminVerticalActivationUseCase
    private let changeActivation: ChangeAdminVerticalActivationUseCase

    init(repository: any AdminVerticalsRepository, permissions: Set<String>) {
        self.permissions = permissions
        self.repository = repository
        self.loadActivation = LoadAdminVerticalActivationUseCase(repository: repository)
        self.changeActivation = ChangeAdminVerticalActivationUseCase(repository: repository)
    }

    var presentation: AdminVerticalActivationPresentation? {
        guard case .loaded(let presentation) = state else { return nil }
        return presentation
    }

    var canViewVerticals: Bool {
        let permissionSet = PermissionSet(permissions)
        return permissionSet.canAny([
            PermissionCatalog.verticalsView,
            PermissionCatalog.verticalsReadinessView,
            PermissionCatalog.modulesView,
            PermissionCatalog.modulesManage
        ])
    }

    var canManageVerticals: Bool {
        let permissionSet = PermissionSet(permissions)
        return permissionSet.canAny([
            PermissionCatalog.verticalsActivate,
            PermissionCatalog.verticalsDeactivate,
            PermissionCatalog.modulesManage
        ])
    }

    var canActivateRestaurant: Bool {
        guard canManageVerticals, !isMutating, let presentation else { return false }
        return presentation.isRestaurantAvailable && !presentation.isRestaurantActive && !activationReason.trimmedForVerticals.isEmpty
    }

    var canDeactivateRestaurant: Bool {
        guard canManageVerticals, !isMutating, let presentation else { return false }
        return presentation.isRestaurantActive && !deactivationReason.trimmedForVerticals.isEmpty
    }

    func load() async {
        if case .loaded = state { return }
        await refresh()
    }

    func refresh() async {
        guard canViewVerticals else {
            state = .failed("Tu usuario no tiene permisos para ver verticales.")
            return
        }

        state = .loading
        errorMessage = nil
        tablesReadinessErrorMessage = nil

        do {
            let presentation = try await loadActivation.execute(verticalCode: AdminVerticalCode.restaurant)
            state = .loaded(presentation)
            await refreshTablesReadiness()
        } catch {
            state = .failed(error.userFriendlyMessage)
        }
    }


    func refreshTablesReadiness() async {
        guard canViewVerticals else { return }

        isLoadingTablesReadiness = true
        tablesReadinessErrorMessage = nil
        do {
            tablesReadiness = try await repository.restaurantTablesReadiness(branchId: nil)
        } catch {
            tablesReadiness = nil
            tablesReadinessErrorMessage = error.userFriendlyMessage
        }
        isLoadingTablesReadiness = false
    }

    func activateRestaurant() async {
        guard let presentation else {
            errorMessage = "Carga verticales antes de activar restaurante."
            return
        }
        guard canActivateRestaurant else {
            errorMessage = "No se puede activar: revisa permisos, motivo y estado actual."
            return
        }

        isMutating = true
        errorMessage = nil
        successMessage = nil
        do {
            let capabilities = presentation.defaultEnabledCapabilities.ifEmpty([
                "restaurant.menu_attributes",
                "restaurant.service_type",
                "restaurant.event_service"
            ])
            _ = try await changeActivation.activateRestaurant(
                reason: activationReason.trimmedForVerticals,
                defaultWorkMode: presentation.defaultWorkMode,
                enabledCapabilities: capabilities
            )
            successMessage = "Restaurante v1 activado para la organización."
            await refresh()
        } catch {
            errorMessage = error.userFriendlyMessage
        }
        isMutating = false
    }

    func deactivateRestaurant() async {
        guard canDeactivateRestaurant else {
            errorMessage = "No se puede desactivar: revisa permisos, motivo y estado actual."
            return
        }

        isMutating = true
        errorMessage = nil
        successMessage = nil
        do {
            _ = try await changeActivation.deactivateRestaurant(reason: deactivationReason.trimmedForVerticals)
            successMessage = "Restaurante v1 desactivado. El historial no se elimina."
            await refresh()
        } catch {
            errorMessage = error.userFriendlyMessage
        }
        isMutating = false
    }
}

private extension String {
    var trimmedForVerticals: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private extension Array where Element == String {
    func ifEmpty(_ fallback: [String]) -> [String] {
        isEmpty ? fallback : self
    }
}
