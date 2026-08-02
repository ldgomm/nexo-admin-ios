//
//  AdminProcurementTestRepository.swift
//  Nexo AdminTests
//
//  Created by José Ruiz on 29/7/26.
//
//  27R.N test support.
//

import Foundation
@testable import Nexo_Admin

class AdminProcurementTestRepository: AdminProcurementRepository, @unchecked Sendable {
    var result: Result<AdminProcurementContractSnapshot, Error>
    var reportCatalogResult: Result<AdminProcurementReportCatalog, Error>
    var supplierStatementResults: [Result<AdminSupplierStatement, Error>]
    var supplierStatementDownloadResult: Result<AdminProcurementDownloadedFile, Error>
    var operationalReportDownloadResult: Result<AdminProcurementDownloadedFile, Error>
    var supplierPageResults: [Result<AdminSupplierPage, Error>]
    var supplierDetailResult: Result<AdminSupplier, Error>
    var supplierCreateResult: Result<AdminSupplierMutationResult, Error>
    var supplierUpdateResult: Result<AdminSupplierMutationResult, Error>
    var supplierStatusResult: Result<AdminSupplierMutationResult, Error>
    var purchaseOrderPageResults: [Result<AdminPurchaseOrderPage, Error>]
    var purchaseOrderDetailResult: Result<AdminPurchaseOrder, Error>
    var purchaseReceiptPageResults: [Result<AdminPurchaseReceiptPage, Error>]
    var purchaseReceiptDetailResult: Result<AdminPurchaseReceipt, Error>
    var purchaseReceiptEffectResult: Result<AdminPurchaseReceiptInventoryEffects, Error>
    var supplierDocumentPageResults: [Result<AdminSupplierDocumentPage, Error>]
    var supplierDocumentDetailResult: Result<AdminSupplierDocument, Error>
    var payablePageResults: [Result<AdminPayablePage, Error>]
    var payableDetailResult: Result<AdminPayable, Error>
    var payableAgingResult: Result<AdminPayableAging, Error>
    var supplierPaymentPageResults: [Result<AdminSupplierPaymentPage, Error>]
    var supplierPaymentDetailResult: Result<AdminSupplierPayment, Error>
    var supplierPaymentVoidResults: [Result<AdminSupplierPaymentMutationResult, Error>]

    private(set) var requests: [(currency: String, branchId: String?)] = []
    private(set) var supplierStatementQueries: [AdminSupplierStatementQuery] = []
    private(set) var supplierStatementDownloadQueries: [AdminSupplierStatementQuery] = []
    private(set) var operationalReportDownloadQueries: [AdminProcurementOperationalExportQuery] = []
    private(set) var reportCatalogRequestCount = 0
    private(set) var supplierListQueries: [AdminSupplierListQuery] = []
    private(set) var supplierDetailIds: [String] = []
    private(set) var supplierCreateInputs: [AdminSupplierWriteInput] = []
    private(set) var supplierUpdateRequests: [(id: String, input: AdminSupplierWriteInput)] = []
    private(set) var supplierStatusRequests: [(id: String, input: AdminSupplierStatusInput)] = []
    private(set) var purchaseOrderListQueries: [AdminPurchaseOrderListQuery] = []
    private(set) var purchaseOrderDetailIds: [String] = []
    private(set) var purchaseReceiptListQueries: [AdminPurchaseReceiptListQuery] = []
    private(set) var purchaseReceiptDetailIds: [String] = []
    private(set) var purchaseReceiptEffectIds: [String] = []
    private(set) var supplierDocumentListQueries: [AdminSupplierDocumentListQuery] = []
    private(set) var supplierDocumentDetailIds: [String] = []
    private(set) var payableListQueries: [AdminPayableListQuery] = []
    private(set) var payableDetailRequests: [(id: String, asOf: String?)] = []
    private(set) var payableAgingQueries: [AdminPayableAgingQuery] = []
    private(set) var supplierPaymentListQueries: [AdminSupplierPaymentListQuery] = []
    private(set) var supplierPaymentDetailIds: [String] = []
    private(set) var supplierPaymentVoidRequests: [(id: String, input: AdminSupplierPaymentVoidInput)] = []

