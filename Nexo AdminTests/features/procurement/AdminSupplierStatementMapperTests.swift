//
//  AdminSupplierStatementMapperTests.swift
//  Nexo AdminTests
//
//  Created by José Ruiz on 29/7/26.
//
//  27R.N — Canonical balances, money, source types and pagination mapping.
//

import Foundation
import XCTest
@testable import Nexo_Admin

class AdminSupplierStatementMapperTests: XCTestCase {
    func testMapsCanonicalStatementWithoutRecalculatingServerBalances() throws {
        let statement = try response().toDomain()

        XCTAssertEqual(statement.supplierId, "sup_1")
        XCTAssertEqual(statement.branchId, "br_1")
        XCTAssertEqual(statement.currency, "USD")
        XCTAssertEqual(statement.openingBalance.amount, Decimal(string: "10.00"))
        XCTAssertEqual(statement.lines.map(\.id), ["stmt_1", "stmt_2"])
        XCTAssertEqual(statement.lines[0].sourceType, .supplierDocument)
        XCTAssertEqual(statement.lines[1].sourceType, .paymentAllocation)
        XCTAssertEqual(statement.lines[1].runningBalance.amount, Decimal(string: "80.00"))
        XCTAssertEqual(statement.closingBalance.amount, Decimal(string: "80.00"))
        XCTAssertTrue(statement.hasMore)
        XCTAssertEqual(statement.nextCursor, "cursor_2")
    }

    func testRejectsClosingBalanceThatDiffersFromLastCanonicalRunningBalance() {
        XCTAssertThrowsError(
            try response(closingAmount: "79.99").toDomain()
        )
    }

    func testRejectsDuplicateLinesAndUnsupportedSourceTypes() {
        let duplicate = line(id: "stmt_1", sourceType: "SUPPLIER_DOCUMENT")
        XCTAssertThrowsError(
            try response(lines: [duplicate, duplicate], closingAmount: "110.00").toDomain()
        )

        XCTAssertThrowsError(
            try response(
                lines: [line(id: "stmt_1", sourceType: "UNKNOWN_EVENT")],
                closingAmount: "110.00"
            ).toDomain()
        )
    }

    func testRejectsMixedCurrencyAndInvalidPaginationPair() {
        XCTAssertThrowsError(
            try response(
                lines: [line(id: "stmt_1", sourceType: "SUPPLIER_DOCUMENT", currency: "EUR")],
                closingAmount: "110.00"
            ).toDomain()
        )
        XCTAssertThrowsError(
            try response(nextCursor: nil, hasMore: true).toDomain()
        )
    }

    private func response(
        lines: [AdminSupplierStatementLineDTO]? = nil,
        closingAmount: String = "80.00",
        nextCursor: String? = "cursor_2",
        hasMore: Bool = true
    ) -> AdminSupplierStatementResponseDTO {
        AdminSupplierStatementResponseDTO(
            supplierId: "sup_1",
            branchId: "br_1",
            currency: "USD",
            from: "2026-07-01",
            to: "2026-07-31",
            asOf: "2026-07-31",
            openingBalance: money("10.00"),
            lines: lines ?? [
                line(
                    id: "stmt_1",
                    sourceType: "SUPPLIER_DOCUMENT",
                    charge: "100.00",
                    credit: "0.00",
                    running: "110.00"
                ),
                line(
                    id: "stmt_2",
                    sourceType: "PAYMENT_ALLOCATION",
                    charge: "0.00",
                    credit: "30.00",
                    running: "80.00"
                )
            ],
            closingBalance: money(closingAmount),
            nextCursor: nextCursor,
            hasMore: hasMore
        )
    }

    private func line(
        id: String,
        sourceType: String,
        currency: String = "USD",
        charge: String = "100.00",
        credit: String = "0.00",
        running: String = "110.00"
    ) -> AdminSupplierStatementLineDTO {
        AdminSupplierStatementLineDTO(
            id: id,
            occurredAt: "2026-07-24T15:00:00Z",
            sourceType: sourceType,
            sourceId: "source_\(id)",
            description: "Movimiento \(id)",
            charge: money(charge, currency: currency),
            credit: money(credit, currency: currency),
            runningBalance: money(running, currency: currency),
            currency: currency,
            auditResourceType: "supplier_document",
            auditResourceId: "audit_\(id)"
        )
    }

    private func money(
        _ amount: String,
        currency: String = "USD"
    ) -> AdminProcurementMoneyDTO {
        AdminProcurementMoneyDTO(amount: amount, currency: currency)
    }
}
