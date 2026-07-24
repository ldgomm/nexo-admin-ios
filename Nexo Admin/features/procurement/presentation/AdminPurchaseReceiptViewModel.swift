//
//  AdminPurchaseReceiptViewModel.swift
//  Nexo Admin
//
//  27R.N.4 — Permission-gated, read-only receipt and inventory-effect state.
//

import Combine
import Foundation

@MainActor
final class AdminPurchaseReceiptViewModel: ObservableObject {
    @Published var branchId = ""
    @Published var supplierId = ""
    @Published var purchaseOrderId = ""
    @Published var receivedFrom = ""
    @Published var receivedTo = ""
    @Published var statusFilter: AdminPurchaseReceiptStatusFilter = .all

    @Published private(set) var receipts: [AdminPurchaseReceipt] = []
    @Published private(set) var isLoading = false
    @Published private(set) var isLoadingMore = false
    @Published private(set) var isLoadingDetail = false
    @Published private(set) var hasMore = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var detailErrorMessage: String?

    private let repository: any AdminProcurementRepository
    private let permissions: Set<String>
    private var nextCursor: String?
    private var activeQuery: AdminPurchaseReceiptListQuery?
    private var refreshGeneration = 0
    private var detailGeneration = 0
    private var effectsByReceiptId: [String: AdminPurchaseReceiptInventoryEffects] = [:]
    private var effectErrorsByReceiptId: [String: String] = [:]
    private var ordersByReceiptId: [String: AdminPurchaseOrder] = [:]
    private var orderErrorsByReceiptId: [String: String] = [:]

    init(
        repository: any AdminProcurementRepository,
        permissions: Set<String>,
        purchaseOrderId: String? = nil
    ) {
        self.repository = repository
        self.permissions = permissions
        self.purchaseOrderId = purchaseOrderId ?? ""
    }

    var canView: Bool { AdminPurchaseReceiptAccess.canView(permissions) }
    var canViewInventoryEffects: Bool {
        AdminPurchaseReceiptAccess.canViewInventoryEffects(permissions)
    }
    var canViewCosts: Bool { AdminPurchaseReceiptAccess.canViewCosts(permissions) }
    var canViewAudit: Bool { AdminPurchaseReceiptAccess.canViewAudit(permissions) }
    var canViewLinkedPurchaseOrder: Bool { AdminPurchaseOrderAccess.canView(permissions) }

    var hasActiveFilters: Bool {
        branchId.trimmedOrNil != nil
            || supplierId.trimmedOrNil != nil
            || purchaseOrderId.trimmedOrNil != nil
            || receivedFrom.trimmedOrNil != nil
            || receivedTo.trimmedOrNil != nil
            || statusFilter != .all
    }

    func receipt(id: String) -> AdminPurchaseReceipt? {
        receipts.first(where: { $0.id == id })
    }

    func inventoryEffects(receiptId: String) -> AdminPurchaseReceiptInventoryEffects? {
        effectsByReceiptId[receiptId]
    }

    func effectError(receiptId: String) -> String? {
        effectErrorsByReceiptId[receiptId]
    }

    func linkedPurchaseOrder(receiptId: String) -> AdminPurchaseOrder? {
        ordersByReceiptId[receiptId]
    }

    func linkedPurchaseOrderError(receiptId: String) -> String? {
        orderErrorsByReceiptId[receiptId]
    }

    func makePurchaseOrderViewModel() -> AdminPurchaseOrderViewModel {
        AdminPurchaseOrderViewModel(repository: repository, permissions: permissions)
    }

    func loadIfNeeded() async {
        guard receipts.isEmpty else { return }
        await refresh()
    }

    func refresh() async {
        guard canView else {
            receipts = []
            hasMore = false
            errorMessage = "Tu usuario no tiene permiso para revisar recepciones."
            return
        }
        guard let request = validatedQuery(cursor: nil) else { return }

        refreshGeneration += 1
        let generation = refreshGeneration
        isLoading = true
        errorMessage = nil
        defer {
            if generation == refreshGeneration { isLoading = false }
        }

        do {
            let page = try await repository.listPurchaseReceipts(query: request)
            guard generation == refreshGeneration else { return }
            receipts = unique(page.receipts)
            nextCursor = page.nextCursor
            hasMore = page.hasMore && page.nextCursor?.trimmedOrNil != nil
            activeQuery = request
        } catch {
            guard generation == refreshGeneration else { return }
            receipts = []
            nextCursor = nil
            hasMore = false
            activeQuery = nil
            errorMessage = error.userFriendlyMessage
        }
    }