    init(result: Result<AdminProcurementContractSnapshot, Error> = .success(.fixture())) {
        let supplier = AdminSupplier.fixture()
        let snapshot = AdminProcurementContractSnapshot.fixture()
        self.result = result
        self.reportCatalogResult = .success(snapshot.catalog)
        self.supplierStatementResults = [.success(.fixture())]
        self.supplierStatementDownloadResult = .success(.fixture(
            exportType: "supplier_statement",
            exportVersion: "27R.J.v1",
            fileName: "nexo_supplier_statement_sup_1.csv"
        ))
        self.operationalReportDownloadResult = .success(.fixture(
            exportType: "purchases_by_supplier",
            exportVersion: "27R.L.v1",
            fileName: "nexo_purchases_by_supplier.csv"
        ))
        self.supplierPageResults = [.success(AdminSupplierPage(suppliers: [supplier], nextCursor: nil, hasMore: false))]
        self.supplierDetailResult = .success(supplier)
        self.supplierCreateResult = .success(AdminSupplierMutationResult(
            supplier: supplier,
            requestId: "req_create",
            idempotencyReplayed: false
        ))
        self.supplierUpdateResult = .success(AdminSupplierMutationResult(
            supplier: supplier,
            requestId: "req_update",
            idempotencyReplayed: nil
        ))
        self.supplierStatusResult = .success(AdminSupplierMutationResult(
            supplier: supplier,
            requestId: "req_status",
            idempotencyReplayed: false
        ))
        let purchaseOrder = AdminPurchaseOrder.fixture()
        self.purchaseOrderPageResults = [
            .success(AdminPurchaseOrderPage(purchaseOrders: [purchaseOrder], nextCursor: nil, hasMore: false))
        ]
        self.purchaseOrderDetailResult = .success(purchaseOrder)
        let purchaseReceipt = AdminPurchaseReceipt.fixture()
        self.purchaseReceiptPageResults = [
            .success(AdminPurchaseReceiptPage(receipts: [purchaseReceipt], nextCursor: nil, hasMore: false))
        ]
        self.purchaseReceiptDetailResult = .success(purchaseReceipt)
        self.purchaseReceiptEffectResult = .success(.fixture())
        let supplierDocument = AdminSupplierDocument.fixture()
        self.supplierDocumentPageResults = [
            .success(AdminSupplierDocumentPage(
                supplierDocuments: [supplierDocument],
                nextCursor: nil,
                hasMore: false
            ))
        ]
        self.supplierDocumentDetailResult = .success(supplierDocument)
        let payable = AdminPayable.fixture()
        self.payablePageResults = [
            .success(AdminPayablePage(
                payables: [payable],
                nextCursor: nil,
                hasMore: false,
                asOf: "2026-07-24"
            ))
        ]
        self.payableDetailResult = .success(payable)
        self.payableAgingResult = .success(.fixture())
        let supplierPayment = AdminSupplierPayment.fixture()
        self.supplierPaymentPageResults = [
            .success(AdminSupplierPaymentPage(
                supplierPayments: [supplierPayment],
                nextCursor: nil,
                hasMore: false
            ))
        ]
        self.supplierPaymentDetailResult = .success(supplierPayment)
        self.supplierPaymentVoidResults = [
            .success(AdminSupplierPaymentMutationResult(
                supplierPayment: .fixture(status: .voided, version: 3),
                requestId: "req_void",
                idempotencyReplayed: false
            ))
        ]
    }

    func getReadinessSnapshot(
        currency: String,
        branchId: String?
    ) async throws -> AdminProcurementContractSnapshot {
        requests.append((currency, branchId))
        return try result.get()
    }


    func getProcurementReportCatalog() async throws -> AdminProcurementReportCatalog {
        reportCatalogRequestCount += 1
        return try reportCatalogResult.get()
    }

    func getSupplierStatement(query: AdminSupplierStatementQuery) async throws -> AdminSupplierStatement {
        supplierStatementQueries.append(query)
        guard !supplierStatementResults.isEmpty else {
            return .fixture(
                supplierId: query.supplierId,
                branchId: query.branchId,
                currency: query.currency,
                nextCursor: nil,
                hasMore: false
            )
        }
        if supplierStatementResults.count == 1 {
            return try supplierStatementResults[0].get()
        }
        return try supplierStatementResults.removeFirst().get()
    }

    func downloadSupplierStatementCSV(
        query: AdminSupplierStatementQuery
    ) async throws -> AdminProcurementDownloadedFile {
        supplierStatementDownloadQueries.append(query)
        return try supplierStatementDownloadResult.get()
    }

    func downloadOperationalReportCSV(
        query: AdminProcurementOperationalExportQuery
    ) async throws -> AdminProcurementDownloadedFile {
        operationalReportDownloadQueries.append(query)
        return try operationalReportDownloadResult.get()
    }

    func listSuppliers(query: AdminSupplierListQuery) async throws -> AdminSupplierPage {
        supplierListQueries.append(query)
        guard !supplierPageResults.isEmpty else {
            return AdminSupplierPage(suppliers: [], nextCursor: nil, hasMore: false)
        }
        if supplierPageResults.count == 1 {
            return try supplierPageResults[0].get()
        }
        return try supplierPageResults.removeFirst().get()
    }

    func getSupplier(id: String) async throws -> AdminSupplier {
        supplierDetailIds.append(id)
        return try supplierDetailResult.get()
    }

    func createSupplier(_ input: AdminSupplierWriteInput) async throws -> AdminSupplierMutationResult {
        supplierCreateInputs.append(input)
        return try supplierCreateResult.get()
    }

    func updateSupplier(
        id: String,
        input: AdminSupplierWriteInput
    ) async throws -> AdminSupplierMutationResult {
        supplierUpdateRequests.append((id, input))
        return try supplierUpdateResult.get()
    }

    func changeSupplierStatus(
        id: String,
        input: AdminSupplierStatusInput
    ) async throws -> AdminSupplierMutationResult {
        supplierStatusRequests.append((id, input))
        return try supplierStatusResult.get()
    }

    func listPurchaseOrders(query: AdminPurchaseOrderListQuery) async throws -> AdminPurchaseOrderPage {
        purchaseOrderListQueries.append(query)
        guard !purchaseOrderPageResults.isEmpty else {
            return AdminPurchaseOrderPage(purchaseOrders: [], nextCursor: nil, hasMore: false)
        }
        if purchaseOrderPageResults.count == 1 {
            return try purchaseOrderPageResults[0].get()
        }
        return try purchaseOrderPageResults.removeFirst().get()
    }

    func getPurchaseOrder(id: String) async throws -> AdminPurchaseOrder {
        purchaseOrderDetailIds.append(id)
        return try purchaseOrderDetailResult.get()
    }

    func listPurchaseReceipts(query: AdminPurchaseReceiptListQuery) async throws -> AdminPurchaseReceiptPage {
        purchaseReceiptListQueries.append(query)
        guard !purchaseReceiptPageResults.isEmpty else {
            return AdminPurchaseReceiptPage(receipts: [], nextCursor: nil, hasMore: false)
        }
        if purchaseReceiptPageResults.count == 1 {
            return try purchaseReceiptPageResults[0].get()
        }
        return try purchaseReceiptPageResults.removeFirst().get()
    }

