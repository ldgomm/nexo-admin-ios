//
//  AdminBusinessViewModel.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import Combine
import Foundation

@MainActor
final class AdminBusinessViewModel: ObservableObject {
    @Published private(set) var isLoading = false
    @Published private(set) var isSaving = false
    @Published private(set) var overview: AdminBusinessOverview?
    @Published private(set) var restaurantReadiness: AdminRestaurantReadiness?
    @Published private(set) var isLoadingRestaurantReadiness = false
    @Published private(set) var restaurantReadinessErrorMessage: String?
    @Published var errorMessage: String?
    @Published var successMessage: String?

    private let getOverview: GetAdminBusinessOverviewUseCase
    private let updateBusinessProfile: UpdateAdminBusinessProfileUseCase
    private let saveActivity: SaveAdminActivityUseCase
    private let changeActivityStatus: ChangeAdminActivityStatusUseCase
    private let saveBranch: SaveAdminBranchUseCase
    private let changeBranchStatus: ChangeAdminBranchStatusUseCase
    private let saveEmissionPoint: SaveAdminEmissionPointUseCase
    private let changeEmissionPointStatus: ChangeAdminEmissionPointStatusUseCase
    private let repository: any AdminBusinessRepository

    init(repository: any AdminBusinessRepository) {
        self.repository = repository
        self.getOverview = GetAdminBusinessOverviewUseCase(repository: repository)
        self.updateBusinessProfile = UpdateAdminBusinessProfileUseCase(repository: repository)
        self.saveActivity = SaveAdminActivityUseCase(repository: repository)
        self.changeActivityStatus = ChangeAdminActivityStatusUseCase(repository: repository)
        self.saveBranch = SaveAdminBranchUseCase(repository: repository)
        self.changeBranchStatus = ChangeAdminBranchStatusUseCase(repository: repository)
        self.saveEmissionPoint = SaveAdminEmissionPointUseCase(repository: repository)
        self.changeEmissionPointStatus = ChangeAdminEmissionPointStatusUseCase(repository: repository)
    }

    var business: AdminBusinessProfile? { overview?.business }
    var readiness: AdminBusinessReadiness? { overview?.readiness }
    var activities: [AdminBusinessActivity] { overview?.activities ?? [] }
    var branches: [AdminBusinessBranch] { overview?.branches ?? [] }
    var emissionPoints: [AdminEmissionPoint] { overview?.emissionPoints ?? [] }
    var primaryBranchId: String? { branches.first(where: { $0.isMain })?.id ?? branches.first?.id }

