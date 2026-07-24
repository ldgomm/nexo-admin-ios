//
//  AdminPurchaseReceiptMapperTests.swift
//  Nexo AdminTests
//
//  27R.N.4 — Receipt quantities, linkage, redaction and reconciliation scope.
//

import Foundation
import XCTest
@testable import Nexo_Admin

final class AdminPurchaseReceiptMapperTests: XCTestCase {
    func testConfirmedReceiptMapsEventQuantitiesWithoutCollapsingThem() throws {
        let receipt = try makeReceiptDTO().toDomain()

        XCTAssertEqual(receipt.status, .confirmed)
        XCTAssertEqual(receipt.receiptNumber, "PR-260722-000001")
        XCTAssertEqual(receipt.lines.first?.receivedQuantity.value, Decimal(2))
        XCTAssertEqual(receipt.lines.first?.acceptedQuantity, Decimal(2))
        XCTAssertEqual(receipt.lines.first?.rejectedQuantity, Decimal(0))
        XCTAssertEqual(receipt.lines.first?.receivedQuantity.formatted, "2")
        XCTAssertEqual(receipt.inventoryMovementIds, ["stmov_1"])
    }

    func testReceiptWithoutPurchaseOrderPreservesUnavailableOrderContext() throws {
        let receipt = try makeReceiptDTO(purchaseOrderId: nil).toDomain()

        XCTAssertNil(receipt.purchaseOrderId)
        XCTAssertNil(receipt.lines.first?.purchaseOrderLineId)
    }

    func testIncoherentReceiptQuantitiesAreRejected() {
        XCTAssertThrowsError(
            try makeReceiptDTO(acceptedQuantity: "1", rejectedQuantity: "0").toDomain()
        )
    }

    func testDraftReceiptCannotCarryInventoryMovementEvidence() {
        XCTAssertThrowsError(try makeReceiptDTO(status: "DRAFT", movementId: "stmov_1").toDomain())
    }

    func testConfirmedInventoryEffectMapsQuantityButNotValueReconciliationScope() throws {
        let effects = try makeEffectsDTO().toDomain(requestId: "req_1")

        XCTAssertEqual(effects.quantityStatus, .quantityReconciled)
        XCTAssertEqual(effects.reconciliationScope, .quantityReconciled)
        XCTAssertEqual(effects.valueStatus, .sourceCurrencyLinked)
        XCTAssertTrue(effects.currencyComesFromReceiptSource)
        XCTAssertEqual(effects.lines.first?.movementQuantity?.value, Decimal(2))
        XCTAssertEqual(effects.lines.first?.unitCost?.currency, "USD")
    }

    func testRedactedEffectPreservesQuantityAndOmitsAllMoney() throws {
        let effects = try makeEffectsDTO(costsVisible: false).toDomain(requestId: nil)

        XCTAssertEqual(effects.quantityStatus, .quantityReconciled)
        XCTAssertEqual(effects.valueStatus, .redacted)
        XCTAssertFalse(effects.costsVisible)
        XCTAssertNil(effects.lines.first?.unitCost)
        XCTAssertNil(effects.lines.first?.totalCost)
    }

    func testDraftEffectIsExplicitlyNoEffectExpected() throws {
        let effects = try makeEffectsDTO(
            status: "DRAFT",
            quantityStatus: "NO_EFFECT_EXPECTED",
            valueStatus: "NOT_APPLICABLE",
            hasMovement: false
        ).toDomain(requestId: nil)

        XCTAssertEqual(effects.receiptStatus, .draft)
        XCTAssertEqual(effects.quantityStatus, .noEffectExpected)
        XCTAssertEqual(effects.lines.first?.effectStatus, .notApplicable)
        XCTAssertEqual(effects.reconciliationScope, .none)
    }

    func testMismatchedMovementSourceFailsClosed() {
        XCTAssertThrowsError(
            try makeEffectsDTO(sourceId: "pr_other").toDomain(requestId: nil)
        )
    }

    func testMovementBalanceMustMatchAcceptedQuantity() {
        XCTAssertThrowsError(
            try makeEffectsDTO(quantityAfter: "8").toDomain(requestId: nil)
        )
    }