    func getPurchaseReceipt(id: String) async throws -> AdminPurchaseReceipt {
        purchaseReceiptDetailIds.append(id)
        return try purchaseReceiptDetailResult.get()
    }

    func getPurchaseReceiptInventoryEffects(
        id: String
    ) async throws -> AdminPurchaseReceiptInventoryEffects {
        purchaseReceiptEffectIds.append(id)
        return try purchaseReceiptEffectResult.get()
    }

    func listSupplierDocuments(
        query: AdminSupplierDocumentListQuery
    ) async throws -> AdminSupplierDocumentPage {
        supplierDocumentListQueries.append(query)
        guard !supplierDocumentPageResults.isEmpty else {
            return AdminSupplierDocumentPage(supplierDocuments: [], nextCursor: nil, hasMore: false)
        }
        if supplierDocumentPageResults.count == 1 {
            return try supplierDocumentPageResults[0].get()
        }
        return try supplierDocumentPageResults.removeFirst().get()
    }

    func getSupplierDocument(id: String) async throws -> AdminSupplierDocument {
        supplierDocumentDetailIds.append(id)
        return try supplierDocumentDetailResult.get()
    }

    func listPayables(query: AdminPayableListQuery) async throws -> AdminPayablePage {
        payableListQueries.append(query)
        guard !payablePageResults.isEmpty else {
            return AdminPayablePage(payables: [], nextCursor: nil, hasMore: false, asOf: query.asOf ?? "2026-07-24")
        }
        if payablePageResults.count == 1 {
            return try payablePageResults[0].get()
        }
        return try payablePageResults.removeFirst().get()
    }

    func getPayable(id: String, asOf: String?) async throws -> AdminPayable {
        payableDetailRequests.append((id, asOf))
        return try payableDetailResult.get()
    }

    func getPayableAging(query: AdminPayableAgingQuery) async throws -> AdminPayableAging {
        payableAgingQueries.append(query)
        return try payableAgingResult.get()
    }


    func listSupplierPayments(query: AdminSupplierPaymentListQuery) async throws -> AdminSupplierPaymentPage {
        supplierPaymentListQueries.append(query)
        guard !supplierPaymentPageResults.isEmpty else {
            return AdminSupplierPaymentPage(supplierPayments: [], nextCursor: nil, hasMore: false)
        }
        if supplierPaymentPageResults.count == 1 {
            return try supplierPaymentPageResults[0].get()
        }
        return try supplierPaymentPageResults.removeFirst().get()
    }

    func getSupplierPayment(id: String) async throws -> AdminSupplierPayment {
        supplierPaymentDetailIds.append(id)
        return try supplierPaymentDetailResult.get()
    }

    func voidSupplierPayment(
        id: String,
        input: AdminSupplierPaymentVoidInput
    ) async throws -> AdminSupplierPaymentMutationResult {
        supplierPaymentVoidRequests.append((id, input))
        guard !supplierPaymentVoidResults.isEmpty else {
            return AdminSupplierPaymentMutationResult(
                supplierPayment: .fixture(id: id, status: .voided, version: input.expectedVersion + 1),
                requestId: "req_void_default",
                idempotencyReplayed: false
            )
        }
        if supplierPaymentVoidResults.count == 1 {
            return try supplierPaymentVoidResults[0].get()
        }
        return try supplierPaymentVoidResults.removeFirst().get()
    }
}


extension AdminSupplierStatement {
    static func fixture(
        supplierId: String = "sup_1",
        branchId: String? = "br_1",
        currency: String = "USD",
        lineIds: [String] = ["stmt_1"],
        nextCursor: String? = nil,
        hasMore: Bool = false
    ) -> AdminSupplierStatement {
        let money: (String) -> AdminProcurementMoney = {
            AdminProcurementMoney(amount: Decimal(string: $0)!, currency: currency)
        }
        let lines = lineIds.enumerated().map { index, id in
            AdminSupplierStatementLine(
                id: id,
                occurredAt: "2026-07-2\(index + 1)T14:00:00Z",
                sourceType: index.isMultiple(of: 2) ? .supplierDocument : .paymentAllocation,
                sourceId: "source_\(index + 1)",
                description: index.isMultiple(of: 2) ? "Factura proveedor" : "Aplicación de pago",
                charge: money(index.isMultiple(of: 2) ? "100.00" : "0.00"),
                credit: money(index.isMultiple(of: 2) ? "0.00" : "30.00"),
                runningBalance: money(index.isMultiple(of: 2) ? "100.00" : "70.00"),
                currency: currency,
                auditResourceType: index.isMultiple(of: 2) ? "supplier_document" : "supplier_payment",
                auditResourceId: "audit_\(index + 1)"
            )
        }
        return AdminSupplierStatement(
            supplierId: supplierId,
            branchId: branchId,
            currency: currency,
            from: "2026-07-01",
            to: "2026-07-31",
            asOf: "2026-07-31",
            openingBalance: money("0.00"),
            lines: lines,
            closingBalance: money(lines.last?.runningBalance.amount.description ?? "0.00"),
            nextCursor: nextCursor,
            hasMore: hasMore
        )
    }
}

extension AdminProcurementDownloadedFile {
    static func fixture(
        exportType: String,
        exportVersion: String,
        fileName: String,
        rowCount: Int = 1
    ) -> AdminProcurementDownloadedFile {
        AdminProcurementDownloadedFile(
            localURL: URL(fileURLWithPath: "/tmp/\(fileName)"),
            fileName: fileName,
            contentType: "text/csv; charset=utf-8",
            sizeBytes: 64,
            exportType: exportType,
            exportVersion: exportVersion,
            rowCount: rowCount
        )
    }
}

