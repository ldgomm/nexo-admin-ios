//
//  AdminSupplierDocumentMapperTests.swift
//  Nexo AdminTests
//
//  Created by José Ruiz on 29/7/26.
//
//  27R.N — Supplier document money, tax, source and audit mapping.
//

import Foundation
import XCTest
@testable import Nexo_Admin

class AdminSupplierDocumentMapperTests: XCTestCase {
    func testDocumentMapsBackendAmountsTaxesLinksAndEvidenceWithoutRecalculation() throws {
        let document = try makeDTO().toDomain()

        XCTAssertEqual(document.documentType, .supplierInvoice)
        XCTAssertEqual(document.status, .confirmed)
        XCTAssertEqual(document.documentNumber, "FAC-001-001-000000123")
        XCTAssertEqual(document.total.amount, Decimal(string: "112.00"))
        XCTAssertEqual(document.payableAmount.amount, Decimal(string: "80.00"))
        XCTAssertEqual(document.sourcePayment?.amount.amount, Decimal(string: "32.00"))
        XCTAssertEqual(document.lines.first?.quantity.value, Decimal(10))
        XCTAssertEqual(document.lines.first?.taxes.first?.rate, Decimal(string: "0.12"))
        XCTAssertEqual(document.purchaseOrderIds, ["po_1"])
        XCTAssertEqual(document.purchaseReceiptIds, ["pr_1"])
        XCTAssertEqual(document.accountingStatus, .futureReview)
    }

    func testMoneyCurrencyMismatchIsRejected() {
        XCTAssertThrowsError(try makeDTO(lineCurrency: "EUR").toDomain())
    }

    func testUnsupportedWireEnumsAreRejected() {
        XCTAssertThrowsError(try makeDTO(documentType: "CREDIT_NOTE").toDomain())
        XCTAssertThrowsError(try makeDTO(status: "POSTED").toDomain())
        XCTAssertThrowsError(try makeDTO(accountingStatus: "APPROVED").toDomain())
    }

    func testNonPositiveQuantityIsRejected() {
        XCTAssertThrowsError(try makeDTO(quantity: "0").toDomain())
    }

    private func makeDTO(
        documentType: String = "SUPPLIER_INVOICE",
        status: String = "CONFIRMED",
        accountingStatus: String = "FUTURE_REVIEW",
        lineCurrency: String = "USD",
        quantity: String = "10"
    ) -> AdminSupplierDocumentDTO {
        let money: (String, String) -> AdminProcurementMoneyDTO = {
            AdminProcurementMoneyDTO(amount: $0, currency: $1)
        }
        let usd: (String) -> AdminProcurementMoneyDTO = { money($0, "USD") }
        let line = AdminSupplierDocumentLineDTO(
            id: "sdl_1",
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
            purchaseOrderLineId: "pol_1",
            purchaseReceiptLineId: "prl_1",
            descriptionSnapshot: "Café de prueba",
            quantity: AdminPurchaseQuantityDTO(value: quantity, unitCode: "UNIT", allowsDecimal: false),
            unitCost: money("10.00", lineCurrency),
            discountAmount: usd("0.00"),
            priceTaxMode: "TAX_EXCLUSIVE",
            taxProfileId: "tax_1",
            taxProfileVersion: 2,
            taxes: [
                AdminPurchaseTaxDTO(
                    taxCode: "IVA",
                    rateCode: "IVA_12",
                    rate: "0.12",
                    taxableBase: usd("100.00"),
                    amount: usd("12.00")
                )
            ],
            grossAmount: usd("100.00"),
            netAmount: usd("100.00"),
            taxAmount: usd("12.00"),
            lineTotal: usd("112.00"),
            expenseCategoryCode: nil,
            notes: nil
        )

        return AdminSupplierDocumentDTO(
            id: "sdoc_1",
            branchId: "br_1",
            supplierId: "sup_1",
            documentType: documentType,
            status: status,
            documentNumber: "FAC-001-001-000000123",
            documentNumberNormalized: "FAC001001000000123",
            accessKey: "access-key-metadata",
            authorizationNumber: "auth-metadata",
            documentDate: "2026-07-23",
            dueDate: "2026-08-22",
            currency: "USD",
            purchaseOrderIds: ["po_1"],
            purchaseReceiptIds: ["pr_1"],
            lines: [line],
            subtotal: usd("100.00"),
            discountTotal: usd("0.00"),
            taxTotal: usd("12.00"),
            total: usd("112.00"),
            sourceTotals: AdminSupplierDocumentSourceTotalsDTO(
                total: usd("112.00"),
                taxTotal: usd("12.00")
            ),
            sourcePayment: AdminSupplierDocumentSourcePaymentDTO(
                amount: usd("32.00"),
                method: "BANK_TRANSFER",
                paymentDate: "2026-07-23",
                reference: "TRX-001"
            ),
            payableAmount: usd("80.00"),
            payableId: "pay_1",
            attachmentIds: ["att_1"],
            accountingStatus: accountingStatus,
            notes: "Documento recibido",
            createdAt: "2026-07-23T14:00:00Z",
            createdBy: "usr_create",
            updatedAt: "2026-07-23T15:00:00Z",
            updatedBy: "usr_confirm",
            confirmedAt: "2026-07-23T15:00:00Z",
            confirmedBy: "usr_confirm",
            cancelledAt: nil,
            cancelledBy: nil,
            cancellationReason: nil,
            version: 3
        )
    }
}