    func loadMoreIfNeeded(current receipt: AdminPurchaseReceipt) async {
        guard receipt.id == receipts.last?.id else { return }
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
            let page = try await repository.listPurchaseReceipts(
                query: AdminPurchaseReceiptListQuery(
                    branchId: activeQuery.branchId,
                    supplierId: activeQuery.supplierId,
                    purchaseOrderId: activeQuery.purchaseOrderId,
                    status: activeQuery.status,
                    receivedFrom: activeQuery.receivedFrom,
                    receivedTo: activeQuery.receivedTo,
                    limit: activeQuery.limit,
                    cursor: cursor
                )
            )
            receipts = unique(receipts + page.receipts)
            nextCursor = page.nextCursor
            hasMore = page.hasMore && page.nextCursor?.trimmedOrNil != nil
        } catch {
            errorMessage = error.userFriendlyMessage
        }
    }

    func refreshDetail(id: String) async {
        guard canView else {
            detailErrorMessage = "Tu usuario no tiene permiso para consultar esta recepción."
            return
        }
        guard !isLoadingDetail else { return }

        detailGeneration += 1
        let generation = detailGeneration
        isLoadingDetail = true
        detailErrorMessage = nil
        effectsByReceiptId[id] = nil
        effectErrorsByReceiptId[id] = nil
        ordersByReceiptId[id] = nil
        orderErrorsByReceiptId[id] = nil
        defer {
            if generation == detailGeneration { isLoadingDetail = false }
        }

        do {
            let receipt = try await repository.getPurchaseReceipt(id: id)
            guard generation == detailGeneration else { return }
            upsert(receipt)
            await loadInventoryEffects(for: receipt, generation: generation)
            await loadLinkedOrder(for: receipt, generation: generation)
        } catch {
            guard generation == detailGeneration else { return }
            detailErrorMessage = error.userFriendlyMessage
        }
    }

    func clearFilters() async {
        branchId = ""
        supplierId = ""
        purchaseOrderId = ""
        receivedFrom = ""
        receivedTo = ""
        statusFilter = .all
        await refresh()
    }

    func clearMessages() {
        errorMessage = nil
        detailErrorMessage = nil
    }

    private func loadInventoryEffects(
        for receipt: AdminPurchaseReceipt,
        generation: Int
    ) async {
        guard canViewInventoryEffects else {
            effectsByReceiptId[receipt.id] = nil
            effectErrorsByReceiptId[receipt.id] =
                "Se requieren purchase_receipts.view e inventory.view para consultar el efecto canónico."
            return
        }
        do {
            let effects = try await repository.getPurchaseReceiptInventoryEffects(id: receipt.id)
            guard generation == detailGeneration else { return }
            guard effects.receiptId == receipt.id,
                  effects.receiptNumber == receipt.receiptNumber,
                  effects.receiptStatus == receipt.status,
                  effects.branchId == receipt.branchId,
                  effects.supplierId == receipt.supplierId,
                  effects.purchaseOrderId == receipt.purchaseOrderId,
                  effects.warehouseId == receipt.warehouseId else {
                throw AppError.decoding("La evidencia de inventario no corresponde a la recepción.")
            }
            if !canViewCosts, effects.costsVisible {
                throw AppError.decoding("El backend expuso costos sin el permiso efectivo requerido.")
            }
            effectsByReceiptId[receipt.id] = effects
        } catch {
            guard generation == detailGeneration else { return }
            effectsByReceiptId[receipt.id] = nil
            effectErrorsByReceiptId[receipt.id] = error.userFriendlyMessage
        }
    }

    private func loadLinkedOrder(
        for receipt: AdminPurchaseReceipt,
        generation: Int
    ) async {
        guard let orderId = receipt.purchaseOrderId?.trimmedOrNil else {
            ordersByReceiptId[receipt.id] = nil
            orderErrorsByReceiptId[receipt.id] = nil
            return
        }
        guard canViewLinkedPurchaseOrder else {
            ordersByReceiptId[receipt.id] = nil
            orderErrorsByReceiptId[receipt.id] =
                "La orden vinculada requiere purchase_orders.view."
            return
        }
        do {
            let order = try await repository.getPurchaseOrder(id: orderId)
            guard generation == detailGeneration else { return }
            guard order.id == orderId,
                  order.branchId == receipt.branchId,
                  order.supplierId == receipt.supplierId else {
                throw AppError.decoding("La orden vinculada no corresponde a la recepción.")
            }
            ordersByReceiptId[receipt.id] = order
        } catch {
            guard generation == detailGeneration else { return }
            ordersByReceiptId[receipt.id] = nil
            orderErrorsByReceiptId[receipt.id] = error.userFriendlyMessage
        }
    }

    private func validatedQuery(cursor: String?) -> AdminPurchaseReceiptListQuery? {
        let from = receivedFrom.trimmedOrNil
        let to = receivedTo.trimmedOrNil
        let fromDate = from.flatMap(Self.isoInstant)
        let toDate = to.flatMap(Self.isoInstant)

        if from != nil, fromDate == nil {
            errorMessage = "La fecha inicial debe ser un instante ISO 8601."
            return nil
        }
        if to != nil, toDate == nil {
            errorMessage = "La fecha final debe ser un instante ISO 8601."
            return nil
        }
        if let fromDate, let toDate, fromDate > toDate {
            errorMessage = "La fecha inicial no puede ser posterior a la fecha final."
            return nil
        }
        return AdminPurchaseReceiptListQuery(
            branchId: branchId.trimmedOrNil,
            supplierId: supplierId.trimmedOrNil,
            purchaseOrderId: purchaseOrderId.trimmedOrNil,
            status: statusFilter,
            receivedFrom: from,
            receivedTo: to,
            limit: 50,
            cursor: cursor
        )
    }

    private func upsert(_ receipt: AdminPurchaseReceipt) {
        if let index = receipts.firstIndex(where: { $0.id == receipt.id }) {
            receipts[index] = receipt
        } else {
            receipts.insert(receipt, at: 0)
        }
        if statusFilter.apiValue != nil, statusFilter.apiValue != receipt.status.rawValue {
            receipts.removeAll(where: { $0.id == receipt.id })
        }
    }

    private func unique(_ values: [AdminPurchaseReceipt]) -> [AdminPurchaseReceipt] {
        var seen = Set<String>()
        return values.filter { seen.insert($0.id).inserted }
    }

    private static func isoInstant(_ value: String) -> Date? {
        let standard = ISO8601DateFormatter()
        if let date = standard.date(from: value) { return date }
        let fractional = ISO8601DateFormatter()
        fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return fractional.date(from: value)
    }
}