extension AdminSupplierPayment {
    static func fixture(
        id: String = "spay_1",
        supplierId: String = "sup_1",
        paymentNumber: String = "SP-202607-000001",
        paymentDate: String = "2026-07-24",
        status: AdminSupplierPaymentStatus = .recorded,
        amount: String = "50.00",
        method: AdminSupplierPaymentMethod? = .bankTransfer,
        reference: String? = "TRX-001",
        version: Int64 = 2
    ) -> AdminSupplierPayment {
        let paymentAmount = Decimal(string: amount)!
        let balanceBefore = Decimal(string: "112.00")!
        let balanceAfter = balanceBefore - paymentAmount
        let isReversed = status == .voided
        let allocation = AdminSupplierPaymentAllocation(
            id: "palloc_1",
            payableId: "pbl_1",
            amount: AdminProcurementMoney(amount: paymentAmount, currency: "USD"),
            payableBalanceBefore: AdminProcurementMoney(amount: balanceBefore, currency: "USD"),
            payableBalanceAfter: AdminProcurementMoney(amount: balanceAfter, currency: "USD"),
            status: isReversed ? .reversed : .applied,
            createdAt: "2026-07-24T14:00:00Z",
            createdBy: "usr_record",
            reversedAt: isReversed ? "2026-07-24T16:00:00Z" : nil,
            reversedBy: isReversed ? "usr_void" : nil,
            reversalReason: isReversed ? "Pago duplicado" : nil
        )
        let hasRecordedEvidence = status != .processing
        let hasVoidClaim = status == .voiding || status == .voided
        return AdminSupplierPayment(
            id: id,
            branchId: "br_1",
            supplierId: supplierId,
            paymentNumber: paymentNumber,
            paymentDate: paymentDate,
            currency: "USD",
            amount: AdminProcurementMoney(amount: paymentAmount, currency: "USD"),
            method: method,
            reference: method == nil ? nil : reference,
            status: status,
            allocations: [allocation],
            attachmentIds: method == nil ? nil : ["patt_1"],
            cashMovementId: method == nil ? nil : "cmov_1",
            notes: method == nil ? nil : "Pago de prueba",
            createdAt: "2026-07-24T13:00:00Z",
            createdBy: "usr_create",
            updatedAt: status == .voided ? "2026-07-24T16:00:00Z" : "2026-07-24T15:00:00Z",
            updatedBy: hasVoidClaim ? "usr_void" : "usr_record",
            recordedAt: hasRecordedEvidence ? "2026-07-24T15:00:00Z" : nil,
            recordedBy: hasRecordedEvidence ? "usr_record" : nil,
            voidedAt: status == .voided ? "2026-07-24T16:00:00Z" : nil,
            voidedBy: status == .voided ? "usr_void" : nil,
            voidReason: hasVoidClaim ? "Pago duplicado" : nil,
            version: version
        )
    }
}


extension AdminPayable {
    static func fixture(
        id: String = "pbl_1",
        supplierId: String = "sup_1",
        sourceId: String = "sdoc_1",
        dueDate: String = "2026-08-15",
        settlementStatus: AdminPayableSettlementStatus = .partiallyPaid,
        effectiveStatus: AdminPayableEffectiveStatus = .partiallyPaid,
        originalAmount: String = "112.00",
        paidAmount: String = "50.00",
        balance: String = "62.00",
        version: Int64 = 2,
        updatedAt: String = "2026-07-24T15:00:00Z"
    ) -> AdminPayable {
        let money: (String) -> AdminProcurementMoney = {
            AdminProcurementMoney(amount: Decimal(string: $0)!, currency: "USD")
        }
        return AdminPayable(
            id: id,
            branchId: "br_1",
            supplierId: supplierId,
            sourceType: "SUPPLIER_DOCUMENT",
            sourceId: sourceId,
            currency: "USD",
            originalAmount: money(originalAmount),
            paidAmount: money(paidAmount),
            balance: money(balance),
            dueDate: dueDate,
            settlementStatus: settlementStatus,
            effectiveStatus: effectiveStatus,
            allocationIds: paidAmount == "0.00" ? [] : ["palloc_1"],
            createdAt: "2026-07-23T14:00:00Z",
            createdBy: "usr_create",
            updatedAt: updatedAt,
            updatedBy: "usr_update",
            version: version
        )
    }
}

extension AdminPayableAging {
    static func fixture(asOf: String = "2026-07-24") -> AdminPayableAging {
        let money: (String) -> AdminProcurementMoney = {
            AdminProcurementMoney(amount: Decimal(string: $0)!, currency: "USD")
        }
        return AdminPayableAging(
            currency: "USD",
            asOf: asOf,
            buckets: [
                AdminPayableAgingBucket(code: .current, count: 1, balance: money("62.00")),
                AdminPayableAgingBucket(code: .due1To30, count: 0, balance: money("0.00")),
                AdminPayableAgingBucket(code: .due31To60, count: 0, balance: money("0.00")),
                AdminPayableAgingBucket(code: .due61To90, count: 0, balance: money("0.00")),
                AdminPayableAgingBucket(code: .due91Plus, count: 0, balance: money("0.00")),
                AdminPayableAgingBucket(code: .noDueDate, count: 0, balance: money("0.00"))
            ]
        )
    }
}

