//
//  AdminProcurementAPI.swift
//  Nexo Admin
//
//  27R.N.1B–N.4 — Admin-only procurement, supplier, order and receipt-read endpoints.
//

import Foundation

enum AdminProcurementRoutes {
    static let reportCatalog = "/api/v1/admin/procurement/reports"
    static let financeFacts = "/api/v1/admin/procurement/finance-facts"
    static let suppliers = "/api/v1/admin/procurement/suppliers"
    static let purchaseOrders = "/api/v1/admin/procurement/purchase-orders"
    static let purchaseReceipts = "/api/v1/admin/procurement/purchase-receipts"

    static func report(_ reportType: String) -> String {
        "/api/v1/admin/procurement/reports/\(encodedPathComponent(reportType))"
    }

    static func supplier(_ supplierId: String) -> String {
        "\(suppliers)/\(encodedPathComponent(supplierId))"
    }

    static func supplierStatus(_ supplierId: String) -> String {
        "\(supplier(supplierId))/status"
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
    func getOpenOverduePayables(currency: String, branchId: String?) async throws -> AdminProcurementOperationalHealthDTO
    func getFinanceFacts(currency: String, branchId: String?) async throws -> AdminProcurementFinanceHealthDTO
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
}

struct RemoteAdminProcurementAPI: AdminProcurementAPI {
    let apiClient: APIClient

    func getReportCatalog() async throws -> AdminProcurementReportCatalogDTO {
        try await apiClient.send(endpoint(path: AdminProcurementRoutes.reportCatalog, method: .get))
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

    private func append(_ items: inout [URLQueryItem], name: String, value: String?) {
        guard let value = value?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty else {
            return
        }
        items.append(URLQueryItem(name: name, value: value))
    }
}
