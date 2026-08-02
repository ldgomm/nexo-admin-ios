//
//  AdminProcurementRepository.swift
//  Nexo Admin
//
//  Created by José Ruiz on 29/7/26.
//
//  27R.N — Procurement readiness, review, supplier statements and canonical exports.
//

import Foundation

protocol AdminProcurementRepository: Sendable {
    func getReadinessSnapshot(currency: String, branchId: String?) async throws -> AdminProcurementContractSnapshot
    func getProcurementReportCatalog() async throws -> AdminProcurementReportCatalog
    func getSupplierStatement(query: AdminSupplierStatementQuery) async throws -> AdminSupplierStatement
    func downloadSupplierStatementCSV(
        query: AdminSupplierStatementQuery
    ) async throws -> AdminProcurementDownloadedFile
    func downloadOperationalReportCSV(
        query: AdminProcurementOperationalExportQuery
    ) async throws -> AdminProcurementDownloadedFile
    func listSuppliers(query: AdminSupplierListQuery) async throws -> AdminSupplierPage
    func getSupplier(id: String) async throws -> AdminSupplier
    func createSupplier(_ input: AdminSupplierWriteInput) async throws -> AdminSupplierMutationResult
    func updateSupplier(id: String, input: AdminSupplierWriteInput) async throws -> AdminSupplierMutationResult
    func changeSupplierStatus(id: String, input: AdminSupplierStatusInput) async throws -> AdminSupplierMutationResult
    func listPurchaseOrders(query: AdminPurchaseOrderListQuery) async throws -> AdminPurchaseOrderPage
    func getPurchaseOrder(id: String) async throws -> AdminPurchaseOrder
    func listPurchaseReceipts(query: AdminPurchaseReceiptListQuery) async throws -> AdminPurchaseReceiptPage
    func getPurchaseReceipt(id: String) async throws -> AdminPurchaseReceipt
    func getPurchaseReceiptInventoryEffects(id: String) async throws -> AdminPurchaseReceiptInventoryEffects
    func listSupplierDocuments(query: AdminSupplierDocumentListQuery) async throws -> AdminSupplierDocumentPage
    func getSupplierDocument(id: String) async throws -> AdminSupplierDocument
    func listPayables(query: AdminPayableListQuery) async throws -> AdminPayablePage
    func getPayable(id: String, asOf: String?) async throws -> AdminPayable
    func getPayableAging(query: AdminPayableAgingQuery) async throws -> AdminPayableAging
    func listSupplierPayments(query: AdminSupplierPaymentListQuery) async throws -> AdminSupplierPaymentPage
    func getSupplierPayment(id: String) async throws -> AdminSupplierPayment
    func voidSupplierPayment(
        id: String,
        input: AdminSupplierPaymentVoidInput
    ) async throws -> AdminSupplierPaymentMutationResult
}

struct RemoteAdminProcurementRepository: AdminProcurementRepository {
    let api: any AdminProcurementAPI
    let downloadDirectory: URL

    init(
        api: any AdminProcurementAPI,
        downloadDirectory: URL = FileManager.default.temporaryDirectory
            .appendingPathComponent("nexo-admin-procurement-exports", isDirectory: true)
    ) {
        self.api = api
        self.downloadDirectory = downloadDirectory
    }

    func getReadinessSnapshot(
        currency: String,
        branchId: String?
    ) async throws -> AdminProcurementContractSnapshot {
        async let catalogTask = api.getReportCatalog()
        async let payableTask = api.getOpenOverduePayables(currency: currency, branchId: branchId)
        async let financeTask = api.getFinanceFacts(currency: currency, branchId: branchId)
        async let replayReadinessTask = api.getFinanceSourceFactReplayReadiness(
            currency: currency,
            branchId: branchId
        )
        async let accountingCompletenessTask = api.getAccountingCompletenessMatrix(
            currency: currency
        )

        let catalog = try await catalogTask
        let payable = try await payableTask
        let finance = try await financeTask
        let replayReadiness = try await replayReadinessTask
        let accountingCompleteness = try await accountingCompletenessTask

        return AdminProcurementContractSnapshot(
            catalog: catalog.toDomain(),
            payableHealth: try payable.toDomain(),
            financeHealth: finance.toDomain(),
            financeSourceFactReplayReadiness: replayReadiness.toDomain(),
            accountingCompletenessMatrix: try accountingCompleteness.toDomain()
        )
    }