extension AdminSupplierDocument {
    static func fixture(
        id: String = "sdoc_1",
        documentNumber: String = "FAC-001-001-000000123",
        status: AdminSupplierDocumentStatus = .confirmed,
        documentType: AdminSupplierDocumentType = .supplierInvoice,
        version: Int64 = 3,
        updatedAt: String = "2026-07-23T15:00:00Z"
    ) -> AdminSupplierDocument {
        let money: (String) -> AdminProcurementMoney = {
            AdminProcurementMoney(amount: Decimal(string: $0)!, currency: "USD")
        }
        let line = AdminSupplierDocumentLine(
            id: "sdl_1",
            kind: .stockItem,
            catalogItemId: "item_1",
            catalogItemSnapshot: AdminPurchaseItemSnapshot(
                catalogItemId: "item_1",
                localName: "Café de prueba",
                sku: "CAF-001",
                unitCode: "UNIT",
                taxProfileId: "tax_1",
                taxProfileVersion: 2
            ),
            purchaseOrderLineId: "pol_1",
            purchaseReceiptLineId: "prl_1",
            descriptionSnapshot: "Café de prueba",
            quantity: AdminPurchaseQuantity(value: Decimal(10), unitCode: "UNIT", allowsDecimal: false),
            unitCost: money("10.00"),
            discountAmount: money("0.00"),
            priceTaxMode: .taxExclusive,
            taxProfileId: "tax_1",
            taxProfileVersion: 2,
            taxes: [
                AdminPurchaseTax(
                    taxCode: "IVA",
                    rateCode: "IVA_12",
                    rate: Decimal(string: "0.12")!,
                    taxableBase: money("100.00"),
                    amount: money("12.00")
                )
            ],
            grossAmount: money("100.00"),
            netAmount: money("100.00"),
            taxAmount: money("12.00"),
            lineTotal: money("112.00"),
            expenseCategoryCode: nil,
            notes: nil
        )
        return AdminSupplierDocument(
            id: id,
            branchId: "br_1",
            supplierId: "sup_1",
            documentType: documentType,
            status: status,
            documentNumber: documentNumber,
            documentNumberNormalized: "FAC001001000000123",
            accessKey: "access-key-metadata",
            authorizationNumber: "auth-metadata",
            documentDate: "2026-07-23",
            dueDate: "2026-08-22",
            currency: "USD",
            purchaseOrderIds: ["po_1"],
            purchaseReceiptIds: ["pr_1"],
            lines: [line],
            subtotal: money("100.00"),
            discountTotal: money("0.00"),
            taxTotal: money("12.00"),
            total: money("112.00"),
            sourceTotals: AdminSupplierDocumentSourceTotals(
                total: money("112.00"),
                taxTotal: money("12.00")
            ),
            sourcePayment: nil,
            payableAmount: money("112.00"),
            payableId: status == .confirmed ? "pay_1" : nil,
            attachmentIds: ["att_1"],
            accountingStatus: .futureReview,
            notes: "Documento recibido",
            createdAt: "2026-07-23T14:00:00Z",
            createdBy: "usr_create",
            updatedAt: updatedAt,
            updatedBy: "usr_update",
            confirmedAt: status == .confirmed ? "2026-07-23T15:00:00Z" : nil,
            confirmedBy: status == .confirmed ? "usr_confirm" : nil,
            cancelledAt: status == .cancelled ? "2026-07-23T15:00:00Z" : nil,
            cancelledBy: status == .cancelled ? "usr_cancel" : nil,
            cancellationReason: status == .cancelled ? "Documento duplicado" : nil,
            version: version
        )
    }
}

extension AdminPurchaseReceipt {
    static func fixture(
        id: String = "pr_1",
        receiptNumber: String = "PR-260722-000001",
        status: AdminPurchaseReceiptStatus = .confirmed,
        purchaseOrderId: String? = "po_1",
        version: Int64 = 2
    ) -> AdminPurchaseReceipt {
        let movementId = status == .confirmed ? "stmov_1" : nil
        let line = AdminPurchaseReceiptLine(
            id: "prl_1",
            purchaseOrderLineId: purchaseOrderId == nil ? nil : "pol_1",
            kind: .stockItem,
            catalogItemId: "item_1",
            itemSnapshot: AdminPurchaseItemSnapshot(
                catalogItemId: "item_1",
                localName: "Café de prueba",
                sku: "CAF-001",
                unitCode: "UNIT",
                taxProfileId: "tax_1",
                taxProfileVersion: 2
            ),
            receivedQuantity: AdminPurchaseQuantity(
                value: Decimal(2),
                unitCode: "UNIT",
                allowsDecimal: false
            ),
            acceptedQuantity: Decimal(2),
            rejectedQuantity: Decimal(0),
            unitCode: "UNIT",
            unitCost: AdminProcurementMoney(amount: Decimal(string: "3.25")!, currency: "USD"),
            warehouseId: "wh_1",
            trackedUnits: [],
            inventoryMovementId: movementId,
            notes: nil
        )
        return AdminPurchaseReceipt(
            id: id,
            branchId: "br_1",
            supplierId: "sup_1",
            purchaseOrderId: purchaseOrderId,
            receiptNumber: receiptNumber,
            status: status,
            warehouseId: "wh_1",
            receivedAt: "2026-07-22T14:00:00Z",
            lines: [line],
            inventoryMovementIds: movementId.map { [$0] } ?? [],
            attachmentIds: ["att_1"],
            notes: "Entrega parcial",
            createdAt: "2026-07-22T13:00:00Z",
            createdBy: "usr_create",
            updatedAt: "2026-07-22T14:00:00Z",
            updatedBy: "usr_confirm",
            confirmedAt: status == .confirmed ? "2026-07-22T14:00:00Z" : nil,
            confirmedBy: status == .confirmed ? "usr_confirm" : nil,
            cancelledAt: status == .cancelled ? "2026-07-22T14:00:00Z" : nil,
            cancelledBy: status == .cancelled ? "usr_cancel" : nil,
            cancellationReason: status == .cancelled ? "Error de captura" : nil,
            version: version
        )
    }
}

