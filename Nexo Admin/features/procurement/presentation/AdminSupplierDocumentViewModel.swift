//
//  AdminSupplierDocumentViewModel.swift
//  Nexo Admin
//
//  Created by José Ruiz on 29/7/26.
//
//  27R.N — Permission-gated, read-only supplier document register state.
//

import Combine
import Foundation

@MainActor
class AdminSupplierDocumentViewModel: ObservableObject {
    @Published var query = ""
    @Published var branchId = ""
    @Published var supplierId = ""
    @Published var documentDateFrom = ""
    @Published var documentDateTo = ""
    @Published var dueDateFrom = ""
    @Published var dueDateTo = ""
    @Published var documentTypeFilter: AdminSupplierDocumentTypeFilter = .all
    @Published var statusFilter: AdminSupplierDocumentStatusFilter = .all

    @Published private(set) var supplierDocuments: [AdminSupplierDocument] = []
    @Published private(set) var isLoading = false
    @Published private(set) var isLoadingMore = false
    @Published private(set) var isLoadingDetail = false
    @Published private(set) var hasMore = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var detailErrorMessage: String?

    private let repository: any AdminProcurementRepository
    private let permissions: Set<String>
    private var nextCursor: String?
    private var activeQuery: AdminSupplierDocumentListQuery?
    private var refreshGeneration = 0

    init(repository: any AdminProcurementRepository, permissions: Set<String>) {
        self.repository = repository
        self.permissions = permissions
    }

    var canView: Bool { AdminSupplierDocumentAccess.canView(permissions) }
    var canViewAudit: Bool { PermissionSet(permissions).can(PermissionCatalog.procurementAuditView) }

    var hasActiveFilters: Bool {
        query.trimmedOrNil != nil
            || branchId.trimmedOrNil != nil
            || supplierId.trimmedOrNil != nil
            || documentDateFrom.trimmedOrNil != nil
            || documentDateTo.trimmedOrNil != nil
            || dueDateFrom.trimmedOrNil != nil
            || dueDateTo.trimmedOrNil != nil
            || documentTypeFilter != .all
            || statusFilter != .all
    }

    func supplierDocument(id: String) -> AdminSupplierDocument? {
        supplierDocuments.first(where: { $0.id == id })
    }

    func loadIfNeeded() async {
        guard supplierDocuments.isEmpty else { return }
        await refresh()
    }

    func refresh() async {
        guard canView else {
            supplierDocuments = []
            hasMore = false
            errorMessage = "Tu usuario no tiene permiso para consultar documentos de proveedor."
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
            let page = try await repository.listSupplierDocuments(query: request)
            guard generation == refreshGeneration else { return }
            supplierDocuments = unique(page.supplierDocuments)
            nextCursor = page.nextCursor
            hasMore = page.hasMore && page.nextCursor?.trimmedOrNil != nil
            activeQuery = request
        } catch {
            guard generation == refreshGeneration else { return }
            supplierDocuments = []
            nextCursor = nil
            hasMore = false
            activeQuery = nil
            errorMessage = error.userFriendlyMessage
        }
    }

    func loadMoreIfNeeded(current document: AdminSupplierDocument) async {
        guard document.id == supplierDocuments.last?.id else { return }
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
            let page = try await repository.listSupplierDocuments(
                query: AdminSupplierDocumentListQuery(
                    branchId: activeQuery.branchId,
                    supplierId: activeQuery.supplierId,
                    documentType: activeQuery.documentType,
                    status: activeQuery.status,
                    documentDateFrom: activeQuery.documentDateFrom,
                    documentDateTo: activeQuery.documentDateTo,
                    dueDateFrom: activeQuery.dueDateFrom,
                    dueDateTo: activeQuery.dueDateTo,
                    query: activeQuery.query,
                    limit: activeQuery.limit,
                    cursor: cursor
                )
            )
            supplierDocuments = unique(supplierDocuments + page.supplierDocuments)
            nextCursor = page.nextCursor
            hasMore = page.hasMore && page.nextCursor?.trimmedOrNil != nil
        } catch {
            errorMessage = error.userFriendlyMessage
        }
    }

    func refreshDetail(id: String) async {
        guard canView else {
            detailErrorMessage = "Tu usuario no tiene permiso para consultar este documento."
            return
        }
        guard !isLoadingDetail else { return }

        isLoadingDetail = true
        detailErrorMessage = nil
        defer { isLoadingDetail = false }

        do {
            let document = try await repository.getSupplierDocument(id: id)
            guard document.id == id else {
                throw AppError.decoding("El backend respondió otro documento de proveedor.")
            }
            upsert(document)
        } catch {
            detailErrorMessage = error.userFriendlyMessage
        }
    }

    func clearFilters() async {
        query = ""
        branchId = ""
        supplierId = ""
        documentDateFrom = ""
        documentDateTo = ""
        dueDateFrom = ""
        dueDateTo = ""
        documentTypeFilter = .all
        statusFilter = .all
        await refresh()
    }

    private func validatedQuery(cursor: String?) -> AdminSupplierDocumentListQuery? {
        guard validateRange(
            from: documentDateFrom.trimmedOrNil,
            to: documentDateTo.trimmedOrNil,
            label: "La fecha del documento"
        ), validateRange(
            from: dueDateFrom.trimmedOrNil,
            to: dueDateTo.trimmedOrNil,
            label: "La fecha de vencimiento"
        ) else {
            return nil
        }

        return AdminSupplierDocumentListQuery(
            branchId: branchId.trimmedOrNil,
            supplierId: supplierId.trimmedOrNil,
            documentType: documentTypeFilter,
            status: statusFilter,
            documentDateFrom: documentDateFrom.trimmedOrNil,
            documentDateTo: documentDateTo.trimmedOrNil,
            dueDateFrom: dueDateFrom.trimmedOrNil,
            dueDateTo: dueDateTo.trimmedOrNil,
            query: query.trimmedOrNil,
            limit: 50,
            cursor: cursor
        )
    }

    private func validateRange(from: String?, to: String?, label: String) -> Bool {
        if let from, !Self.isValidDate(from) {
            errorMessage = "\(label) inicial debe usar AAAA-MM-DD."
            return false
        }
        if let to, !Self.isValidDate(to) {
            errorMessage = "\(label) final debe usar AAAA-MM-DD."
            return false
        }
        if let from, let to, from > to {
            errorMessage = "\(label) inicial no puede ser posterior a la final."
            return false
        }
        return true
    }

    private func upsert(_ document: AdminSupplierDocument) {
        if let index = supplierDocuments.firstIndex(where: { $0.id == document.id }) {
            supplierDocuments[index] = document
        } else {
            supplierDocuments.insert(document, at: 0)
        }
        if statusFilter.apiValue != nil, statusFilter.apiValue != document.status.rawValue {
            supplierDocuments.removeAll(where: { $0.id == document.id })
        }
        if documentTypeFilter.apiValue != nil, documentTypeFilter.apiValue != document.documentType.rawValue {
            supplierDocuments.removeAll(where: { $0.id == document.id })
        }
    }

    private func unique(_ values: [AdminSupplierDocument]) -> [AdminSupplierDocument] {
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