    func load() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            overview = try await getOverview.execute()
        } catch {
            errorMessage = error.userFacingMessage
        }
    }

    func refresh() async {
        await load()
    }

    func loadRestaurantReadiness(branchId: String? = nil) async {
        guard !isLoadingRestaurantReadiness else { return }
        isLoadingRestaurantReadiness = true
        restaurantReadinessErrorMessage = nil
        defer { isLoadingRestaurantReadiness = false }

        do {
            restaurantReadiness = try await repository.getRestaurantReadiness(branchId: branchId)
        } catch {
            restaurantReadinessErrorMessage = error.userFacingMessage
        }
    }

    func refreshRestaurantReadiness(branchId: String? = nil) async {
        await loadRestaurantReadiness(branchId: branchId)
    }

    func updateBusiness(_ input: UpdateAdminBusinessProfileInput) async -> Bool {
        guard validateReason(input.reason) else { return false }
        return await savingSuccess("Datos del negocio actualizados.") {
            let updated = try await updateBusinessProfile.execute(input)
            if let current = overview {
                overview = AdminBusinessOverview(
                    organizationId: current.organizationId,
                    overallStatus: current.overallStatus,
                    ready: current.ready,
                    generatedAt: current.generatedAt,
                    business: updated,
                    readiness: current.readiness,
                    counts: current.counts,
                    nextActions: current.nextActions,
                    activities: current.activities,
                    branches: current.branches,
                    emissionPoints: current.emissionPoints
                )
            }
        }
    }

    func saveActivity(_ input: SaveAdminActivityInput) async -> Bool {
        guard validateReason(input.reason), validateRequired(input.code, "El código de actividad es obligatorio."), validateRequired(input.name, "El nombre de actividad es obligatorio.") else { return false }
        return await savingSuccess(input.id == nil ? "Actividad creada." : "Actividad actualizada.") {
            _ = try await saveActivity.execute(input)
            overview = try await getOverview.execute()
        }
    }

    func activateActivity(_ activity: AdminBusinessActivity, reason: String) async -> Bool {
        guard validateReason(reason) else { return false }
        return await savingSuccess("Actividad activada.") {
            _ = try await changeActivityStatus.activate(id: activity.id, reason: reason)
            overview = try await getOverview.execute()
        }
    }

    func deactivateActivity(_ activity: AdminBusinessActivity, reason: String) async -> Bool {
        guard validateReason(reason) else { return false }
        return await savingSuccess("Actividad desactivada.") {
            _ = try await changeActivityStatus.deactivate(id: activity.id, reason: reason)
            overview = try await getOverview.execute()
        }
    }

    func saveBranch(_ input: SaveAdminBranchInput) async -> Bool {
        guard validateReason(input.reason), validateRequired(input.code, "El código de sucursal es obligatorio."), validateRequired(input.name, "El nombre de sucursal es obligatorio.") else { return false }
        return await savingSuccess(input.id == nil ? "Sucursal creada." : "Sucursal actualizada.") {
            _ = try await saveBranch.execute(input)
            overview = try await getOverview.execute()
        }
    }

    func activateBranch(_ branch: AdminBusinessBranch, reason: String) async -> Bool {
        guard validateReason(reason) else { return false }
        return await savingSuccess("Sucursal activada.") {
            _ = try await changeBranchStatus.activate(id: branch.id, reason: reason)
            overview = try await getOverview.execute()
        }
    }

    func deactivateBranch(_ branch: AdminBusinessBranch, reason: String) async -> Bool {
        guard validateReason(reason) else { return false }
        return await savingSuccess("Sucursal desactivada.") {
            _ = try await changeBranchStatus.deactivate(id: branch.id, reason: reason)
            overview = try await getOverview.execute()
        }
    }

    func saveEmissionPoint(_ input: SaveAdminEmissionPointInput) async -> Bool {
        guard validateReason(input.reason), validateRequired(input.branchId, "Selecciona una sucursal."), validateRequired(input.establishmentCode, "El establecimiento es obligatorio."), validateRequired(input.emissionPointCode, "El punto de emisión es obligatorio."), validateRequired(input.displayName, "El nombre visible es obligatorio.") else { return false }
        return await savingSuccess(input.id == nil ? "Punto de emisión creado." : "Punto de emisión actualizado.") {
            _ = try await saveEmissionPoint.execute(input)
            overview = try await getOverview.execute()
        }
    }

    func activateEmissionPoint(_ point: AdminEmissionPoint, reason: String) async -> Bool {
        guard validateReason(reason) else { return false }
        return await savingSuccess("Punto de emisión activado.") {
            _ = try await changeEmissionPointStatus.activate(id: point.id, reason: reason)
            overview = try await getOverview.execute()
        }
    }

    func deactivateEmissionPoint(_ point: AdminEmissionPoint, reason: String) async -> Bool {
        guard validateReason(reason) else { return false }
        return await savingSuccess("Punto de emisión desactivado.") {
            _ = try await changeEmissionPointStatus.deactivate(id: point.id, reason: reason)
            overview = try await getOverview.execute()
        }
    }

    private func savingSuccess(_ message: String, operation: () async throws -> Void) async -> Bool {
        guard !isSaving else { return false }
        isSaving = true
        errorMessage = nil
        successMessage = nil
        defer { isSaving = false }

        do {
            try await operation()
            successMessage = message
            return true
        } catch {
            errorMessage = error.userFacingMessage
            return false
        }
    }

    private func validateReason(_ reason: String) -> Bool {
        validateRequired(reason, "Ingresa un motivo para auditar este cambio.")
    }

    private func validateRequired(_ value: String, _ message: String) -> Bool {
        if value.trimmedOrNil == nil {
            errorMessage = message
            return false
        }
        return true
    }
}

private extension Error {
    var userFacingMessage: String {
        if let appError = self as? AppError { return appError.localizedDescription }
        return localizedDescription
    }
}