extension AdminPurchaseReceiptInventoryEffects {
    static func fixture(
        receiptId: String = "pr_1",
        quantityStatus: AdminPurchaseReceiptQuantityReconciliationStatus = .quantityReconciled,
        costsVisible: Bool = true
    ) -> AdminPurchaseReceiptInventoryEffects {
        let hasMovement = quantityStatus == .quantityReconciled
        let effect = AdminPurchaseReceiptInventoryEffectLine(
            receiptLineId: "prl_1",
            kind: .stockItem,
            catalogItemId: "item_1",
            receiptAcceptedQuantity: AdminPurchaseQuantity(
                value: Decimal(2),
                unitCode: "UNIT",
                allowsDecimal: false
            ),
            warehouseId: "wh_1",
            inventoryMovementId: hasMovement ? "stmov_1" : nil,
            effectStatus: hasMovement ? .quantityReconciled : .notApplicable,
            movementType: hasMovement ? "purchase_in" : nil,
            direction: hasMovement ? "in" : nil,
            movementQuantity: hasMovement
                ? AdminPurchaseQuantity(value: Decimal(2), unitCode: "UNIT", allowsDecimal: false)
                : nil,
            quantityBefore: hasMovement ? Decimal(5) : nil,
            quantityAfter: hasMovement ? Decimal(7) : nil,
            sourceType: hasMovement ? "purchase_receipt" : nil,
            sourceId: hasMovement ? receiptId : nil,
            sourceLineId: hasMovement ? "prl_1" : nil,
            occurredAt: hasMovement ? "2026-07-22T14:00:00Z" : nil,
            createdBy: hasMovement ? "usr_confirm" : nil,
            unitCost: hasMovement && costsVisible
                ? AdminProcurementMoney(amount: Decimal(string: "3.25")!, currency: "USD")
                : nil,
            totalCost: hasMovement && costsVisible
                ? AdminProcurementMoney(amount: Decimal(string: "6.50")!, currency: "USD")
                : nil,
            valueStatus: hasMovement
                ? (costsVisible ? .valueReconciled : .redacted)
                : .notApplicable
        )
        return AdminPurchaseReceiptInventoryEffects(
            receiptId: receiptId,
            receiptNumber: "PR-260722-000001",
            receiptStatus: hasMovement ? .confirmed : .draft,
            branchId: "br_1",
            supplierId: "sup_1",
            purchaseOrderId: "po_1",
            warehouseId: "wh_1",
            quantityStatus: quantityStatus,
            valueStatus: hasMovement
                ? (costsVisible ? .valueReconciled : .redacted)
                : .notApplicable,
            costsVisible: costsVisible,
            limitations: [],
            lines: [effect],
            requestId: "req_effect"
        )
    }
}

extension AdminPurchaseOrder {
    static func fixture(
        id: String = "po_1",
        orderNumber: String = "PO-260721-000001",
        status: AdminPurchaseOrderStatus = .partiallyReceived,
        version: Int64 = 4,
        total: Decimal? = Decimal(string: "112.00")!,
        updatedAt: String = "2026-07-21T14:00:00Z"
    ) -> AdminPurchaseOrder {
        let costsVisible = total != nil
        let money: (Decimal) -> AdminProcurementMoney = {
            AdminProcurementMoney(amount: $0, currency: "USD")
        }
        let line = AdminPurchaseOrderLine(
            id: "pol_1",
            kind: .stockItem,
            catalogItemId: "item_1",
            catalogItemSnapshot: AdminPurchaseItemSnapshot(
                catalogItemId: "item_1",
                localName: "Café de prueba",
                sku: "CAF-001",
                unitCode: "UNIT",
                taxProfileId: "tax_1",
                taxProfileVersion: 2
            ),
            descriptionSnapshot: "Café de prueba",
            orderedQuantity: AdminPurchaseQuantity(value: Decimal(10), unitCode: "UNIT", allowsDecimal: false),
            receivedQuantity: Decimal(4),
            unitCost: costsVisible ? money(Decimal(10)) : nil,
            discountAmount: costsVisible ? money(Decimal(0)) : nil,
            priceTaxMode: .taxExclusive,
            taxProfileId: "tax_1",
            taxProfileVersion: 2,
            taxes: costsVisible ? [
                AdminPurchaseTax(
                    taxCode: "IVA",
                    rateCode: "IVA_12",
                    rate: Decimal(string: "0.12")!,
                    taxableBase: money(Decimal(100)),
                    amount: money(Decimal(12))
                )
            ] : nil,
            grossAmount: costsVisible ? money(Decimal(100)) : nil,
            netAmount: costsVisible ? money(Decimal(100)) : nil,
            taxAmount: costsVisible ? money(Decimal(12)) : nil,
            lineTotal: costsVisible ? money(Decimal(112)) : nil,
            targetWarehouseId: "wh_1",
            notes: nil
        )
        return AdminPurchaseOrder(
            id: id,
            branchId: "br_1",
            supplierId: "sup_1",
            orderNumber: orderNumber,
            status: status,
            currency: "USD",
            lines: [line],
            subtotal: total.map { _ in money(Decimal(100)) },
            discountTotal: total.map { _ in money(Decimal(0)) },
            taxTotal: total.map { _ in money(Decimal(12)) },
            total: total.map(money),
            expectedDate: "2026-07-25",
            supplierSnapshot: AdminPurchaseSupplierSnapshot(
                supplierId: "sup_1",
                legalName: "Proveedor Uno S.A.",
                tradeName: "Proveedor Uno",
                identificationType: .ruc,
                identificationNumber: "1799999999001",
                paymentTerms: AdminSupplierPaymentTerms(mode: .netDays, netDays: 30, label: nil, notes: nil),
                defaultCurrency: "USD"
            ),
            paymentTermsSnapshot: AdminSupplierPaymentTerms(mode: .netDays, netDays: 30, label: nil, notes: nil),
            notes: "Entrega parcial autorizada",
            attachmentIds: ["att_1"],
            createdAt: "2026-07-20T12:00:00Z",
            createdBy: "usr_create",
            updatedAt: updatedAt,
            updatedBy: "usr_update",
            sentAt: "2026-07-20T13:00:00Z",
            sentBy: "usr_send",
            closedAt: nil,
            closedBy: nil,
            closeReason: nil,
            cancelledAt: nil,
            cancelledBy: nil,
            cancellationReason: nil,
            version: version,
            costsVisible: costsVisible
        )
    }
}

