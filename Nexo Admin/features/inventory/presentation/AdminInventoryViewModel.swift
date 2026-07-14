//
//  AdminInventoryViewModel.swift
//  Nexo Admin
//

import Combine
import Foundation

@MainActor
final class AdminInventoryViewModel: ObservableObject {
    @Published var selectedBranchId: String
    @Published var selectedActivityId: String
    @Published var query = ""
    @Published var selectedFilter: AdminInventoryFilter = .all
    @Published private(set) var items: [AdminInventoryItem] = []
    @Published private(set) var movementsByCatalogItem: [String: [AdminInventoryMovement]] = [:]
    @Published private(set) var isLoading = false
    @Published private(set) var isSaving = false
    @Published private(set) var isExportingKardex = false
    @Published private(set) var downloadedKardexFile: AdminInventoryDownloadedFile?
    @Published var errorMessage: String?
    @Published var successMessage: String?

    let branches: [AdminBusinessBranch]
    let activities: [AdminBusinessActivity]
    let permissions: Set<String>
    private let repository: any AdminInventoryRepository

    init(
        repository: any AdminInventoryRepository,
        branches: [AdminBusinessBranch],
        activities: [AdminBusinessActivity],
        permissions: Set<String>
    ) {
        let activeActivities = activities
            .filter { $0.status == .active }
            .sorted {
                let lhsIsRetail = $0.activityType == "retail_store" || $0.workflowMode == "quick_sale"
                let rhsIsRetail = $1.activityType == "retail_store" || $1.workflowMode == "quick_sale"
                if lhsIsRetail != rhsIsRetail { return lhsIsRetail }
                if $0.sortOrder != $1.sortOrder { return $0.sortOrder < $1.sortOrder }
                return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
        self.repository = repository
        self.branches = branches
        self.activities = activeActivities
        self.permissions = permissions
        selectedBranchId = branches.first(where: { $0.isMain && $0.status == .active })?.id
            ?? branches.first(where: { $0.status == .active })?.id
            ?? branches.first?.id
            ?? ""
        selectedActivityId = activeActivities.first?.id ?? ""
    }

    var canView: Bool {
        canAny([PermissionCatalog.inventoryView])
    }

    var canAdjust: Bool {
        canAny([PermissionCatalog.inventoryAdjust])
    }

    var canExportKardex: Bool { canView }

    var visibleItems: [AdminInventoryItem] {
        let normalizedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines).folding(
            options: [.diacriticInsensitive, .caseInsensitive],
            locale: Locale(identifier: "es_EC")
        )

        return items.filter { item in
            let matchesQuery: Bool
            if normalizedQuery.isEmpty {
                matchesQuery = true
            } else {
                let haystack = [item.displayName, item.sku, item.barcode, item.catalogItemId]
                    .compactMap { $0 }
                    .joined(separator: " ")
                    .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "es_EC"))
                matchesQuery = haystack.contains(normalizedQuery)
            }

