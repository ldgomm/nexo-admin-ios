//
//  AdminProcurementAPI.swift
//  Nexo Admin
//
//  Created by José Ruiz on 29/7/26.
//
//  27R.N — Admin procurement read/control, supplier statement and canonical CSV exports.
//

import Foundation

enum AdminProcurementRoutes {
    static let reportCatalog = "/api/v1/admin/procurement/reports"
    static let financeFacts = "/api/v1/admin/procurement/finance-facts"
    static let financeFactsV1ReplayReadiness = "/api/v1/admin/procurement/finance-facts/v1/readiness"
    static let accountingCompleteness = "/api/v1/admin/procurement/accounting-completeness"
    static let suppliers = "/api/v1/admin/procurement/suppliers"
    static let purchaseOrders = "/api/v1/admin/procurement/purchase-orders"
    static let purchaseReceipts = "/api/v1/admin/procurement/purchase-receipts"
    static let supplierDocuments = "/api/v1/admin/procurement/supplier-documents"
    static let payables = "/api/v1/admin/procurement/payables"
    static let payableAging = "\(payables)/aging"
    static let supplierPayments = "/api/v1/admin/procurement/supplier-payments"

    static func report(_ reportType: String) -> String {
        "/api/v1/admin/procurement/reports/\(encodedPathComponent(reportType))"
    }

    static func reportCSV(_ reportType: String) -> String {
        "\(report(reportType))/export.csv"
    }

    static func supplier(_ supplierId: String) -> String {
        "\(suppliers)/\(encodedPathComponent(supplierId))"
    }

    static func supplierStatus(_ supplierId: String) -> String {
        "\(supplier(supplierId))/status"
    }

    static func supplierStatement(_ supplierId: String) -> String {
        "\(supplier(supplierId))/statement"
    }

    static func supplierStatementCSV(_ supplierId: String) -> String {
        "\(supplier(supplierId))/statement.csv"
    }

    static func purchaseOrder(_ orderId: String) -> String {
        "\(purchaseOrders)/\(encodedPathComponent(orderId))"
    }

    static func purchaseReceipt(_ receiptId: String) -> String {
        "\(purchaseReceipts)/\(encodedPathComponent(receiptId))"
    }

    static func purchaseReceiptInventoryEffects(_ receiptId: String) -> String {
        "\(purchaseReceipt(receiptId))/inventory-effects"
    }

    static func supplierDocument(_ documentId: String) -> String {
        "\(supplierDocuments)/\(encodedPathComponent(documentId))"
    }

    static func payable(_ payableId: String) -> String {
        "\(payables)/\(encodedPathComponent(payableId))"
    }

    static func supplierPayment(_ paymentId: String) -> String {
        "\(supplierPayments)/\(encodedPathComponent(paymentId))"
    }

    static func voidSupplierPayment(_ paymentId: String) -> String {
        "\(supplierPayment(paymentId))/void"
    }

    private static func encodedPathComponent(_ value: String) -> String {
        value.addingPercentEncoding(withAllowedCharacters: pathComponentAllowed) ?? value
    }

    private static let pathComponentAllowed: CharacterSet = {
        var allowed = CharacterSet.urlPathAllowed
        allowed.remove(charactersIn: "/?#")
        return allowed
    }()
}