    func getProcurementReportCatalog() async throws -> AdminProcurementReportCatalog {
        try await api.getReportCatalog().toDomain()
    }

    func getSupplierStatement(query: AdminSupplierStatementQuery) async throws -> AdminSupplierStatement {
        try await api.getSupplierStatement(query.toDTO()).toDomain()
    }

    func downloadSupplierStatementCSV(
        query: AdminSupplierStatementQuery
    ) async throws -> AdminProcurementDownloadedFile {
        let response = try await api.downloadSupplierStatementCSV(query.toDTO())
        return try storeCSV(
            response,
            expectedType: "supplier_statement",
            expectedVersion: "27R.J.v1",
            fallbackFileName: "nexo_supplier_statement_\(query.supplierId).csv"
        )
    }

    func downloadOperationalReportCSV(
        query: AdminProcurementOperationalExportQuery
    ) async throws -> AdminProcurementDownloadedFile {
        let response = try await api.downloadOperationalReportCSV(query.toDTO())
        return try storeCSV(
            response,
            expectedType: query.reportType,
            expectedVersion: "27R.L.v1",
            fallbackFileName: "nexo_\(query.reportType).csv"
        )
    }

    func listSuppliers(query: AdminSupplierListQuery) async throws -> AdminSupplierPage {
        try await api.listSuppliers(query.toDTO()).toDomain()
    }

    func getSupplier(id: String) async throws -> AdminSupplier {
        try await api.getSupplier(id: id).toDomain().supplier
    }

    func createSupplier(_ input: AdminSupplierWriteInput) async throws -> AdminSupplierMutationResult {
        try await api.createSupplier(
            input.toDTO(),
            idempotencyKey: input.idempotencyKey
        ).toDomain()
    }

    func updateSupplier(
        id: String,
        input: AdminSupplierWriteInput
    ) async throws -> AdminSupplierMutationResult {
        try await api.updateSupplier(id: id, request: input.toDTO()).toDomain()
    }

    func changeSupplierStatus(
        id: String,
        input: AdminSupplierStatusInput
    ) async throws -> AdminSupplierMutationResult {
        try await api.changeSupplierStatus(
            id: id,
            request: input.toDTO(),
            idempotencyKey: input.idempotencyKey
        ).toDomain()
    }

    func listPurchaseOrders(query: AdminPurchaseOrderListQuery) async throws -> AdminPurchaseOrderPage {
        try await api.listPurchaseOrders(query.toDTO()).toDomain()
    }

    func getPurchaseOrder(id: String) async throws -> AdminPurchaseOrder {
        try await api.getPurchaseOrder(id: id).toDomain().purchaseOrder
    }

    func listPurchaseReceipts(query: AdminPurchaseReceiptListQuery) async throws -> AdminPurchaseReceiptPage {
        try await api.listPurchaseReceipts(query.toDTO()).toDomain()
    }

    func getPurchaseReceipt(id: String) async throws -> AdminPurchaseReceipt {
        try await api.getPurchaseReceipt(id: id).toDomain().receipt
    }

    func getPurchaseReceiptInventoryEffects(
        id: String
    ) async throws -> AdminPurchaseReceiptInventoryEffects {
        try await api.getPurchaseReceiptInventoryEffects(id: id).toDomain()
    }

    func listSupplierDocuments(query: AdminSupplierDocumentListQuery) async throws -> AdminSupplierDocumentPage {
        try await api.listSupplierDocuments(query.toDTO()).toDomain()
    }

    func getSupplierDocument(id: String) async throws -> AdminSupplierDocument {
        try await api.getSupplierDocument(id: id).toDomain().supplierDocument
    }

    func listPayables(query: AdminPayableListQuery) async throws -> AdminPayablePage {
        try await api.listPayables(query.toDTO()).toDomain()
    }

