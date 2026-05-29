//
//  AdminFoundationViewModel.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import Combine
import Foundation

@MainActor
final class AdminFoundationViewModel: ObservableObject {
    @Published private(set) var state: LoadableViewState<AdminFoundationSnapshot> = .idle
    @Published private(set) var isMutating = false
    @Published var selectedBranchId: String?
    @Published var actionDraft = AdminFoundationModuleActionDraft()
    @Published var errorMessage: String?
    @Published var successMessage: String?

    let permissions: Set<String>
    private let getSnapshot: GetAdminFoundationSnapshotUseCase
    private let changeModuleStatus: ChangeAdminModuleStatusUseCase

    init(repository: any AdminFoundationRepository, permissions: Set<String>) {
        self.permissions = permissions
        self.getSnapshot = GetAdminFoundationSnapshotUseCase(repository: repository)
        self.changeModuleStatus = ChangeAdminModuleStatusUseCase(repository: repository)
    }

    var snapshot: AdminFoundationSnapshot? {
        guard case .loaded(let snapshot) = state else { return nil }
        return snapshot
    }

    var canViewModules: Bool {
        PermissionSet(permissions).canAny([PermissionCatalog.modulesView, PermissionCatalog.modulesManage])
    }

    var canManageModules: Bool {
        PermissionSet(permissions).can(PermissionCatalog.modulesManage)
    }

    var canRunAction: Bool {
        !actionDraft.moduleCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !actionDraft.reason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        canManageModules
    }

    func load() async {
        if case .loaded = state { return }
        await refresh()
    }

    func refresh() async {
        guard canViewModules else {
            state = .failed("Tu usuario no tiene permisos para ver módulos.")
            return
        }

        state = .loading
        errorMessage = nil

        do {
            let loaded = try await getSnapshot.execute(branchId: selectedBranchId)
            state = .loaded(loaded)
            if selectedBranchId == nil {
                selectedBranchId = loaded.context.activeBranch?.id
            }
        } catch {
            state = .failed(error.userFriendlyMessage)
        }
    }

    func prepareToggle(module: AdminResolvedModule) {
        actionDraft = AdminFoundationModuleActionDraft(
            moduleCode: module.code,
            reason: "Actualizar módulo \(module.code) desde Nexo Admin iOS",
            enable: !module.active
        )
    }

    func runToggle() async {
        guard canRunAction else {
            errorMessage = "Completa el motivo y verifica permisos para gestionar módulos."
            return
        }

        isMutating = true
        errorMessage = nil
        successMessage = nil
        do {
            if actionDraft.enable {
                _ = try await changeModuleStatus.enable(code: actionDraft.moduleCode, reason: actionDraft.reason)
                successMessage = "Módulo activado."
            } else {
                _ = try await changeModuleStatus.disable(code: actionDraft.moduleCode, reason: actionDraft.reason)
                successMessage = "Módulo desactivado."
            }
            await refresh()
        } catch {
            errorMessage = error.userFriendlyMessage
        }
        isMutating = false
    }
}