extension AdminSupplier {
    static func fixture(
        id: String = "sup_1",
        legalName: String = "Proveedor Uno S.A.",
        tradeName: String? = "Proveedor Uno",
        status: AdminSupplierStatus = .active,
        version: Int64 = 1,
        contacts: [AdminSupplierContact]? = [
            AdminSupplierContact(
                id: "scon_1",
                name: "Ana Proveedor",
                role: "Ventas",
                email: "ana@example.test",
                phone: "0990000000",
                isPrimary: true,
                notes: nil
            )
        ]
    ) -> AdminSupplier {
        AdminSupplier(
            id: id,
            legalName: legalName,
            tradeName: tradeName,
            identificationType: .ruc,
            identificationNumber: contacts == nil ? nil : "1799999999001",
            email: contacts == nil ? nil : "compras@example.test",
            phone: contacts == nil ? nil : "022000000",
            address: contacts == nil ? nil : "Quito",
            categories: ["insumos"],
            contacts: contacts,
            paymentTerms: AdminSupplierPaymentTerms(
                mode: .netDays,
                netDays: 30,
                label: nil,
                notes: nil
            ),
            defaultCurrency: "USD",
            status: status,
            notes: contacts == nil ? nil : "Entrega semanal",
            createdAt: "2026-07-14T12:00:00Z",
            createdBy: "usr_create",
            updatedAt: "2026-07-21T12:00:00Z",
            updatedBy: "usr_update",
            version: version
        )
    }
}

extension AdminProcurementContractSnapshot {
    static func fixture(
        payableReconciled: Bool = true,
        financeReconciled: Bool = true,
        accountingEntriesGenerated: Bool = false,
        branchId: String? = "br_1",
        catalogImplementationOverride: String? = nil,
        replayReadOnly: Bool = true,
        replayHasMore: Bool = false,
        replayNextCursorAvailable: Bool = false,
        accountingMatrixVersion: String = "27R.L0.H.v1",
        accountingMatrixReadOnly: Bool = true
    ) -> AdminProcurementContractSnapshot {
        let catalogEntries = AdminProcurementReadinessEvaluator.requiredReportTypes.sorted().map { type in
            AdminProcurementReportCatalogEntry(
                reportType: type,
                title: type,
                description: "Fixture",
                jsonPath: type == "supplier_statement"
                    ? "/api/v1/admin/procurement/suppliers/{supplierId}/statement"
                    : "/api/v1/admin/procurement/reports/\(type)",
                csvPath: type == "supplier_statement"
                    ? "/api/v1/admin/procurement/suppliers/{supplierId}/statement.csv"
                    : "/api/v1/admin/procurement/reports/\(type)/export.csv",
                implementation: catalogImplementationOverride ?? (type == "supplier_statement" ? "27R.J.v1" : "27R.L.v1")
            )
        }
        let money = AdminProcurementMoney(amount: Decimal(string: "125.40")!, currency: "USD")

        return AdminProcurementContractSnapshot(
            catalog: AdminProcurementReportCatalog(
                contractVersion: 1,
                reports: catalogEntries,
                financeFactsPath: "/api/v1/admin/procurement/finance-facts",
                financeFactsCsvPath: "/api/v1/admin/procurement/finance-facts/export.csv",
                accountingEntriesGenerated: accountingEntriesGenerated
            ),
            payableHealth: AdminProcurementOperationalHealth(
                reportType: "open_overdue_payables",
                title: "Open and overdue payables",
                branchId: branchId,
                currency: "USD",
                asOf: "2026-07-21",
                generatedAt: "2026-07-21T14:00:00Z",
                matchingRowCount: 2,
                totalAmount: money,
                openBalance: money,
                reconciliationChecks: [
                    AdminProcurementReconciliationCheck(
                        name: "payable_original_to_paid_plus_balance",
                        expected: "125.40",
                        actual: payableReconciled ? "125.40" : "120.40",
                        unit: "USD",
                        passed: payableReconciled
                    )
                ],
                hasMore: false
            ),
            financeHealth: AdminProcurementFinanceHealth(
                organizationId: "org_1",
                branchId: branchId,
                currency: "USD",
                generatedAt: "2026-07-21T14:00:00Z",
                matchingFactCount: 4,
                accountingEntriesGenerated: accountingEntriesGenerated,
                reconciliationChecks: [
                    AdminProcurementReconciliationCheck(
                        name: "finance_source_replay",
                        expected: "4",
                        actual: financeReconciled ? "4" : "3",
                        unit: "count",
                        passed: financeReconciled
                    )
                ],
                hasMore: false
            ),
            financeSourceFactReplayReadiness: AdminProcurementFinanceSourceFactReplayReadiness(
                contractVersion: 1,
                schemaVersion: 1,
                organizationId: "org_1",
                branchId: branchId,
                supplierId: nil,
                currency: "USD",
                effectiveFrom: nil,
                effectiveTo: nil,
                snapshotAt: "2026-07-21T14:00:00Z",
                returnedFactCount: replayHasMore ? 1 : 0,
                hasMore: replayHasMore,
                nextCursorAvailable: replayNextCursorAvailable,
                maxPageSize: 100,
                supportedFactTypes: [
                    "PURCHASE_ORDER_SENT",
                    "PURCHASE_ORDER_CANCELLED",
                    "PURCHASE_RECEIPT_CONFIRMED",
                    "SUPPLIER_DOCUMENT_CONFIRMED",
                    "SOURCE_PAYMENT_RECORDED",
                    "PAYABLE_CREATED",
                    "PAYABLE_STATUS_CHANGED",
                    "SUPPLIER_PAYMENT_RECORDED",
                    "SUPPLIER_PAYMENT_VOIDED"
                ],
                reservedFactTypes: [
                    "PURCHASE_RECEIPT_REVERSED",
                    "SUPPLIER_DOCUMENT_VOIDED",
                    "PAYABLE_ADJUSTMENT_RECORDED",
                    "PAYABLE_ADJUSTMENT_VOIDED"
                ],
                replayMode: "SNAPSHOT_KEYSET_V1",
                readOnly: replayReadOnly,
                accountingEntriesGenerated: false,
                postable: false,
                limitations: ["USD_ONLY", "READ_ONLY", "NO_ACCOUNTING_ENTRIES", "NO_PAYLOAD_EXPOSURE"]
            ),
            accountingCompletenessMatrix: .fixture(
                matrixVersion: accountingMatrixVersion,
                readOnly: accountingMatrixReadOnly
            )
        )
    }
}

