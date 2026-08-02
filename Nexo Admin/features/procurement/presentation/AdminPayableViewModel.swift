//
//  AdminPayableViewModel.swift
//  Nexo Admin
//
//  Created by José Ruiz on 29/7/26.
//
//  27R.N — Permission-gated, read-only payable ageing and due-date state.
//

import Combine
import Foundation

@MainActor
class AdminPayableViewModel: ObservableObject {
    @Published var branchId = ""
    @Published var supplierId = ""
    @Published var dueFrom = ""
    @Published var dueTo = ""
    @Published var currency = ""
    @Published var asOf = ""
    @Published var statusFilter: AdminPayableStatusFilter = .all

    @Published private(set) var payables: [AdminPayablePresentation] = []
    @Published private(set) var aging: AdminPayableAging?
    @Published private(set) var isLoading = false
    @Published private(set) var isLoadingMore = false
    @Published private(set) var isLoadingAging = false
    @Published private(set) var isLoadingDetail = false
    @Published private(set) var hasMore = false
    @Published private(set) var snapshotAsOf: String?
    @Published private(set) var errorMessage: String?
    @Published private(set) var agingErrorMessage: String?
    @Published private(set) var detailErrorMessage: String?
    @Published private(set) var referenceWarning: String?

    private let repository: any AdminProcurementRepository
    private let permissions: Set<String>
    private var nextCursor: String?
    private var activeQuery: AdminPayableListQuery?
    private var hasLoaded = false
    private var refreshGeneration = 0
    private var supplierNameCache: [String: String] = [:]
    private var sourceDocumentNumberCache: [String: String] = [:]

    init(repository: any AdminProcurementRepository, permissions: Set<String>) {
        self.repository = repository
        self.permissions = permissions
    }

    var canViewList: Bool { AdminPayableAccess.canViewList(permissions) }
    var canViewAging: Bool { AdminPayableAccess.canViewAging(permissions) }
    var canViewAudit: Bool { PermissionSet(permissions).can(PermissionCatalog.procurementAuditView) }

    var hasActiveFilters: Bool {
        branchId.trimmedOrNil != nil
            || supplierId.trimmedOrNil != nil
            || dueFrom.trimmedOrNil != nil
            || dueTo.trimmedOrNil != nil
            || currency.trimmedOrNil != nil
            || asOf.trimmedOrNil != nil
            || statusFilter != .all
    }

    func payablePresentation(id: String) -> AdminPayablePresentation? {
        payables.first(where: { $0.id == id })
    }

    func loadIfNeeded() async {
        guard !hasLoaded else { return }
        await refresh()
    }

    func refresh() async {
        guard AdminPayableAccess.canEnter(permissions) else {
            payables = []
            aging = nil
            hasMore = false
            errorMessage = "Tu usuario no tiene permiso para consultar cuentas por pagar ni su envejecimiento."
            return
        }
        guard let values = validatedFilterValues() else { return }

        refreshGeneration += 1
        let generation = refreshGeneration
        errorMessage = nil
        agingErrorMessage = nil
        detailErrorMessage = nil
        referenceWarning = nil

        if canViewList {
            await refreshList(values: values, generation: generation)
        } else {
            payables = []
            nextCursor = nil
            hasMore = false
            activeQuery = nil
            snapshotAsOf = nil
        }

        guard generation == refreshGeneration else { return }

        if canViewAging {
            await refreshAging(values: values, generation: generation)
        } else {
            aging = nil
        }

        guard generation == refreshGeneration else { return }
        hasLoaded = true
    }

    func loadMoreIfNeeded(current presentation: AdminPayablePresentation) async {
        guard presentation.id == payables.last?.id else { return }
        await loadNextPage()
    }

