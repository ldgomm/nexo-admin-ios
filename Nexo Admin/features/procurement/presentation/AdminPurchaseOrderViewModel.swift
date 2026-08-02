//
//  AdminPurchaseOrderViewModel.swift
//  Nexo Admin
//
//  Created by José Ruiz on 29/7/26.
//
//  27R.N.3 — Permission-gated, read-only purchase order oversight state.
//

import Combine
import Foundation

@MainActor
class AdminPurchaseOrderViewModel: ObservableObject {
    @Published var query = ""
    @Published var branchId = ""
    @Published var supplierId = ""
    @Published var expectedFrom = ""
    @Published var expectedTo = ""
    @Published var statusFilter: AdminPurchaseOrderStatusFilter = .all

    @Published private(set) var purchaseOrders: [AdminPurchaseOrder] = []
    @Published private(set) var isLoading = false
    @Published private(set) var isLoadingMore = false
    @Published private(set) var isLoadingDetail = false
    @Published private(set) var hasMore = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var detailErrorMessage: String?

    private let repository: any AdminProcurementRepository
    private let permissions: Set<String>
    private var nextCursor: String?
    private var activeQuery: AdminPurchaseOrderListQuery?
    private var refreshGeneration = 0

    init(repository: any AdminProcurementRepository, permissions: Set<String>) {
        self.repository = repository
        self.permissions = permissions
    }

    var canView: Bool { AdminPurchaseOrderAccess.canView(permissions) }
    var canViewCosts: Bool { AdminPurchaseOrderAccess.canViewCosts(permissions) }
    var canViewReceipts: Bool { AdminPurchaseReceiptAccess.canView(permissions) }
    var hasActiveFilters: Bool {
        query.trimmedOrNil != nil
            || branchId.trimmedOrNil != nil
            || supplierId.trimmedOrNil != nil
            || expectedFrom.trimmedOrNil != nil
            || expectedTo.trimmedOrNil != nil
            || statusFilter != .all
    }

    func order(id: String) -> AdminPurchaseOrder? {
        purchaseOrders.first(where: { $0.id == id })
    }

    func makeReceiptViewModel(for purchaseOrderId: String) -> AdminPurchaseReceiptViewModel {
        AdminPurchaseReceiptViewModel(
            repository: repository,
            permissions: permissions,
            purchaseOrderId: purchaseOrderId
        )
    }

    func loadIfNeeded() async {
        guard purchaseOrders.isEmpty else { return }
        await refresh()
    }

    func refresh() async {
        guard canView else {
            purchaseOrders = []
            hasMore = false
            errorMessage = "Tu usuario no tiene permiso para supervisar órdenes de compra."
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
            let page = try await repository.listPurchaseOrders(query: request)
            guard generation == refreshGeneration else { return }
            purchaseOrders = unique(page.purchaseOrders)
            nextCursor = page.nextCursor
            hasMore = page.hasMore && page.nextCursor?.trimmedOrNil != nil
            activeQuery = request
        } catch {
            guard generation == refreshGeneration else { return }
            purchaseOrders = []
            nextCursor = nil
            hasMore = false
            activeQuery = nil
            errorMessage = error.userFriendlyMessage
        }
    }

    func loadMoreIfNeeded(current order: AdminPurchaseOrder) async {
        guard order.id == purchaseOrders.last?.id else { return }
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
            let page = try await repository.listPurchaseOrders(
                query: AdminPurchaseOrderListQuery(
                    branchId: activeQuery.branchId,
                    supplierId: activeQuery.supplierId,
                    status: activeQuery.status,
                    expectedFrom: activeQuery.expectedFrom,
                    expectedTo: activeQuery.expectedTo,
                    query: activeQuery.query,
                    limit: activeQuery.limit,
                    cursor: cursor
                )
            )
            purchaseOrders = unique(purchaseOrders + page.purchaseOrders)
            nextCursor = page.nextCursor
            hasMore = page.hasMore && page.nextCursor?.trimmedOrNil != nil
        } catch {
            errorMessage = error.userFriendlyMessage
        }
    }

    func refreshDetail(id: String) async {
        guard canView else {
            detailErrorMessage = "Tu usuario no tiene permiso para consultar esta orden."
            return
        }
        guard !isLoadingDetail else { return }

        isLoadingDetail = true
        detailErrorMessage = nil
        defer { isLoadingDetail = false }
        do {
            upsert(try await repository.getPurchaseOrder(id: id))
        } catch {
            detailErrorMessage = error.userFriendlyMessage
        }
    }

    func clearFilters() async {
        query = ""
        branchId = ""
        supplierId = ""
        expectedFrom = ""
        expectedTo = ""
        statusFilter = .all
        await refresh()
    }

    func clearMessages() {
        errorMessage = nil
        detailErrorMessage = nil
    }

    private func validatedQuery(cursor: String?) -> AdminPurchaseOrderListQuery? {
        let from = expectedFrom.trimmedOrNil
        let to = expectedTo.trimmedOrNil
        if let from, !Self.isValidDate(from) {
            errorMessage = "La fecha inicial debe usar AAAA-MM-DD."
            return nil
        }
        if let to, !Self.isValidDate(to) {
            errorMessage = "La fecha final debe usar AAAA-MM-DD."
            return nil
        }
        if let from, let to, from > to {
            errorMessage = "La fecha inicial no puede ser posterior a la fecha final."
            return nil
        }
        return AdminPurchaseOrderListQuery(
            branchId: branchId.trimmedOrNil,
            supplierId: supplierId.trimmedOrNil,
            status: statusFilter,
            expectedFrom: from,
            expectedTo: to,
            query: query.trimmedOrNil,
            limit: 50,
            cursor: cursor
        )
    }

    private func upsert(_ order: AdminPurchaseOrder) {
        if let index = purchaseOrders.firstIndex(where: { $0.id == order.id }) {
            purchaseOrders[index] = order
        } else {
            purchaseOrders.insert(order, at: 0)
        }
        if statusFilter.apiValue != nil, statusFilter.apiValue != order.status.rawValue {
            purchaseOrders.removeAll(where: { $0.id == order.id })
        }
    }

    private func unique(_ values: [AdminPurchaseOrder]) -> [AdminPurchaseOrder] {
        var seen = Set<String>()
        return values.filter { seen.insert($0.id).inserted }
    }

    private static func isValidDate(_ raw: String) -> Bool {
        guard raw.range(of: #"^[0-9]{4}-[0-9]{2}-[0-9]{2}$"#, options: .regularExpression) != nil else {
            return false
        }
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.isLenient = false
        guard let date = formatter.date(from: raw) else { return false }
        return formatter.string(from: date) == raw
    }
}