protocol AdminProcurementAPI: Sendable {
    func getReportCatalog() async throws -> AdminProcurementReportCatalogDTO
    func getSupplierStatement(
        _ request: AdminSupplierStatementRequestDTO
    ) async throws -> AdminSupplierStatementResponseDTO
    func downloadSupplierStatementCSV(
        _ request: AdminSupplierStatementRequestDTO
    ) async throws -> APIDataResponse
    func downloadOperationalReportCSV(
        _ request: AdminProcurementOperationalExportRequestDTO
    ) async throws -> APIDataResponse
    func getOpenOverduePayables(currency: String, branchId: String?) async throws -> AdminProcurementOperationalHealthDTO
    func getFinanceFacts(currency: String, branchId: String?) async throws -> AdminProcurementFinanceHealthDTO
    func getFinanceSourceFactReplayReadiness(
        currency: String,
        branchId: String?
    ) async throws -> AdminProcurementFinanceSourceFactReplayReadinessDTO
    func getAccountingCompletenessMatrix(
        currency: String
    ) async throws -> AdminProcurementAccountingCompletenessMatrixDTO
    func listSuppliers(_ request: AdminSupplierListRequestDTO) async throws -> AdminSupplierListResponseDTO
    func getSupplier(id: String) async throws -> AdminSupplierEnvelopeDTO
    func createSupplier(
        _ request: AdminSupplierWriteRequestDTO,
        idempotencyKey: String
    ) async throws -> AdminSupplierEnvelopeDTO
    func updateSupplier(id: String, request: AdminSupplierWriteRequestDTO) async throws -> AdminSupplierEnvelopeDTO
    func changeSupplierStatus(
        id: String,
        request: AdminSupplierStatusRequestDTO,
        idempotencyKey: String
    ) async throws -> AdminSupplierEnvelopeDTO
    func listPurchaseOrders(_ request: AdminPurchaseOrderListRequestDTO) async throws -> AdminPurchaseOrderListResponseDTO
    func getPurchaseOrder(id: String) async throws -> AdminPurchaseOrderEnvelopeDTO
    func listPurchaseReceipts(
        _ request: AdminPurchaseReceiptListRequestDTO
    ) async throws -> AdminPurchaseReceiptListResponseDTO
    func getPurchaseReceipt(id: String) async throws -> AdminPurchaseReceiptEnvelopeDTO
    func getPurchaseReceiptInventoryEffects(
        id: String
    ) async throws -> AdminPurchaseReceiptInventoryEffectsEnvelopeDTO
    func listSupplierDocuments(
        _ request: AdminSupplierDocumentListRequestDTO
    ) async throws -> AdminSupplierDocumentListResponseDTO
    func getSupplierDocument(id: String) async throws -> AdminSupplierDocumentEnvelopeDTO
    func listPayables(_ request: AdminPayableListRequestDTO) async throws -> AdminPayableListResponseDTO
    func getPayable(id: String, asOf: String?) async throws -> AdminPayableEnvelopeDTO
    func getPayableAging(_ request: AdminPayableAgingRequestDTO) async throws -> AdminPayableAgingResponseDTO
    func listSupplierPayments(
        _ request: AdminSupplierPaymentListRequestDTO
    ) async throws -> AdminSupplierPaymentListResponseDTO
    func getSupplierPayment(id: String) async throws -> AdminSupplierPaymentEnvelopeDTO
    func voidSupplierPayment(
        id: String,
        request: AdminSupplierPaymentVoidRequestDTO,
        idempotencyKey: String
    ) async throws -> AdminSupplierPaymentEnvelopeDTO
}

struct RemoteAdminProcurementAPI: AdminProcurementAPI {
    let apiClient: APIClient

    func getReportCatalog() async throws -> AdminProcurementReportCatalogDTO {
        try await apiClient.send(endpoint(path: AdminProcurementRoutes.reportCatalog, method: .get))
    }

    func getSupplierStatement(
        _ request: AdminSupplierStatementRequestDTO
    ) async throws -> AdminSupplierStatementResponseDTO {
        try await apiClient.send(
            endpoint(
                path: AdminProcurementRoutes.supplierStatement(request.supplierId),
                method: .get,
                queryItems: supplierStatementQueryItems(request, includePagination: true)
            )
        )
    }

    func downloadSupplierStatementCSV(
        _ request: AdminSupplierStatementRequestDTO
    ) async throws -> APIDataResponse {
        guard let dataClient = apiClient as? any APIDataClient else {
            throw AppError.transport("El cliente HTTP no soporta descarga de archivos.")
        }
        return try await dataClient.sendData(
            endpoint(
                path: AdminProcurementRoutes.supplierStatementCSV(request.supplierId),
                method: .get,
                queryItems: supplierStatementQueryItems(request, includePagination: false)
            )
        )
    }

    func downloadOperationalReportCSV(
        _ request: AdminProcurementOperationalExportRequestDTO
    ) async throws -> APIDataResponse {
        guard let dataClient = apiClient as? any APIDataClient else {
            throw AppError.transport("El cliente HTTP no soporta descarga de archivos.")
        }
        return try await dataClient.sendData(
            endpoint(
                path: AdminProcurementRoutes.reportCSV(request.reportType),
                method: .get,
                queryItems: operationalExportQueryItems(request)
            )
        )
    }

    func getOpenOverduePayables(
        currency: String,
        branchId: String?
    ) async throws -> AdminProcurementOperationalHealthDTO {
        try await apiClient.send(
            endpoint(
                path: AdminProcurementRoutes.report("open_overdue_payables"),
                method: .get,
                queryItems: healthQueryItems(currency: currency, branchId: branchId)
            )
        )
    }