    func getPayable(id: String, asOf: String?) async throws -> AdminPayable {
        try await api.getPayable(id: id, asOf: asOf?.trimmedOrNil).toDomain().payable
    }

    func getPayableAging(query: AdminPayableAgingQuery) async throws -> AdminPayableAging {
        try await api.getPayableAging(query.toDTO()).toDomain()
    }


    func listSupplierPayments(query: AdminSupplierPaymentListQuery) async throws -> AdminSupplierPaymentPage {
        try await api.listSupplierPayments(query.toDTO()).toDomain()
    }

    func getSupplierPayment(id: String) async throws -> AdminSupplierPayment {
        try await api.getSupplierPayment(id: id).toDomain().supplierPayment
    }

    func voidSupplierPayment(
        id: String,
        input: AdminSupplierPaymentVoidInput
    ) async throws -> AdminSupplierPaymentMutationResult {
        try await api.voidSupplierPayment(
            id: id,
            request: input.toDTO(),
            idempotencyKey: input.idempotencyKey
        ).toMutationDomain()
    }

    private func storeCSV(
        _ response: APIDataResponse,
        expectedType: String,
        expectedVersion: String,
        fallbackFileName: String
    ) throws -> AdminProcurementDownloadedFile {
        guard !response.data.isEmpty else {
            throw AppError.decoding("El servidor devolvió un CSV vacío.")
        }
        let contentType = response.headerValue("Content-Type") ?? ""
        guard contentType.lowercased().contains("text/csv") else {
            throw AppError.decoding("El servidor no devolvió contenido CSV.")
        }
        guard response.headerValue("X-Nexo-Export-Type") == expectedType else {
            throw AppError.decoding("El tipo de exportación no coincide con la solicitud.")
        }
        guard response.headerValue("X-Nexo-Export-Version") == expectedVersion else {
            throw AppError.decoding("La versión de exportación no coincide con el contrato aceptado.")
        }
        guard let rowCountValue = response.headerValue("X-Nexo-Export-Row-Count"),
              let rowCount = Int(rowCountValue),
              rowCount >= 0 else {
            throw AppError.decoding("El servidor no informó un conteo de filas válido.")
        }

        let headerFileName = Self.fileName(
            fromContentDisposition: response.headerValue("Content-Disposition")
        )
        let fileName = Self.safeFileName(headerFileName ?? fallbackFileName)
        try FileManager.default.createDirectory(
            at: downloadDirectory,
            withIntermediateDirectories: true
        )
        let localURL = downloadDirectory.appendingPathComponent(
            "\(UUID().uuidString)-\(fileName)"
        )
        try response.data.write(to: localURL, options: .atomic)

        return AdminProcurementDownloadedFile(
            localURL: localURL,
            fileName: fileName,
            contentType: contentType,
            sizeBytes: response.data.count,
            exportType: expectedType,
            exportVersion: expectedVersion,
            rowCount: rowCount
        )
    }

    private static func fileName(fromContentDisposition value: String?) -> String? {
        guard let value else { return nil }
        for part in value.split(separator: ";").map({
            $0.trimmingCharacters(in: .whitespacesAndNewlines)
        }) {
            let lower = part.lowercased()
            if lower.hasPrefix("filename*=utf-8''") {
                let encoded = String(part.dropFirst("filename*=utf-8''".count))
                return encoded.removingPercentEncoding ?? encoded
            }
            if lower.hasPrefix("filename=") {
                return String(part.dropFirst("filename=".count))
                    .trimmingCharacters(in: CharacterSet(charactersIn: "\""))
            }
        }
        return nil
    }

    private static func safeFileName(_ value: String) -> String {
        let component = value.replacingOccurrences(of: "\\", with: "/")
            .split(separator: "/").last.map(String.init) ?? value
        let safe = component.replacingOccurrences(
            of: "[^A-Za-z0-9_.-]",
            with: "_",
            options: .regularExpression
        )
        let csvName = safe.lowercased().hasSuffix(".csv") ? safe : "\(safe).csv"
        return csvName.isEmpty || csvName == ".csv" ? "nexo_procurement_export.csv" : csvName
    }
}
