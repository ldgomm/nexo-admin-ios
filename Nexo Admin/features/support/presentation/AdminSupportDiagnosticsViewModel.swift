//
//  AdminSupportDiagnosticsViewModel.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import Combine
import Foundation

@MainActor
final class AdminSupportDiagnosticsViewModel: ObservableObject {
    @Published private(set) var state: LoadableViewState<AdminSupportDiagnosticsSnapshot> = .idle
    @Published var errorMessage: String?

    private let repository: any AdminSupportRepository
    private let permissions: Set<String>
    private let buildInfoProvider: () -> BuildInfo

    init(
        repository: any AdminSupportRepository,
        permissions: Set<String>,
        buildInfoProvider: @escaping () -> BuildInfo = { BuildInfo.current() }
    ) {
        self.repository = repository
        self.permissions = permissions
        self.buildInfoProvider = buildInfoProvider
    }

    var canView: Bool {
        PermissionSet(permissions).canAny([
            PermissionCatalog.supportView,
            PermissionCatalog.supportDiagnosticsView,
            PermissionCatalog.healthView,
            PermissionCatalog.observabilityView,
            PermissionCatalog.devicesView,
            PermissionCatalog.auditView
        ])
    }

    func load() async {
        if case .loaded = state { return }
        await refresh()
    }

    func refresh() async {
        guard canView else {
            state = .failed("Tu usuario no tiene permisos para ver diagnóstico de soporte.")
            return
        }

        state = .loading
        errorMessage = nil
        let buildInfo = buildInfoProvider()

        do {
            async let healthTask = repository.getHealth()
            async let devicesTask = repository.listDevices()
            let (health, devices) = try await (healthTask, devicesTask)
            let snapshot = AdminSupportDiagnosticsSnapshot(
                buildInfo: buildInfo,
                health: health,
                devices: devices
            )
            state = .loaded(snapshot)
        } catch {
            state = .failed(error.userFriendlyMessage)
        }
    }
}