    func getFinanceFacts(
        currency: String,
        branchId: String?
    ) async throws -> AdminProcurementFinanceHealthDTO {
        try await apiClient.send(
            endpoint(
                path: AdminProcurementRoutes.financeFacts,
                method: .get,
                queryItems: healthQueryItems(currency: currency, branchId: branchId)
            )
        )
    }

    func getFinanceSourceFactReplayReadiness(
        currency: String,
        branchId: String?
    ) async throws -> AdminProcurementFinanceSourceFactReplayReadinessDTO {
        try await apiClient.send(
            endpoint(
                path: AdminProcurementRoutes.financeFactsV1ReplayReadiness,
                method: .get,
                queryItems: replayReadinessQueryItems(currency: currency, branchId: branchId)
            )
        )
    }

    func getAccountingCompletenessMatrix(
        currency: String
    ) async throws -> AdminProcurementAccountingCompletenessMatrixDTO {
        try await apiClient.send(
            endpoint(
                path: AdminProcurementRoutes.accountingCompleteness,
                method: .get,
                queryItems: [URLQueryItem(name: "currency", value: currency)]
            )
        )
    }

    func listSuppliers(_ request: AdminSupplierListRequestDTO) async throws -> AdminSupplierListResponseDTO {
        try await apiClient.send(
            endpoint(
                path: AdminProcurementRoutes.suppliers,
                method: .get,
                queryItems: supplierQueryItems(request)
            )
        )
    }

    func getSupplier(id: String) async throws -> AdminSupplierEnvelopeDTO {
        try await apiClient.send(endpoint(path: AdminProcurementRoutes.supplier(id), method: .get))
    }

    func createSupplier(
        _ request: AdminSupplierWriteRequestDTO,
        idempotencyKey: String
    ) async throws -> AdminSupplierEnvelopeDTO {
        try await apiClient.send(
            endpoint(path: AdminProcurementRoutes.suppliers, method: .post)
                .withIdempotencyKey(idempotencyKey),
            body: request
        )
    }

    func updateSupplier(
        id: String,
        request: AdminSupplierWriteRequestDTO
    ) async throws -> AdminSupplierEnvelopeDTO {
        try await apiClient.send(
            endpoint(path: AdminProcurementRoutes.supplier(id), method: .put),
            body: request
        )
    }

    func changeSupplierStatus(
        id: String,
        request: AdminSupplierStatusRequestDTO,
        idempotencyKey: String
    ) async throws -> AdminSupplierEnvelopeDTO {
        try await apiClient.send(
            endpoint(path: AdminProcurementRoutes.supplierStatus(id), method: .post)
                .withIdempotencyKey(idempotencyKey),
            body: request
        )
    }

    func listPurchaseOrders(
        _ request: AdminPurchaseOrderListRequestDTO
    ) async throws -> AdminPurchaseOrderListResponseDTO {
        try await apiClient.send(
            endpoint(
                path: AdminProcurementRoutes.purchaseOrders,
                method: .get,
                queryItems: purchaseOrderQueryItems(request)
            )
        )
    }

    func getPurchaseOrder(id: String) async throws -> AdminPurchaseOrderEnvelopeDTO {
        try await apiClient.send(endpoint(path: AdminProcurementRoutes.purchaseOrder(id), method: .get))
    }

    func listPurchaseReceipts(
        _ request: AdminPurchaseReceiptListRequestDTO
    ) async throws -> AdminPurchaseReceiptListResponseDTO {
        try await apiClient.send(
            endpoint(
                path: AdminProcurementRoutes.purchaseReceipts,
                method: .get,
                queryItems: purchaseReceiptQueryItems(request)
            )
        )
    }

    func getPurchaseReceipt(id: String) async throws -> AdminPurchaseReceiptEnvelopeDTO {
        try await apiClient.send(endpoint(path: AdminProcurementRoutes.purchaseReceipt(id), method: .get))
    }

    func getPurchaseReceiptInventoryEffects(
        id: String
    ) async throws -> AdminPurchaseReceiptInventoryEffectsEnvelopeDTO {
        try await apiClient.send(
            endpoint(
                path: AdminProcurementRoutes.purchaseReceiptInventoryEffects(id),
                method: .get
            )
        )
    }

    func listSupplierDocuments(
        _ request: AdminSupplierDocumentListRequestDTO
    ) async throws -> AdminSupplierDocumentListResponseDTO {
        try await apiClient.send(
            endpoint(
                path: AdminProcurementRoutes.supplierDocuments,
                method: .get,
                queryItems: supplierDocumentQueryItems(request)
            )
        )
    }