    func loadNextPage() async {
        guard canViewList, hasMore, !isLoading, !isLoadingMore,
              let cursor = nextCursor?.trimmedOrNil,
              let activeQuery else { return }

        isLoadingMore = true
        errorMessage = nil
        defer { isLoadingMore = false }

        do {
            let page = try await repository.listPayables(
                query: AdminPayableListQuery(
                    branchId: activeQuery.branchId,
                    supplierId: activeQuery.supplierId,
                    status: activeQuery.status,
                    dueFrom: activeQuery.dueFrom,
                    dueTo: activeQuery.dueTo,
                    currency: activeQuery.currency,
                    asOf: activeQuery.asOf,
                    limit: activeQuery.limit,
                    cursor: cursor
                )
            )
            let mapped = await presentations(for: page.payables)
            appendUnique(mapped)
            nextCursor = page.nextCursor
            hasMore = page.hasMore && page.nextCursor?.trimmedOrNil != nil
            snapshotAsOf = page.asOf
        } catch {
            errorMessage = error.userFriendlyMessage
        }
    }

    func refreshDetail(id: String) async {
        guard canViewList else {
            detailErrorMessage = "Tu usuario no tiene permiso para consultar esta cuenta por pagar."
            return
        }
        guard !isLoadingDetail else { return }

        isLoadingDetail = true
        detailErrorMessage = nil
        defer { isLoadingDetail = false }

        do {
            let payable = try await repository.getPayable(id: id, asOf: activeQuery?.asOf)
            guard payable.id == id else {
                throw AppError.decoding("El backend respondió otra cuenta por pagar.")
            }
            guard let presentation = await presentations(for: [payable]).first else {
                throw AppError.decoding("No se pudo presentar la cuenta por pagar recibida.")
            }
            upsert(presentation)
        } catch {
            detailErrorMessage = error.userFriendlyMessage
        }
    }

    func clearFilters() async {
        branchId = ""
        supplierId = ""
        dueFrom = ""
        dueTo = ""
        currency = ""
        asOf = ""
        statusFilter = .all
        await refresh()
    }

    private func refreshList(
        values: FilterValues,
        generation: Int
    ) async {
        let query = AdminPayableListQuery(
            branchId: values.branchId,
            supplierId: values.supplierId,
            status: statusFilter,
            dueFrom: values.dueFrom,
            dueTo: values.dueTo,
            currency: values.currency,
            asOf: values.asOf,
            limit: 50,
            cursor: nil
        )

        isLoading = true
        defer {
            if generation == refreshGeneration { isLoading = false }
        }

        do {
            let page = try await repository.listPayables(query: query)
            guard generation == refreshGeneration else { return }
            payables = await presentations(for: page.payables)
            nextCursor = page.nextCursor
            hasMore = page.hasMore && page.nextCursor?.trimmedOrNil != nil
            snapshotAsOf = page.asOf
            activeQuery = query
        } catch {
            guard generation == refreshGeneration else { return }
            payables = []
            nextCursor = nil
            hasMore = false
            snapshotAsOf = nil
            activeQuery = nil
            errorMessage = error.userFriendlyMessage
        }
    }

    private func refreshAging(
        values: FilterValues,
        generation: Int
    ) async {
        isLoadingAging = true
        defer {
            if generation == refreshGeneration { isLoadingAging = false }
        }

        do {
            let response = try await repository.getPayableAging(
                query: AdminPayableAgingQuery(
                    branchId: values.branchId,
                    supplierId: values.supplierId,
                    currency: values.currency,
                    asOf: values.asOf
                )
            )
            guard generation == refreshGeneration else { return }
            aging = response
        } catch {
            guard generation == refreshGeneration else { return }
            aging = nil
            agingErrorMessage = error.userFriendlyMessage
        }
    }

