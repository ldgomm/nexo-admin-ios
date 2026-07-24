//
//  AdminSupplierViewModel.swift
//  Nexo Admin
//
//  27R.N.2 — Permission-gated supplier master state.
//

import Combine
import Foundation

@MainActor
final class AdminSupplierViewModel: ObservableObject {
    @Published var query = ""
    @Published var category = ""
    @Published var statusFilter: AdminSupplierStatusFilter = .all

    @Published private(set) var suppliers: [AdminSupplier] = []
    @Published private(set) var isLoading = false
    @Published private(set) var isLoadingMore = false
    @Published private(set) var isSaving = false
    @Published private(set) var hasMore = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var successMessage: String?

    private let repository: any AdminProcurementRepository
    private let permissions: Set<String>
    private var nextCursor: String?
    private var activeQuery: AdminSupplierListQuery?
    private var refreshGeneration = 0

    init(repository: any AdminProcurementRepository, permissions: Set<String>) {
        self.repository = repository
        self.permissions = permissions
    }

    var canView: Bool { AdminSupplierAccess.canView(permissions) }
    var canViewSensitive: Bool { AdminSupplierAccess.canViewSensitive(permissions) }
    var canCreate: Bool { AdminSupplierAccess.canCreate(permissions) }
    var canUpdate: Bool { AdminSupplierAccess.canUpdate(permissions) }
    var canManageStatus: Bool { AdminSupplierAccess.canManageStatus(permissions) }
    var hasActiveFilters: Bool {
        query.trimmedOrNil != nil || category.trimmedOrNil != nil || statusFilter != .all
    }

    func supplier(id: String) -> AdminSupplier? {
        suppliers.first(where: { $0.id == id })
    }

    func loadIfNeeded() async {
        guard suppliers.isEmpty else { return }
        await refresh()
    }

    func refresh() async {
        guard canView else {
            suppliers = []
            hasMore = false
            errorMessage = "Tu usuario no tiene permiso para consultar proveedores."
            return
        }

        refreshGeneration += 1
        let generation = refreshGeneration
        let request = AdminSupplierListQuery(
            query: query.trimmedOrNil,
            status: statusFilter,
            category: category.trimmedOrNil,
            limit: 50,
            cursor: nil
        )

        isLoading = true
        errorMessage = nil
        defer {
            if generation == refreshGeneration { isLoading = false }
        }

        do {
            let page = try await repository.listSuppliers(query: request)
            guard generation == refreshGeneration else { return }
            suppliers = unique(page.suppliers)
            nextCursor = page.nextCursor
            hasMore = page.hasMore && page.nextCursor?.trimmedOrNil != nil
            activeQuery = request
        } catch {
            guard generation == refreshGeneration else { return }
            suppliers = []
            nextCursor = nil
            hasMore = false
            activeQuery = nil
            errorMessage = error.userFriendlyMessage
        }
    }

    func loadMoreIfNeeded(current supplier: AdminSupplier) async {
        guard supplier.id == suppliers.last?.id else { return }
        await loadNextPage()
    }

    func loadNextPage() async {
        guard canView, hasMore, !isLoading, !isLoadingMore,
              let cursor = nextCursor?.trimmedOrNil,
              let activeQuery else { return }

        isLoadingMore = true
        errorMessage = nil
        defer { isLoadingMore = false }

        do {
            let page = try await repository.listSuppliers(
                query: AdminSupplierListQuery(
                    query: activeQuery.query,
                    status: activeQuery.status,
                    category: activeQuery.category,
                    limit: activeQuery.limit,
                    cursor: cursor
                )
            )
            suppliers = unique(suppliers + page.suppliers)
            nextCursor = page.nextCursor
            hasMore = page.hasMore && page.nextCursor?.trimmedOrNil != nil
        } catch {
            errorMessage = error.userFriendlyMessage
        }
    }

    @discardableResult
    func create(_ input: AdminSupplierWriteInput) async -> Bool {
        guard canCreate else {
            errorMessage = "Tu usuario no tiene permiso para crear proveedores."
            return false
        }
        guard input.expectedVersion == nil else {
            errorMessage = "Un proveedor nuevo no puede incluir una versión previa."
            return false
        }
        return await mutate(
            input: input,
            operation: { try await self.repository.createSupplier(input) },
            success: "Proveedor creado y auditado."
        )
    }