    func getSupplierDocument(id: String) async throws -> AdminSupplierDocumentEnvelopeDTO {
        try await apiClient.send(endpoint(path: AdminProcurementRoutes.supplierDocument(id), method: .get))
    }

    func listPayables(_ request: AdminPayableListRequestDTO) async throws -> AdminPayableListResponseDTO {
        try await apiClient.send(
            endpoint(
                path: AdminProcurementRoutes.payables,
                method: .get,
                queryItems: payableQueryItems(request)
            )
        )
    }

    func getPayable(id: String, asOf: String?) async throws -> AdminPayableEnvelopeDTO {
        var items: [URLQueryItem] = []
        append(&items, name: "asOf", value: asOf)
        return try await apiClient.send(
            endpoint(
                path: AdminProcurementRoutes.payable(id),
                method: .get,
                queryItems: items
            )
        )
    }

    func getPayableAging(_ request: AdminPayableAgingRequestDTO) async throws -> AdminPayableAgingResponseDTO {
        try await apiClient.send(
            endpoint(
                path: AdminProcurementRoutes.payableAging,
                method: .get,
                queryItems: payableAgingQueryItems(request)
            )
        )
    }

    func listSupplierPayments(
        _ request: AdminSupplierPaymentListRequestDTO
    ) async throws -> AdminSupplierPaymentListResponseDTO {
        try await apiClient.send(
            endpoint(
                path: AdminProcurementRoutes.supplierPayments,
                method: .get,
                queryItems: supplierPaymentQueryItems(request)
            )
        )
    }

    func getSupplierPayment(id: String) async throws -> AdminSupplierPaymentEnvelopeDTO {
        try await apiClient.send(
            endpoint(path: AdminProcurementRoutes.supplierPayment(id), method: .get)
        )
    }

    func voidSupplierPayment(
        id: String,
        request: AdminSupplierPaymentVoidRequestDTO,
        idempotencyKey: String
    ) async throws -> AdminSupplierPaymentEnvelopeDTO {
        try await apiClient.send(
            endpoint(path: AdminProcurementRoutes.voidSupplierPayment(id), method: .post)
                .withIdempotencyKey(idempotencyKey),
            body: request
        )
    }

    private func endpoint(
        path: String,
        method: HTTPMethod,
        queryItems: [URLQueryItem] = []
    ) -> APIEndpoint {
        APIEndpoint(
            path: path,
            method: method,
            queryItems: queryItems,
            requiresAuth: true,
            requiresOrganization: true
        )
    }

    private func healthQueryItems(currency: String, branchId: String?) -> [URLQueryItem] {
        var items = [
            URLQueryItem(name: "currency", value: currency),
            URLQueryItem(name: "limit", value: "1")
        ]
        if let branchId = branchId?.trimmingCharacters(in: .whitespacesAndNewlines), !branchId.isEmpty {
            items.append(URLQueryItem(name: "branchId", value: branchId))
        }
        return items
    }

    private func replayReadinessQueryItems(currency: String, branchId: String?) -> [URLQueryItem] {
        var items = [URLQueryItem(name: "currency", value: currency)]
        if let branchId = branchId?.trimmingCharacters(in: .whitespacesAndNewlines), !branchId.isEmpty {
            items.append(URLQueryItem(name: "branchId", value: branchId))
        }
        return items
    }

    private func supplierQueryItems(_ request: AdminSupplierListRequestDTO) -> [URLQueryItem] {
        var items = [URLQueryItem(name: "limit", value: String(request.limit))]
        append(&items, name: "query", value: request.query)
        append(&items, name: "status", value: request.status)
        append(&items, name: "category", value: request.category)
        append(&items, name: "cursor", value: request.cursor)
        return items
    }

    private func purchaseOrderQueryItems(_ request: AdminPurchaseOrderListRequestDTO) -> [URLQueryItem] {
        var items = [URLQueryItem(name: "limit", value: String(request.limit))]
        append(&items, name: "branchId", value: request.branchId)
        append(&items, name: "supplierId", value: request.supplierId)
        append(&items, name: "status", value: request.status)
        append(&items, name: "expectedFrom", value: request.expectedFrom)
        append(&items, name: "expectedTo", value: request.expectedTo)
        append(&items, name: "query", value: request.query)
        append(&items, name: "cursor", value: request.cursor)
        return items
    }

