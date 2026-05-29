//
//  AdminBusinessAppReadinessViewModel.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import Combine
import Foundation

@MainActor
final class AdminBusinessAppReadinessViewModel: ObservableObject {
    @Published private(set) var state: LoadableViewState<AdminBusinessAppReadinessReport> = .idle
    @Published var errorMessage: String?

    private let repository: any AdminFoundationRepository
    private let permissions: Set<String>
    private let evaluator: AdminBusinessAppReadinessEvaluator

    init(
        repository: any AdminFoundationRepository,
        permissions: Set<String>,
        evaluator: AdminBusinessAppReadinessEvaluator = AdminBusinessAppReadinessEvaluator()
    ) {
        self.repository = repository
        self.permissions = permissions
        self.evaluator = evaluator
    }

    var report: AdminBusinessAppReadinessReport? {
        guard case .loaded(let report) = state else { return nil }
        return report
    }

    var canView: Bool {
        PermissionSet(permissions).canAny([
            PermissionCatalog.modulesView,
            PermissionCatalog.modulesManage,
            PermissionCatalog.organizationView,
            PermissionCatalog.reportsDashboardView,
            PermissionCatalog.supportDiagnosticsView
        ])
    }

    func load() async {
        if case .loaded = state { return }
        await refresh()
    }

    func refresh() async {
        guard canView else {
            state = .failed("Tu usuario no tiene permisos para ver readiness de Business App.")
            return
        }

        state = .loading
        errorMessage = nil

        do {
            let snapshot = try await GetAdminFoundationSnapshotUseCase(repository: repository).execute()
            state = .loaded(evaluator.evaluate(snapshot: snapshot))
        } catch {
            state = .failed(error.userFriendlyMessage)
        }
    }
}