extension AdminProcurementAccountingCompletenessMatrix {
    static func fixture(
        matrixVersion: String = "27R.L0.H.v1",
        readOnly: Bool = true
    ) -> AdminProcurementAccountingCompletenessMatrix {
        let passItems = AdminProcurementReadinessEvaluator.accountingCompletenessPassExistingIds.sorted().map {
            AdminProcurementAccountingCompletenessItem.fixture(id: $0, classification: .passExisting)
        }
        let futureGapItems = AdminProcurementReadinessEvaluator.accountingCompletenessFutureGapIds.sorted().map {
            AdminProcurementAccountingCompletenessItem.fixture(id: $0, classification: .documentFutureGap)
        }
        let notApplicableItems = AdminProcurementReadinessEvaluator.accountingCompletenessNotApplicableIds.sorted().map {
            AdminProcurementAccountingCompletenessItem.fixture(id: $0, classification: .notApplicable)
        }
        return AdminProcurementAccountingCompletenessMatrix(
            contractVersion: 1,
            matrixVersion: matrixVersion,
            acceptedStage: "27R.L.7",
            organizationId: "org_1",
            currency: "USD",
            scope: "PROCUREMENT_PAYABLES",
            sourceDocument: "NEXO_27R_ACCOUNTING_COMPLETENESS_SOURCE_MATRIX.md",
            totalItemCount: 33,
            passExistingCount: 20,
            futureGapCount: 10,
            notApplicableCount: 3,
            items: passItems + futureGapItems + notApplicableItems,
            readOnly: readOnly,
            accountingEntriesGenerated: false,
            postable: false,
            limitations: ["USD_ONLY", "READ_ONLY", "NO_ACCOUNTING_ENTRIES", "NO_TAX_OR_ACCOUNTING_INFERENCE"]
        )
    }
}

extension AdminProcurementAccountingCompletenessItem {
    static func fixture(
        id: String,
        classification: AdminProcurementAccountingCompletenessClassification
    ) -> AdminProcurementAccountingCompletenessItem {
        AdminProcurementAccountingCompletenessItem(
            id: id,
            title: id,
            displayTitle: id.replacingOccurrences(of: "_", with: " ").capitalized,
            authoritativeEvidence: "Canonical 27R source evidence",
            v1ReplayStatus: "Accepted V1 replay status",
            classification: classification,
            classificationNote: nil,
            futureOwnerAction: "28R/29R controlled follow-up"
        )
    }
}

extension AdminFoundationTestRepository {
    static func procurementReady() -> AdminFoundationTestRepository {
        let context = AdminBusinessContext(
            user: AdminBusinessContextUser(id: "usr_1", displayName: "Admin", email: "admin@nexo.test"),
            organization: AdminBusinessContextOrganization(
                id: "org_1",
                legalName: "Altos del Murco",
                commercialName: "Altos del Murco",
                countryCode: "EC",
                taxId: "9999999999999",
                defaultCurrency: "USD",
                timezone: "America/Guayaquil"
            ),
            branches: [
                AdminBusinessContextBranch(id: "br_1", code: "001", name: "Matriz", type: "main", status: "active", main: true)
            ],
            activeBranchId: "br_1",
            activities: [],
            activeModules: ["module.purchases", "core.reports"],
            effectivePermissions: [PermissionCatalog.all],
            catalogRevision: "catrev_1",
            taxConfigurationRevision: "taxrev_1",
            realtime: AdminBusinessContextRealtime(enabled: false, sseUrl: "/api/v1/realtime/events")
        )
        let modules = [
            AdminResolvedModule.fixture(code: "module.purchases", active: true),
            AdminResolvedModule.fixture(code: "core.reports", active: true)
        ]
        let readiness = modules.map {
            AdminModuleReadinessItem(
                code: $0.code,
                ready: true,
                active: true,
                missingDependencies: [],
                warnings: [],
                blockers: []
            )
        }
        return AdminFoundationTestRepository(
            contextResult: context,
            modulesResult: AdminModulesResult(organizationId: "org_1", modules: modules),
            readinessResult: AdminModuleReadinessResult(organizationId: "org_1", readiness: readiness)
        )
    }
}