    private func purchaseReceiptQueryItems(_ request: AdminPurchaseReceiptListRequestDTO) -> [URLQueryItem] {
        var items = [URLQueryItem(name: "limit", value: String(request.limit))]
        append(&items, name: "branchId", value: request.branchId)
        append(&items, name: "supplierId", value: request.supplierId)
        append(&items, name: "purchaseOrderId", value: request.purchaseOrderId)
        append(&items, name: "status", value: request.status)
        append(&items, name: "receivedFrom", value: request.receivedFrom)
        append(&items, name: "receivedTo", value: request.receivedTo)
        append(&items, name: "cursor", value: request.cursor)
        return items
    }

    private func supplierDocumentQueryItems(_ request: AdminSupplierDocumentListRequestDTO) -> [URLQueryItem] {
        var items = [URLQueryItem(name: "limit", value: String(request.limit))]
        append(&items, name: "branchId", value: request.branchId)
        append(&items, name: "supplierId", value: request.supplierId)
        append(&items, name: "documentType", value: request.documentType)
        append(&items, name: "status", value: request.status)
        append(&items, name: "documentDateFrom", value: request.documentDateFrom)
        append(&items, name: "documentDateTo", value: request.documentDateTo)
        append(&items, name: "dueDateFrom", value: request.dueDateFrom)
        append(&items, name: "dueDateTo", value: request.dueDateTo)
        append(&items, name: "query", value: request.query)
        append(&items, name: "cursor", value: request.cursor)
        return items
    }

    private func payableQueryItems(_ request: AdminPayableListRequestDTO) -> [URLQueryItem] {
        var items = [URLQueryItem(name: "limit", value: String(request.limit))]
        append(&items, name: "branchId", value: request.branchId)
        append(&items, name: "supplierId", value: request.supplierId)
        append(&items, name: "effectiveStatus", value: request.effectiveStatus)
        append(&items, name: "dueFrom", value: request.dueFrom)
        append(&items, name: "dueTo", value: request.dueTo)
        append(&items, name: "currency", value: request.currency)
        append(&items, name: "asOf", value: request.asOf)
        append(&items, name: "cursor", value: request.cursor)
        return items
    }

    private func payableAgingQueryItems(_ request: AdminPayableAgingRequestDTO) -> [URLQueryItem] {
        var items: [URLQueryItem] = []
        append(&items, name: "branchId", value: request.branchId)
        append(&items, name: "supplierId", value: request.supplierId)
        append(&items, name: "currency", value: request.currency)
        append(&items, name: "asOf", value: request.asOf)
        return items
    }

    private func supplierPaymentQueryItems(
        _ request: AdminSupplierPaymentListRequestDTO
    ) -> [URLQueryItem] {
        var items = [URLQueryItem(name: "limit", value: String(request.limit))]
        append(&items, name: "branchId", value: request.branchId)
        append(&items, name: "supplierId", value: request.supplierId)
        append(&items, name: "status", value: request.status)
        append(&items, name: "paymentFrom", value: request.paymentFrom)
        append(&items, name: "paymentTo", value: request.paymentTo)
        append(&items, name: "method", value: request.method)
        append(&items, name: "query", value: request.query)
        append(&items, name: "cursor", value: request.cursor)
        return items
    }

    private func supplierStatementQueryItems(
        _ request: AdminSupplierStatementRequestDTO,
        includePagination: Bool
    ) -> [URLQueryItem] {
        var items = [URLQueryItem(name: "currency", value: request.currency)]
        append(&items, name: "branchId", value: request.branchId)
        append(&items, name: "from", value: request.from)
        append(&items, name: "to", value: request.to)
        append(&items, name: "asOf", value: request.asOf)
        if includePagination {
            items.append(URLQueryItem(name: "limit", value: String(request.limit)))
            append(&items, name: "cursor", value: request.cursor)
        }
        return items
    }

    private func operationalExportQueryItems(
        _ request: AdminProcurementOperationalExportRequestDTO
    ) -> [URLQueryItem] {
        var items = [URLQueryItem(name: "currency", value: request.currency)]
        append(&items, name: "branchId", value: request.branchId)
        append(&items, name: "supplierId", value: request.supplierId)
        append(&items, name: "category", value: request.category)
        append(&items, name: "catalogItemId", value: request.catalogItemId)
        append(&items, name: "paymentMethod", value: request.paymentMethod)
        append(&items, name: "attachmentSourceType", value: request.attachmentSourceType)
        append(&items, name: "from", value: request.from)
        append(&items, name: "to", value: request.to)
        append(&items, name: "asOf", value: request.asOf)
        return items
    }

    private func append(_ items: inout [URLQueryItem], name: String, value: String?) {
        guard let value = value?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty else {
            return
        }
        items.append(URLQueryItem(name: name, value: value))
    }
}
