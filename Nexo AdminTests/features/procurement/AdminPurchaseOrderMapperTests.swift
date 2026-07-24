//
//  AdminPurchaseOrderMapperTests.swift
//  Nexo AdminTests
//
//  27R.N.3 — Purchase order snapshots, quantities and cost redaction.
//

import Foundation
import XCTest
@testable import Nexo_Admin

final class AdminPurchaseOrderMapperTests: XCTestCase {
    func testFullOrderMapsBackendTotalsAndReceiptProgressWithoutRecalculation() throws {
        let order = try makeDTO().toDomain()

        XCTAssertEqual(order.status, .partiallyReceived)
        XCTAssertEqual(order.orderNumber, "PO-260721-000001")
        XCTAssertEqual(order.supplierSnapshot.displayName, "Proveedor Uno")
        XCTAssertEqual(order.lines.first?.orderedQuantity.value, Decimal(10))
        XCTAssertEqual(order.lines.first?.receivedQuantity, Decimal(4))
        XCTAssertEqual(order.total?.amount, Decimal(string: "112.00"))
        XCTAssertTrue(order.costsVisible)
        XCTAssertEqual(order.lines.first?.taxes?.first?.rate, Decimal(string: "0.12"))
    }

    func testRedactedOrderPreservesOperationalFieldsAndNilCosts() throws {
        let order = try makeDTO(costsVisible: false, sensitiveSupplier: false).toDomain()

        XCTAssertFalse(order.costsVisible)
        XCTAssertNil(order.total)
        XCTAssertNil(order.lines.first?.unitCost)
        XCTAssertNil(order.lines.first?.taxes)
        XCTAssertNil(order.supplierSnapshot.identificationNumber)
        XCTAssertEqual(order.lines.first?.receivedQuantity, Decimal(4))
    }

    func testPartialOrderCostRedactionIsRejected() {
        XCTAssertThrowsError(try makeDTO(partialOrderCosts: true).toDomain())
    }

    func testPartialLineCostRedactionIsRejected() {
        XCTAssertThrowsError(try makeDTO(partialLineCosts: true).toDomain())
    }

    func testUnsupportedStatusIsRejected() {
        XCTAssertThrowsError(try makeDTO(status: "APPROVED").toDomain())
    }

    private func makeDTO(
        costsVisible: Bool = true,
        sensitiveSupplier: Bool = true,
        partialOrderCosts: Bool = false,
        partialLineCosts: Bool = false,
        status: String = "PARTIALLY_RECEIVED"
    ) -> AdminPurchaseOrderDTO {
        let money: (String) -> AdminProcurementMoneyDTO = {
            AdminProcurementMoneyDTO(amount: $0, currency: "USD")
        }
        let line = AdminPurchaseOrderLineDTO(
            id: "pol_1",
            kind: "STOCK_ITEM",
            catalogItemId: "item_1",
            catalogItemSnapshot: AdminPurchaseItemSnapshotDTO(
                catalogItemId: "item_1",
                localName: "Café de prueba",
                sku: "CAF-001",
                unitCode: "UNIT",
                taxProfileId: "tax_1",
                taxProfileVersion: 2
            ),
            descriptionSnapshot: "Café de prueba",
            orderedQuantity: AdminPurchaseQuantityDTO(value: "10", unitCode: "UNIT", allowsDecimal: false),
            receivedQuantity: "4.000000",
            unitCost: costsVisible && !partialLineCosts ? money("10.00") : nil,
            discountAmount: costsVisible ? money("0.00") : nil,
            priceTaxMode: "TAX_EXCLUSIVE",
            taxProfileId: "tax_1",
            taxProfileVersion: 2,
            taxes: costsVisible ? [
                AdminPurchaseTaxDTO(
                    taxCode: "IVA",
                    rateCode: "IVA_12",
                    rate: "0.12",
                    taxableBase: money("100.00"),
                    amount: money("12.00")
                )
            ] : nil,
            grossAmount: costsVisible ? money("100.00") : nil,
            netAmount: costsVisible ? money("100.00") : nil,
            taxAmount: costsVisible ? money("12.00") : nil,
            lineTotal: costsVisible ? money("112.00") : nil,
            targetWarehouseId: "wh_1",
            notes: nil
        )
        let terms = AdminSupplierPaymentTermsDTO(mode: "NET_DAYS", netDays: 30, label: nil, notes: nil)

        return AdminPurchaseOrderDTO(
            id: "po_1",
            branchId: "br_1",
            supplierId: "sup_1",
            orderNumber: "PO-260721-000001",
            status: status,
            currency: "USD",
            lines: [line],
            subtotal: costsVisible ? money("100.00") : nil,
            discountTotal: costsVisible ? money("0.00") : nil,
            taxTotal: costsVisible ? money("12.00") : nil,
            total: costsVisible && !partialOrderCosts ? money("112.00") : nil,
            expectedDate: "2026-07-25",
            supplierSnapshot: AdminPurchaseSupplierSnapshotDTO(
                supplierId: "sup_1",
                legalName: "Proveedor Uno S.A.",
                tradeName: "Proveedor Uno",
                identificationType: sensitiveSupplier ? "RUC" : nil,
                identificationNumber: sensitiveSupplier ? "1799999999001" : nil,
                paymentTerms: terms,
                defaultCurrency: "USD"
            ),
            paymentTermsSnapshot: terms,
            notes: nil,
            attachmentIds: ["att_1"],
            createdAt: "2026-07-20T12:00:00Z",
            createdBy: "usr_create",
            updatedAt: "2026-07-21T14:00:00Z",
            updatedBy: "usr_update",
            sentAt: "2026-07-20T13:00:00Z",
            sentBy: "usr_send",
            closedAt: nil,
            closedBy: nil,
            closeReason: nil,
            cancelledAt: nil,
            cancelledBy: nil,
            cancellationReason: nil,
            version: 4
        )
    }
}
