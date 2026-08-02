//
//  AdminProcurementReadinessViewModel.swift
//  Nexo Admin
//
//  Created by José Ruiz on 29/7/26.
//
//  27R.N.1B — Procurement readiness state.
//

import Combine
import Foundation

@MainActor
class AdminProcurementReadinessViewModel: ObservableObject {
    @Published private(set) var state: LoadableViewState<AdminProcurementReadinessReport> = .idle

    private let permissions: Set<String>
    private let getReadiness: GetAdminProcurementReadinessReportUseCase

    init(
        foundationRepository: any AdminFoundationRepository,
        procurementRepository: any AdminProcurementRepository,
        permissions: Set<String>,
        evaluator: AdminProcurementReadinessEvaluator = AdminProcurementReadinessEvaluator()
    ) {
        self.permissions = permissions
        self.getReadiness = GetAdminProcurementReadinessReportUseCase(
            foundationRepository: foundationRepository,
            procurementRepository: procurementRepository,
            evaluator: evaluator
        )
    }

    var report: AdminProcurementReadinessReport? {
        guard case .loaded(let report) = state else { return nil }
        return report
    }

    var canView: Bool {
        AdminProcurementReadinessAccess.allows(permissions)
    }

    func load() async {
        if case .loaded = state { return }
        await refresh()
    }

    func refresh() async {
        guard canView else {
            state = .failed("Tu usuario no tiene todos los permisos de lectura necesarios para consultar saldos, hechos y auditoría de compras.")
            return
        }

        state = .loading
        do {
            state = .loaded(try await getReadiness.execute())
        } catch {
            state = .failed(error.userFriendlyMessage)
        }
    }
}