    private func presentations(for page: [AdminPayable]) async -> [AdminPayablePresentation] {
        var unavailableReference = false

        for payable in page {
            if supplierNameCache[payable.supplierId] == nil {
                if PermissionSet(permissions).can(PermissionCatalog.suppliersView) {
                    do {
                        let supplier = try await repository.getSupplier(id: payable.supplierId)
                        guard supplier.id == payable.supplierId else {
                            unavailableReference = true
                            continue
                        }
                        supplierNameCache[payable.supplierId] = supplier.tradeName?.trimmedOrNil ?? supplier.legalName
                    } catch {
                        unavailableReference = true
                    }
                } else {
                    unavailableReference = true
                }
            }

            if payable.sourceType.uppercased() == "SUPPLIER_DOCUMENT",
               sourceDocumentNumberCache[payable.sourceId] == nil {
                if PermissionSet(permissions).can(PermissionCatalog.supplierDocumentsView) {
                    do {
                        let document = try await repository.getSupplierDocument(id: payable.sourceId)
                        if document.id == payable.sourceId, document.supplierId == payable.supplierId {
                            sourceDocumentNumberCache[payable.sourceId] = document.documentNumber
                        } else {
                            unavailableReference = true
                        }
                    } catch {
                        unavailableReference = true
                    }
                } else {
                    unavailableReference = true
                }
            }
        }

        if unavailableReference {
            referenceWarning = "Algunos nombres de proveedor o documentos de origen están protegidos o no disponibles. Los importes, estados y saldos del backend siguen visibles."
        }

        return page.map {
            AdminPayablePresentation(
                payable: $0,
                supplierName: supplierNameCache[$0.supplierId],
                sourceDocumentNumber: sourceDocumentNumberCache[$0.sourceId]
            )
        }
    }

    private func appendUnique(_ page: [AdminPayablePresentation]) {
        var known = Set(payables.map(\.id))
        for presentation in page where known.insert(presentation.id).inserted {
            payables.append(presentation)
        }
    }

    private func upsert(_ presentation: AdminPayablePresentation) {
        if let index = payables.firstIndex(where: { $0.id == presentation.id }) {
            payables[index] = presentation
        } else {
            payables.insert(presentation, at: 0)
        }

        let payable = presentation.payable
        if !statusFilter.apiValues.isEmpty,
           !statusFilter.apiValues.contains(payable.effectiveStatus) {
            payables.removeAll(where: { $0.id == payable.id })
        }
        if let normalizedCurrency = currency.trimmedOrNil?.uppercased(),
           payable.currency != normalizedCurrency {
            payables.removeAll(where: { $0.id == payable.id })
        }
        if let normalizedDueFrom = dueFrom.trimmedOrNil, payable.dueDate < normalizedDueFrom {
            payables.removeAll(where: { $0.id == payable.id })
        }
        if let normalizedDueTo = dueTo.trimmedOrNil, payable.dueDate > normalizedDueTo {
            payables.removeAll(where: { $0.id == payable.id })
        }
    }

    private func validatedFilterValues() -> FilterValues? {
        let values = FilterValues(
            branchId: branchId.trimmedOrNil,
            supplierId: supplierId.trimmedOrNil,
            dueFrom: dueFrom.trimmedOrNil,
            dueTo: dueTo.trimmedOrNil,
            currency: currency.trimmedOrNil?.uppercased(),
            asOf: asOf.trimmedOrNil
        )

        if let dueFrom = values.dueFrom, !Self.isValidDate(dueFrom) {
            errorMessage = "La fecha inicial de vencimiento debe usar AAAA-MM-DD."
            return nil
        }
        if let dueTo = values.dueTo, !Self.isValidDate(dueTo) {
            errorMessage = "La fecha final de vencimiento debe usar AAAA-MM-DD."
            return nil
        }
        if let dueFrom = values.dueFrom, let dueTo = values.dueTo, dueFrom > dueTo {
            errorMessage = "La fecha inicial de vencimiento no puede ser posterior a la final."
            return nil
        }
        if let asOf = values.asOf, !Self.isValidDate(asOf) {
            errorMessage = "La fecha de corte debe usar AAAA-MM-DD."
            return nil
        }
        if let currency = values.currency,
           currency.range(of: "^[A-Z]{3}$", options: .regularExpression) == nil {
            errorMessage = "La moneda debe usar tres letras, por ejemplo USD."
            return nil
        }
        return values
    }

    private static func isValidDate(_ raw: String) -> Bool {
        guard raw.range(of: "^[0-9]{4}-[0-9]{2}-[0-9]{2}$", options: .regularExpression) != nil else {
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

    private struct FilterValues {
        let branchId: String?
        let supplierId: String?
        let dueFrom: String?
        let dueTo: String?
        let currency: String?
        let asOf: String?
    }
}
