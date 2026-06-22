//
//  AdminBusinessPackagesDiagnosticsViewModel.swift
//  Nexo Admin
//
//  Created by Nexo on 22/6/26.
//

import Combine
import Foundation

@MainActor
final class AdminBusinessPackagesDiagnosticsViewModel: ObservableObject {
    @Published private(set) var state: LoadableViewState<AdminBusinessPackagesDiagnosticsPresentation> = .idle

    let permissions: Set<String>
    private let loadDiagnostics: LoadAdminBusinessPackagesDiagnosticsUseCase

    init(repository: any AdminBusinessPackagesRepository, permissions: Set<String>) {
        self.permissions = permissions
        self.loadDiagnostics = LoadAdminBusinessPackagesDiagnosticsUseCase(repository: repository)
    }

    var canViewPackages: Bool {
        PermissionSet(permissions).canAny([PermissionCatalog.modulesView, PermissionCatalog.modulesManage])
    }

    func load() async {
        if case .loaded = state { return }
        await refresh()
    }

    func refresh() async {
        guard canViewPackages else {
            state = .failed("Tu usuario no tiene permisos para ver paquetes del negocio.")
            return
        }

        state = .loading

        do {
            let presentation = try await loadDiagnostics.execute()
            state = .loaded(presentation)
        } catch {
            state = .failed(error.userFriendlyMessage)
        }
    }
}
