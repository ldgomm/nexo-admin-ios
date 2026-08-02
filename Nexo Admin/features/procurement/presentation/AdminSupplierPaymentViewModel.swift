//
//  AdminSupplierPaymentViewModel.swift
//  Nexo Admin
//
//  Created by José Ruiz on 29/7/26.
//
//  27R.N — Permission-gated supplier-payment review and controlled void state.
//

import Combine
import Foundation

@MainActor
class AdminSupplierPaymentViewModel: ObservableObject {
    @Published var branchId = ""
    @Published var supplierId = ""
    @Published var paymentFrom = ""
    @Published var paymentTo = ""
    @Published var query = ""
    @Published var statusFilter: AdminSupplierPaymentStatusFilter = .all
    @Published var methodFilter: AdminSupplierPaymentMethodFilter = .all

    @Published private(set) var supplierPayments: [AdminSupplierPaymentPresentation] = []
    @Published private(set) var detailPayments: [String: AdminSupplierPaymentPresentation] = [:]
    @Published private(set) var payableReferenceTitles: [String: String] = [:]
    @Published private(set) var isLoading = false
    @Published private(set) var isLoadingMore = false
    @Published private(set) var isLoadingDetail = false
    @Published private(set) var isVoidingPaymentId: String?
    @Published private(set) var hasMore = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var detailErrorMessage: String?
    @Published private(set) var detailInfoMessage: String?
    @Published private(set) var referenceWarning: String?
    @Published private(set) var detailReferenceWarning: String?

    private let repository: any AdminProcurementRepository
    private let permissions: Set<String>
    private var nextCursor: String?
    private var activeQuery: AdminSupplierPaymentListQuery?
    private var hasLoaded = false
    private var supplierNameCache: [String: String] = [:]
    private var payableReferenceTitleCache: [String: String] = [:]
    private var voidIdempotencyKeys: [String: VoidIntentKey] = [:]

    init(repository: any AdminProcurementRepository, permissions: Set<String>) {
        self.repository = repository
        self.permissions = permissions
    }

    var canView: Bool { AdminSupplierPaymentAccess.canView(permissions) }
    var canViewSensitive: Bool { AdminSupplierPaymentAccess.canViewSensitive(permissions) }
    var canViewAudit: Bool { AdminSupplierPaymentAccess.canViewAudit(permissions) }

    var hasActiveFilters: Bool {
        branchId.trimmedOrNil != nil
            || supplierId.trimmedOrNil != nil
            || paymentFrom.trimmedOrNil != nil
            || paymentTo.trimmedOrNil != nil
            || query.trimmedOrNil != nil
            || statusFilter != .all
            || (canViewSensitive && methodFilter != .all)
    }

    func paymentPresentation(id: String) -> AdminSupplierPaymentPresentation? {
        detailPayments[id] ?? supplierPayments.first(where: { $0.id == id })
    }

    func payableReferenceTitle(for allocation: AdminSupplierPaymentAllocation, index: Int) -> String {
        payableReferenceTitles[allocation.payableId]
            ?? payableReferenceTitleCache[allocation.payableId]
            ?? "Cuenta por pagar \(index + 1)"
    }

    func canVoid(paymentId: String) -> Bool {
        guard let payment = paymentPresentation(id: paymentId)?.payment else { return false }
        return AdminSupplierPaymentAccess.canVoid(payment.status, permissions: permissions)
    }

    func isVoiding(paymentId: String) -> Bool {
        isVoidingPaymentId == paymentId
    }

    func loadIfNeeded() async {
        guard !hasLoaded else { return }
        await refresh()
    }

    func refresh() async {
        guard canView else {
            supplierPayments = []
            hasMore = false
            errorMessage = "Tu usuario no tiene permiso para consultar pagos a proveedores."
            return
        }
        guard let values = validatedFilterValues() else { return }
        guard !isLoading else { return }

        let listQuery = AdminSupplierPaymentListQuery(
            branchId: values.branchId,
            supplierId: values.supplierId,
            status: statusFilter,
            paymentFrom: values.paymentFrom,
            paymentTo: values.paymentTo,
            method: values.method,
            query: values.query,
            limit: 50,
            cursor: nil
        )

        isLoading = true
        errorMessage = nil
        referenceWarning = nil
        defer { isLoading = false }

        do {
            let page = try await repository.listSupplierPayments(query: listQuery)
            supplierPayments = await presentations(for: page.supplierPayments, detail: false)
            nextCursor = page.nextCursor
            hasMore = page.hasMore && page.nextCursor?.trimmedOrNil != nil
            activeQuery = listQuery
            hasLoaded = true
        } catch {
            supplierPayments = []
            nextCursor = nil
            hasMore = false
            activeQuery = nil
            errorMessage = error.userFriendlyMessage
        }
    }