    @discardableResult
    func update(id: String, input: AdminSupplierWriteInput) async -> Bool {
        guard canUpdate else {
            errorMessage = "Tu usuario no tiene permiso para editar proveedores."
            return false
        }
        guard input.expectedVersion.map({ $0 > 0 }) == true else {
            errorMessage = "Falta la versión vigente del proveedor. Vuelve a cargar antes de guardar."
            return false
        }
        return await mutate(
            input: input,
            operation: { try await self.repository.updateSupplier(id: id, input: input) },
            success: "Proveedor actualizado con control de versión."
        )
    }

    @discardableResult
    func changeStatus(id: String, input: AdminSupplierStatusInput) async -> Bool {
        guard canManageStatus else {
            errorMessage = "Tu usuario no tiene permiso para cambiar el estado del proveedor."
            return false
        }
        guard input.expectedVersion > 0 else {
            errorMessage = "Falta la versión vigente del proveedor."
            return false
        }
        guard input.reason.trimmedOrNil != nil else {
            errorMessage = "Indica el motivo del cambio de estado."
            return false
        }
        guard input.idempotencyKey.trimmedOrNil != nil else {
            errorMessage = "No se pudo generar la clave segura de la operación."
            return false
        }
        if let current = supplier(id: id), current.status == input.status {
            errorMessage = "El proveedor ya está \(input.status.title.lowercased())."
            return false
        }
        guard !isSaving else { return false }

        isSaving = true
        errorMessage = nil
        successMessage = nil
        defer { isSaving = false }
        do {
            let result = try await repository.changeSupplierStatus(id: id, input: input)
            upsert(result.supplier)
            successMessage = result.idempotencyReplayed == true
                ? "El cambio ya había sido aplicado; se recuperó el mismo resultado."
                : "Estado del proveedor actualizado y auditado."
            return true
        } catch {
            errorMessage = error.userFriendlyMessage
            return false
        }
    }

    func clearFilters() async {
        query = ""
        category = ""
        statusFilter = .all
        await refresh()
    }

    func clearMessages() {
        errorMessage = nil
        successMessage = nil
    }

    private func mutate(
        input: AdminSupplierWriteInput,
        operation: () async throws -> AdminSupplierMutationResult,
        success: String
    ) async -> Bool {
        if let validationMessage = validate(input) {
            errorMessage = validationMessage
            return false
        }
        guard input.idempotencyKey.trimmedOrNil != nil else {
            errorMessage = "No se pudo generar la clave segura de la operación."
            return false
        }
        guard !isSaving else { return false }

        isSaving = true
        errorMessage = nil
        successMessage = nil
        defer { isSaving = false }
        do {
            let result = try await operation()
            upsert(result.supplier)
            successMessage = result.idempotencyReplayed == true
                ? "La operación ya había sido aplicada; se recuperó el mismo proveedor."
                : success
            return true
        } catch {
            errorMessage = error.userFriendlyMessage
            return false
        }
    }

    private func validate(_ input: AdminSupplierWriteInput) -> String? {
        guard input.legalName.trimmedOrNil != nil else {
            return "Ingresa la razón social del proveedor."
        }
        let hasIdentificationType = input.identificationType != nil
        let hasIdentificationNumber = input.identificationNumber.trimmedOrNil != nil
        guard hasIdentificationType == hasIdentificationNumber else {
            return "El tipo y número de identificación deben registrarse juntos."
        }
        guard input.contacts.allSatisfy({ $0.name.trimmedOrNil != nil }) else {
            return "Cada contacto debe tener nombre."
        }
        guard input.contacts.filter(\.isPrimary).count <= 1 else {
            return "Solo un contacto puede ser principal."
        }
        switch input.paymentTermsMode {
        case .immediate:
            break
        case .netDays:
            guard let netDays = input.netDays, (1...365).contains(netDays) else {
                return "El crédito debe estar entre 1 y 365 días."
            }
        case .custom:
            guard input.paymentTermsLabel.trimmedOrNil != nil else {
                return "Describe la condición de pago personalizada."
            }
        }
        return nil
    }

    private func upsert(_ supplier: AdminSupplier) {
        if let index = suppliers.firstIndex(where: { $0.id == supplier.id }) {
            suppliers[index] = supplier
        } else {
            suppliers.insert(supplier, at: 0)
        }
        if statusFilter.apiValue != nil, statusFilter.apiValue != supplier.status.rawValue {
            suppliers.removeAll(where: { $0.id == supplier.id })
        }
    }

    private func unique(_ values: [AdminSupplier]) -> [AdminSupplier] {
        var seen = Set<String>()
        return values.filter { seen.insert($0.id).inserted }
    }
}