    private func makeReceiptDTO(
        status: String = "CONFIRMED",
        purchaseOrderId: String? = "po_1",
        movementId: String? = "stmov_1",
        acceptedQuantity: String = "2.000000",
        rejectedQuantity: String = "0.000000"
    ) -> AdminPurchaseReceiptDTO {
        let snapshot = AdminPurchaseItemSnapshotDTO(
            catalogItemId: "item_1",
            localName: "Café de prueba",
            sku: "CAF-001",
            unitCode: "UNIT",
            taxProfileId: "tax_1",
            taxProfileVersion: 2
        )
        let line = AdminPurchaseReceiptLineDTO(
            id: "prl_1",
            purchaseOrderLineId: purchaseOrderId == nil ? nil : "pol_1",
            kind: "STOCK_ITEM",
            catalogItemId: "item_1",
            itemSnapshot: snapshot,
            receivedQuantity: AdminPurchaseQuantityDTO(
                value: "2.000000",
                unitCode: "UNIT",
                allowsDecimal: false
            ),
            acceptedQuantity: acceptedQuantity,
            rejectedQuantity: rejectedQuantity,
            unitCode: "UNIT",
            unitCost: AdminProcurementMoneyDTO(amount: "3.25", currency: "USD"),
            warehouseId: "wh_1",
            trackedUnits: [],
            inventoryMovementId: movementId,
            notes: nil
        )
        return AdminPurchaseReceiptDTO(
            id: "pr_1",
            branchId: "br_1",
            supplierId: "sup_1",
            purchaseOrderId: purchaseOrderId,
            receiptNumber: "PR-260722-000001",
            status: status,
            warehouseId: "wh_1",
            receivedAt: "2026-07-22T14:00:00Z",
            lines: [line],
            inventoryMovementIds: movementId.map { [$0] } ?? [],
            attachmentIds: ["att_1"],
            notes: nil,
            createdAt: "2026-07-22T13:00:00Z",
            createdBy: "usr_create",
            updatedAt: "2026-07-22T14:00:00Z",
            updatedBy: "usr_confirm",
            confirmedAt: status == "CONFIRMED" ? "2026-07-22T14:00:00Z" : nil,
            confirmedBy: status == "CONFIRMED" ? "usr_confirm" : nil,
            cancelledAt: status == "CANCELLED" ? "2026-07-22T14:00:00Z" : nil,
            cancelledBy: status == "CANCELLED" ? "usr_cancel" : nil,
            cancellationReason: status == "CANCELLED" ? "Error de captura" : nil,
            version: 2
        )
    }

    private func makeEffectsDTO(
        status: String = "CONFIRMED",
        quantityStatus: String = "QUANTITY_RECONCILED",
        valueStatus: String = "SOURCE_CURRENCY_LINKED",
        costsVisible: Bool = true,
        hasMovement: Bool = true,
        sourceId: String = "pr_1",
        quantityAfter: String = "7"
    ) -> AdminPurchaseReceiptInventoryEffectsDTO {
        let line = AdminPurchaseReceiptInventoryEffectLineDTO(
            receiptLineId: "prl_1",
            kind: "STOCK_ITEM",
            catalogItemId: "item_1",
            receiptAcceptedQuantity: AdminPurchaseQuantityDTO(
                value: "2",
                unitCode: "UNIT",
                allowsDecimal: false
            ),
            warehouseId: "wh_1",
            inventoryMovementId: hasMovement ? "stmov_1" : nil,
            effectStatus: hasMovement ? "QUANTITY_RECONCILED" : "NOT_APPLICABLE",
            movementType: hasMovement ? "purchase_in" : nil,
            direction: hasMovement ? "in" : nil,
            movementQuantity: hasMovement
                ? AdminPurchaseQuantityDTO(value: "2", unitCode: "UNIT", allowsDecimal: false)
                : nil,
            quantityBefore: hasMovement ? "5" : nil,
            quantityAfter: hasMovement ? quantityAfter : nil,
            sourceType: hasMovement ? "purchase_receipt" : nil,
            sourceId: hasMovement ? sourceId : nil,
            sourceLineId: hasMovement ? "prl_1" : nil,
            occurredAt: hasMovement ? "2026-07-22T14:00:00Z" : nil,
            createdBy: hasMovement ? "usr_confirm" : nil,
            unitCost: hasMovement && costsVisible
                ? AdminProcurementMoneyDTO(amount: "3.25", currency: "USD")
                : nil,
            totalCost: hasMovement && costsVisible
                ? AdminProcurementMoneyDTO(amount: "6.50", currency: "USD")
                : nil,
            valueStatus: hasMovement
                ? (costsVisible ? valueStatus : "REDACTED")
                : "NOT_APPLICABLE"
        )
        return AdminPurchaseReceiptInventoryEffectsDTO(
            receiptId: "pr_1",
            receiptNumber: "PR-260722-000001",
            receiptStatus: status,
            branchId: "br_1",
            supplierId: "sup_1",
            purchaseOrderId: "po_1",
            warehouseId: "wh_1",
            quantityReconciliationStatus: quantityStatus,
            valueReconciliationStatus: hasMovement
                ? (costsVisible ? valueStatus : "REDACTED")
                : "NOT_APPLICABLE",
            costsVisible: costsVisible,
            limitations: hasMovement && costsVisible
                ? ["MOVEMENT_CURRENCY_DERIVED_FROM_RECEIPT_SOURCE"]
                : [],
            lines: [line]
        )
    }
}