    func loadMoreIfNeeded(current presentation: AdminSupplierPaymentPresentation) async {
        guard presentation.id == supplierPayments.last?.id else { return }
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
            let page = try await repository.listSupplierPayments(
                query: AdminSupplierPaymentListQuery(
                    branchId: activeQuery.branchId,
                    supplierId: activeQuery.supplierId,
                    status: activeQuery.status,
                    paymentFrom: activeQuery.paymentFrom,
                    paymentTo: activeQuery.paymentTo,
                    method: activeQuery.method,
                    query: activeQuery.query,
                    limit: activeQuery.limit,
                    cursor: cursor
                )
            )
            let mapped = await presentations(for: page.supplierPayments, detail: false)
            appendUnique(mapped)
            nextCursor = page.nextCursor
            hasMore = page.hasMore && page.nextCursor?.trimmedOrNil != nil
        } catch {
            errorMessage = error.userFriendlyMessage
        }
    }

    func refreshDetail(id: String) async {
        guard canView else {
            detailErrorMessage = "Tu usuario no tiene permiso para consultar este pago a proveedor."
            return
        }
        guard !isLoadingDetail else { return }

        isLoadingDetail = true
        detailErrorMessage = nil
        detailInfoMessage = nil
        detailReferenceWarning = nil
        defer { isLoadingDetail = false }

        do {
            let payment = try await repository.getSupplierPayment(id: id)
            guard payment.id == id else {
                throw AppError.decoding("El backend respondió otro pago a proveedor.")
            }
            let result = await presentation(for: payment)
            detailPayments[id] = result.presentation
            if result.referenceUnavailable {
                detailReferenceWarning = supplierReferenceWarning
            }
            replaceInList(payment)
            await hydratePayableReferences(for: payment)
        } catch {
            detailErrorMessage = error.userFriendlyMessage
        }
    }

    func voidPayment(id: String, reason: String) async -> AdminSupplierPayment? {
        guard canView else {
            detailErrorMessage = "Tu usuario no tiene permiso para consultar este pago a proveedor."
            return nil
        }
        guard isVoidingPaymentId == nil else { return nil }
        guard let payment = paymentPresentation(id: id)?.payment else {
            detailErrorMessage = "Actualiza el detalle antes de anular el pago."
            return nil
        }
        guard AdminSupplierPaymentAccess.canVoid(payment.status, permissions: permissions) else {
            detailErrorMessage = payment.status == .recorded
                ? "Tu usuario no tiene permiso para anular pagos a proveedores."
                : "Solo un pago registrado puede anularse. Actualiza el detalle para confirmar su estado."
            return nil
        }
        guard payment.version > 0 else {
            detailErrorMessage = "No se encontró una versión válida del pago."
            return nil
        }

        let normalizedReason = reason.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedReason.isEmpty else {
            detailErrorMessage = "Ingresa el motivo de anulación."
            return nil
        }

        let input = AdminSupplierPaymentVoidInput(
            reason: normalizedReason,
            expectedVersion: payment.version,
            idempotencyKey: voidIdempotencyKey(
                for: payment.id,
                expectedVersion: payment.version,
                normalizedReason: normalizedReason
            )
        )

        isVoidingPaymentId = payment.id
        detailErrorMessage = nil
        detailInfoMessage = nil
        defer { isVoidingPaymentId = nil }

        do {
            let result = try await repository.voidSupplierPayment(id: payment.id, input: input)
            guard result.supplierPayment.id == payment.id else {
                throw AppError.decoding("El backend respondió otro pago después de la anulación.")
            }
            let presentationResult = await presentation(for: result.supplierPayment)
            detailPayments[payment.id] = presentationResult.presentation
            replaceInList(result.supplierPayment)
            await hydratePayableReferences(for: result.supplierPayment)
            detailInfoMessage = voidSuccessMessage(
                status: result.supplierPayment.status,
                replayed: result.idempotencyReplayed == true
            )
            return result.supplierPayment
        } catch {
            detailErrorMessage = error.userFriendlyMessage
            return nil
        }
    }

    func clearFilters() async {
        branchId = ""
        supplierId = ""
        paymentFrom = ""
        paymentTo = ""
        query = ""
        statusFilter = .all
        methodFilter = .all
        await refresh()
    }

    private func presentations(
        for payments: [AdminSupplierPayment],
        detail: Bool
    ) async -> [AdminSupplierPaymentPresentation] {
        var mapped: [AdminSupplierPaymentPresentation] = []
        var unavailableReference = false
        for payment in payments {
            let result = await presentation(for: payment)
            mapped.append(result.presentation)
            unavailableReference = unavailableReference || result.referenceUnavailable
        }
        if unavailableReference {
            if detail {
                detailReferenceWarning = supplierReferenceWarning
            } else {
                referenceWarning = supplierReferenceWarning
            }
        }
        return mapped
    }

    private func presentation(
        for payment: AdminSupplierPayment
    ) async -> (presentation: AdminSupplierPaymentPresentation, referenceUnavailable: Bool) {
        if supplierNameCache[payment.supplierId] == nil {
            guard PermissionSet(permissions).can(PermissionCatalog.suppliersView) else {
                return (
                    AdminSupplierPaymentPresentation(payment: payment, supplierName: nil),
                    true
                )
            }
            do {
                let supplier = try await repository.getSupplier(id: payment.supplierId)
                guard supplier.id == payment.supplierId else {
                    return (
                        AdminSupplierPaymentPresentation(payment: payment, supplierName: nil),
                        true
                    )
                }
                supplierNameCache[payment.supplierId] = supplier.tradeName?.trimmedOrNil ?? supplier.legalName
            } catch {
                return (
                    AdminSupplierPaymentPresentation(payment: payment, supplierName: nil),
                    true
                )
            }
        }

        return (
            AdminSupplierPaymentPresentation(
                payment: payment,
                supplierName: supplierNameCache[payment.supplierId]
            ),
            false
        )
    }

    private func hydratePayableReferences(for payment: AdminSupplierPayment) async {
        payableReferenceTitles = [:]
        var unavailableReference = false

        guard PermissionSet(permissions).can(PermissionCatalog.payablesView) else {
            if !payment.allocations.isEmpty {
                detailReferenceWarning = payableReferenceWarning
            }
            return
        }

        var attemptedPayableIds = Set<String>()
        for allocation in payment.allocations {
            guard attemptedPayableIds.insert(allocation.payableId).inserted else { continue }
            if let cached = payableReferenceTitleCache[allocation.payableId] {
                payableReferenceTitles[allocation.payableId] = cached
                continue
            }
            do {
                let payable = try await repository.getPayable(id: allocation.payableId, asOf: nil)
                guard payable.id == allocation.payableId,
                      payable.supplierId == payment.supplierId else {
                    unavailableReference = true
                    continue
                }
                let title = await payableTitle(for: payable, payment: payment)
                payableReferenceTitleCache[allocation.payableId] = title
                payableReferenceTitles[allocation.payableId] = title
            } catch {
                unavailableReference = true
            }
        }

        if unavailableReference {
            detailReferenceWarning = payableReferenceWarning
        }
    }

    private func payableTitle(
        for payable: AdminPayable,
        payment: AdminSupplierPayment
    ) async -> String {
        if payable.sourceType.uppercased() == "SUPPLIER_DOCUMENT",
           PermissionSet(permissions).can(PermissionCatalog.supplierDocumentsView) {
            do {
                let document = try await repository.getSupplierDocument(id: payable.sourceId)
                if document.id == payable.sourceId,
                   document.supplierId == payment.supplierId {
                    return "Documento \(document.documentNumber)"
                }
            } catch {
                // Fall through to a protected business label.
            }
        }

        switch payable.sourceType.uppercased() {
        case "SUPPLIER_DOCUMENT": return "Documento de proveedor"
        case "OPENING_BALANCE": return "Saldo inicial"
        case "ADJUSTMENT": return "Ajuste operativo"
        default: return "Cuenta por pagar"
        }
    }

    private func appendUnique(_ page: [AdminSupplierPaymentPresentation]) {
        var known = Set(supplierPayments.map(\.id))
        for presentation in page where known.insert(presentation.id).inserted {
            supplierPayments.append(presentation)
        }
    }

    private func replaceInList(_ payment: AdminSupplierPayment) {
        let existingIndex = supplierPayments.firstIndex(where: { $0.id == payment.id })
        guard matchesCurrentFilters(payment) else {
            if let existingIndex {
                supplierPayments.remove(at: existingIndex)
            }
            return
        }

        let supplierName: String?
        if let cached = supplierNameCache[payment.supplierId] {
            supplierName = cached
        } else if let existingIndex {
            supplierName = supplierPayments[existingIndex].supplierName
        } else {
            supplierName = nil
        }
        let presentation = AdminSupplierPaymentPresentation(
            payment: payment,
            supplierName: supplierName
        )
        if let existingIndex {
            supplierPayments[existingIndex] = presentation
        } else {
            supplierPayments.insert(presentation, at: 0)
        }
    }

    private func matchesCurrentFilters(_ payment: AdminSupplierPayment) -> Bool {
        guard let activeQuery else { return true }
        if let branchId = activeQuery.branchId, payment.branchId != branchId { return false }
        if let supplierId = activeQuery.supplierId, payment.supplierId != supplierId { return false }
        if !activeQuery.status.apiValues.isEmpty,
           !activeQuery.status.apiValues.contains(payment.status) { return false }
        if let from = activeQuery.paymentFrom, payment.paymentDate < from { return false }
        if let to = activeQuery.paymentTo, payment.paymentDate > to { return false }
        if let method = activeQuery.method.apiValue, payment.method?.rawValue != method { return false }
        if let query = activeQuery.query?.trimmedOrNil,
           payment.paymentNumber.localizedCaseInsensitiveContains(query) == false { return false }
        return true
    }

    private func voidIdempotencyKey(
        for paymentId: String,
        expectedVersion: Int64,
        normalizedReason: String
    ) -> String {
        let intent = "\(expectedVersion)|\(normalizedReason)"
        if let cached = voidIdempotencyKeys[paymentId], cached.intent == intent {
            return cached.key
        }
        let key = UUID().uuidString.lowercased()
        voidIdempotencyKeys[paymentId] = VoidIntentKey(intent: intent, key: key)
        return key
    }

    private func voidSuccessMessage(
        status: AdminSupplierPaymentStatus,
        replayed: Bool
    ) -> String {
        if replayed {
            return "La operación se recuperó de un intento anterior. Revisa el estado canónico entregado por el servidor."
        }
        switch status {
        case .voiding:
            return "La anulación está en proceso. Actualiza el detalle antes de asumir que las aplicaciones fueron restauradas."
        case .voided:
            return "Pago anulado. El servidor conservó el historial y restauró sus aplicaciones."
        case .processing, .recorded:
            return "El servidor recibió la solicitud. Actualiza el detalle antes de asumir el resultado final."
        }
    }

    private func validatedFilterValues() -> FilterValues? {
        let values = FilterValues(
            branchId: branchId.trimmedOrNil,
            supplierId: supplierId.trimmedOrNil,
            paymentFrom: paymentFrom.trimmedOrNil,
            paymentTo: paymentTo.trimmedOrNil,
            method: canViewSensitive ? methodFilter : .all,
            query: query.trimmedOrNil
        )

        if let paymentFrom = values.paymentFrom, !Self.isValidDate(paymentFrom) {
            errorMessage = "La fecha inicial debe usar AAAA-MM-DD."
            return nil
        }
        if let paymentTo = values.paymentTo, !Self.isValidDate(paymentTo) {
            errorMessage = "La fecha final debe usar AAAA-MM-DD."
            return nil
        }
        if let paymentFrom = values.paymentFrom,
           let paymentTo = values.paymentTo,
           paymentFrom > paymentTo {
            errorMessage = "La fecha inicial no puede ser posterior a la final."
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

    private var supplierReferenceWarning: String {
        "Algunos nombres de proveedor están protegidos o no disponibles. El pago y sus importes siguen siendo la respuesta autoritativa del servidor."
    }

    private var payableReferenceWarning: String {
        "Alguna cuenta por pagar o documento de origen está protegido o no disponible. Las aplicaciones e importes canónicos siguen visibles."
    }

    private struct VoidIntentKey {
        let intent: String
        let key: String
    }

    private struct FilterValues {
        let branchId: String?
        let supplierId: String?
        let paymentFrom: String?
        let paymentTo: String?
        let method: AdminSupplierPaymentMethodFilter
        let query: String?
    }
}
