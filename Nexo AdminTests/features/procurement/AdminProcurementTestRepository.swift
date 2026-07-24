//
//  AdminProcurementTestRepository.swift
//  Nexo AdminTests
//
//  27R.N.1B–N.4 test support.
//

import Foundation
@testable import Nexo_Admin

final class AdminProcurementTestRepository: AdminProcurementRepository, @unchecked Sendable {
    var result: Result<AdminProcurementContractSnapshot, Error>
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

    private(set) var requests: [(currency: String, branchId: String?)] = []
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

    init(result: Result<AdminProcurementContractSnapshot, Error> = .success(.fixture())) {
        let supplier = AdminSupplier.fixture()
        self.result = result
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
    }

    func getReadinessSnapshot(
        currency: String,
        branchId: String?
    ) async throws -> AdminProcurementContractSnapshot {
        requests.append((currency, branchId))
        return try result.get()
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
                ? (costsVisible ? .sourceCurrencyLinked : .redacted)
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
                ? (costsVisible ? .sourceCurrencyLinked : .redacted)
                : .notApplicable,
            costsVisible: costsVisible,
            limitations: costsVisible ? ["MOVEMENT_CURRENCY_DERIVED_FROM_RECEIPT_SOURCE"] : [],
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
        catalogImplementationOverride: String? = nil
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
            )
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
