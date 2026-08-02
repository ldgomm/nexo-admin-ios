//
//  AdminFinanceControlViewModel.swift
//  Nexo Admin
//
//  Created by José Ruiz on 29/7/26.
//

import Foundation
import Observation

@MainActor
@Observable
class AdminFinanceControlViewModel {
    private(set) var snapshot: AdminFinanceControlSnapshot?
    private(set) var isLoading = false
    private(set) var activeCommand: AdminFinanceControlAction?
    private(set) var lastActionReceipt: AdminFinanceControlActionReceipt?
    private(set) var errorMessage: String?
    private(set) var successMessage: String?

    private let repository: any AdminFinanceControlRepository
    private let accessPolicy: AdminFinanceControlAccessPolicy
    private let validator: AdminFinanceControlSnapshotValidator
    private let cutoverPolicy: AdminFinanceCutoverApprovalPolicy
    private var hasLoaded = false

    init(
        effectivePermissions: Set<String>,
        repository: any AdminFinanceControlRepository,
        validator: AdminFinanceControlSnapshotValidator = .init(),
        cutoverPolicy: AdminFinanceCutoverApprovalPolicy = .init()
    ) {
        self.repository = repository
        self.accessPolicy = AdminFinanceControlAccessPolicy(
            effectivePermissions: effectivePermissions
        )
        self.validator = validator
        self.cutoverPolicy = cutoverPolicy
    }

    var canViewSurface: Bool {
        accessPolicy.canViewSurface
    }

    func loadIfNeeded() async {
        guard !hasLoaded else { return }
        await load()
    }

    func load() async {
        guard accessPolicy.canViewSurface else {
            snapshot = nil
            errorMessage = "No tienes permiso para consultar este control financiero."
            hasLoaded = true
            return
        }

        isLoading = true
        errorMessage = nil
        successMessage = nil
        defer {
            isLoading = false
            hasLoaded = true
        }

        do {
            let loadedSnapshot = try await repository.loadSnapshot()
            try validator.validate(loadedSnapshot)
            snapshot = loadedSnapshot
        } catch AdminFinanceControlRepositoryError.runtimeEndpointUnavailable {
            snapshot = nil
            errorMessage = "La vista administrativa segura está instalada. La conexión con datos reales se habilita en el cierre runtime de 28R."
        } catch {
            snapshot = nil
            errorMessage = "No fue posible cargar el control financiero de forma segura."
        }
    }

    func canView(_ surface: AdminFinanceControlSurface) -> Bool {
        accessPolicy.canView(surface)
    }

    func allows(_ action: AdminFinanceControlAction) -> Bool {
        guard let snapshot else { return false }
        return accessPolicy.allows(action, capabilities: snapshot.capabilities)
    }

    func reviewImportBatch(
        id: String,
        reason: String
    ) async {
        guard let snapshot,
              accessPolicy.allows(
                .reviewImportBatch,
                capabilities: snapshot.capabilities
              ),
              isPresent(reason) else {
            errorMessage = "La revisión requiere permiso, capacidad y motivo."
            return
        }

        await runCommand(.reviewImportBatch) {
            try await repository.reviewImportBatch(
                id: id,
                reason: reason,
                expectedSourceRevision: snapshot.sourceRevision
            )
        }
    }

    func reviewReconciliationException(
        id: String,
        reason: String
    ) async {
        guard let snapshot,
              accessPolicy.allows(
                .reviewReconciliationException,
                capabilities: snapshot.capabilities
              ),
              isPresent(reason) else {
            errorMessage = "La excepción requiere permiso, capacidad y motivo."
            return
        }

        await runCommand(.reviewReconciliationException) {
            try await repository.reviewReconciliationException(
                id: id,
                reason: reason,
                expectedSourceRevision: snapshot.sourceRevision
            )
        }
    }

    func approveCutover(reason: String) async {
        guard let snapshot else {
            errorMessage = "No existe un estado autoritativo para aprobar."
            return
        }

        do {
            try cutoverPolicy.validate(
                snapshot: snapshot,
                accessPolicy: accessPolicy,
                reason: reason
            )
        } catch {
            errorMessage = "Cutover bloqueado: revisa permisos, diferencias, pendientes, evidencia y motivo."
            return
        }

        await runCommand(.approveCutover) {
            try await repository.approveCutover(
                reason: reason,
                expectedSourceRevision: snapshot.sourceRevision
            )
        }
    }

    func clearMessages() {
        errorMessage = nil
        successMessage = nil
    }

    private func runCommand(
        _ action: AdminFinanceControlAction,
        operation: () async throws -> AdminFinanceControlActionReceipt
    ) async {
        activeCommand = action
        errorMessage = nil
        successMessage = nil
        defer { activeCommand = nil }

        do {
            let receipt = try await operation()
            lastActionReceipt = receipt
            successMessage = "Acción registrada con evidencia \(receipt.evidenceId)."
        } catch AdminFinanceControlRepositoryError.runtimeEndpointUnavailable {
            errorMessage = "La acción permanece bloqueada hasta el cierre runtime de 28R."
        } catch {
            errorMessage = "El backend rechazó la acción; no se aplicó ningún cambio."
        }
    }

    private func isPresent(_ value: String) -> Bool {
        !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