            let matchesFilter: Bool
            switch selectedFilter {
            case .all: matchesFilter = true
            case .tracked: matchesFilter = item.tracksInventory && item.hasStockProfile
            case .lowStock: matchesFilter = item.isLowStock
            case .outOfStock: matchesFilter = item.tracksInventory && item.isOutOfStock
            case .unconfigured: matchesFilter = item.needsConfiguration
            }
            return matchesQuery && matchesFilter
        }
    }

    var readiness: AdminInventoryReadiness { AdminInventoryReadiness(items: items) }

    var hasActiveFilters: Bool {
        !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || selectedFilter != .all
    }

    var visibleResultTitle: String {
        hasActiveFilters
            ? "Productos · \(visibleItems.count) de \(items.count)"
            : "Productos · \(items.count)"
    }

    var inventoryScopeMessage: String {
        if hasActiveFilters {
            return "La salud resume los \(items.count) productos de la actividad y sucursal; la consulta actual muestra \(visibleItems.count)."
        }
        return "La salud resume todos los productos de la actividad y sucursal seleccionadas."
    }

    func item(catalogItemId: String) -> AdminInventoryItem? {
        items.first(where: { $0.catalogItemId == catalogItemId })
    }

    func movements(catalogItemId: String) -> [AdminInventoryMovement] {
        movementsByCatalogItem[catalogItemId] ?? []
    }

    func loadIfNeeded() async {
        guard items.isEmpty else { return }
        await refresh()
    }

    func refresh() async {
        guard canView else {
            errorMessage = "Tu usuario no tiene permiso para consultar inventario."
            return
        }
        guard !selectedBranchId.isEmpty else {
            errorMessage = "Configura una sucursal antes de administrar inventario."
            return
        }
        guard !selectedActivityId.isEmpty else {
            errorMessage = "Activa al menos una actividad antes de administrar inventario."
            return
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            items = try await repository.listInventory(
                branchId: selectedBranchId,
                activityId: selectedActivityId,
                query: nil
            )
                .sorted { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
        } catch {
            errorMessage = error.userFriendlyMessage
        }
    }

    func loadMovements(for item: AdminInventoryItem) async {
        guard canView else { return }
        do {
            movementsByCatalogItem[item.catalogItemId] = try await repository.listMovements(
                branchId: selectedBranchId,
                catalogItemId: item.catalogItemId,
                warehouseId: item.warehouseId
            )
        } catch {
            errorMessage = error.userFriendlyMessage
        }
    }

    func exportConsolidatedKardex() async {
        guard canExportKardex else {
            errorMessage = "Tu usuario no tiene permiso para exportar inventario."
            return
        }
        guard !selectedBranchId.isEmpty, !selectedActivityId.isEmpty else {
            errorMessage = "Selecciona sucursal y actividad antes de exportar."
            return
        }
        guard !isExportingKardex else { return }
        isExportingKardex = true
        errorMessage = nil
        successMessage = nil
        downloadedKardexFile = nil
        defer { isExportingKardex = false }
        let period = Self.defaultKardexPeriod()
        do {
            downloadedKardexFile = try await repository.downloadConsolidatedKardex(
                branchId: selectedBranchId, activityId: selectedActivityId,
                from: period.from, to: period.to, warehouseId: nil, movementType: nil
            )
            successMessage = "Kardex consolidado listo para compartir."
        } catch {
            errorMessage = error.userFriendlyMessage
        }
    }

    @discardableResult
    func savePolicy(catalogItemId: String, input: AdminInventoryPolicyInput) async -> Bool {
        guard canAdjust else {
            errorMessage = "Tu usuario no tiene permiso para cambiar la política de inventario."
            return false
        }
        guard !input.reason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Indica el motivo del cambio de política."
            return false
        }
        guard !input.stockUnit.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Indica la unidad de stock."
            return false
        }
        guard validNonNegativeNumber(input.lowStockThreshold) else {
            errorMessage = "El stock mínimo debe ser un número mayor o igual a cero."
            return false
        }
        if let referenceCost = input.referenceCost, !referenceCost.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
           !validNonNegativeNumber(referenceCost) {
            errorMessage = "El costo referencial debe ser un número mayor o igual a cero."
            return false
        }

        isSaving = true
        errorMessage = nil
        successMessage = nil
        defer { isSaving = false }
        do {
            try await repository.updatePolicy(catalogItemId: catalogItemId, input: input)
            successMessage = input.tracksInventory
                ? "Política guardada. Ya puedes fijar el stock inicial."
                : "Control de inventario desactivado."
            await refresh()
            return true
        } catch {
            errorMessage = error.userFriendlyMessage
            return false
        }
    }

    @discardableResult
    func adjust(_ input: AdminInventoryAdjustmentInput) async -> Bool {
        guard canAdjust else {
            errorMessage = "Tu usuario no tiene permiso para ajustar inventario."
            return false
        }
        guard validPositiveNumber(input.quantity) else {
            errorMessage = "La cantidad debe ser un número mayor que cero."
            return false
        }
        guard !input.reason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Indica el motivo del ajuste."
            return false
        }

        isSaving = true
        errorMessage = nil
        successMessage = nil
        defer { isSaving = false }
        do {
            let result = try await repository.adjust(input)
            replace(result.balance)
            movementsByCatalogItem[input.catalogItemId] = [result.movement] + movements(catalogItemId: input.catalogItemId)
            successMessage = result.idempotencyReplayed
                ? "El ajuste ya había sido aplicado; se recuperó el mismo resultado."
                : "Stock actualizado y movimiento auditado."
            await refresh()
            if let refreshed = item(catalogItemId: input.catalogItemId) {
                await loadMovements(for: refreshed)
            }
            return true
        } catch {
            errorMessage = error.userFriendlyMessage
            return false
        }
    }

    func clearMessages() {
        errorMessage = nil
        successMessage = nil
    }

    func clearFilters() {
        query = ""
        selectedFilter = .all
    }

    private func replace(_ item: AdminInventoryItem) {
        if let index = items.firstIndex(where: { $0.catalogItemId == item.catalogItemId }) {
            items[index] = item
        } else {
            items.append(item)
        }
    }

    private func validPositiveNumber(_ raw: String) -> Bool {
        decimal(raw).map { $0 > .zero } == true
    }

    private func validNonNegativeNumber(_ raw: String) -> Bool {
        decimal(raw).map { $0 >= .zero } == true
    }

    private func decimal(_ raw: String) -> Decimal? {
        Decimal(
            string: raw.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: ",", with: "."),
            locale: Locale(identifier: "en_US_POSIX")
        )
    }

    private func canAny(_ required: Set<String>) -> Bool {
        permissions.contains(PermissionCatalog.all) || !permissions.isDisjoint(with: required)
    }

    private static func defaultKardexPeriod() -> (from: String, to: String) {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Guayaquil") ?? .current
        let end = Date()
        let start = calendar.date(byAdding: .day, value: -29, to: end) ?? end
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "yyyy-MM-dd"
        return (formatter.string(from: start), formatter.string(from: end))
    }
}
