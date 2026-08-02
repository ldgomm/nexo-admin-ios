//
//  AdminPayableMapperTests.swift
//  Nexo AdminTests
//
//  Created by José Ruiz on 29/7/26.
//
//  27R.N — Payable amount, currency, status and ageing mapping.
//

import Foundation
import XCTest
@testable import Nexo_Admin

class AdminPayableMapperTests: XCTestCase {
    func testPayableMapsCanonicalBackendAmountsStatusDatesAndEvidence() throws {
        let payable = try makeDTO().toDomain()

        XCTAssertEqual(payable.id, "pbl_1")
        XCTAssertEqual(payable.sourceType, "SUPPLIER_DOCUMENT")
        XCTAssertEqual(payable.originalAmount.amount, Decimal(string: "112.00"))
        XCTAssertEqual(payable.paidAmount.amount, Decimal(string: "50.00"))
        XCTAssertEqual(payable.balance.amount, Decimal(string: "62.00"))
        XCTAssertEqual(payable.currency, "USD")
        XCTAssertEqual(payable.dueDate, "2026-08-15")
        XCTAssertEqual(payable.settlementStatus, .partiallyPaid)
        XCTAssertEqual(payable.effectiveStatus, .partiallyPaid)
        XCTAssertEqual(payable.allocationIds, ["palloc_1"])
        XCTAssertEqual(payable.version, 2)
    }

    func testListEnvelopeAndAgingMapExactBackendCutoffAndBuckets() throws {
        let page = try AdminPayableListResponseDTO(
            payables: [makeDTO()],
            nextCursor: "cursor_2",
            hasMore: true,
            asOf: "2026-07-24"
        ).toDomain()
        let envelope = try AdminPayableEnvelopeDTO(
            data: makeDTO(),
            meta: AdminPayableResponseMetaDTO(requestId: "req_1", idempotencyReplayed: false)
        ).toDomain()
        let aging = try AdminPayableAgingResponseDTO(
            currency: "USD",
            asOf: "2026-07-24",
            buckets: [
                bucket(.current, count: 1, balance: "62.00"),
                bucket(.due1To30, count: 2, balance: "30.00"),
                bucket(.due31To60, count: 0, balance: "0.00"),
                bucket(.due61To90, count: 0, balance: "0.00"),
                bucket(.due91Plus, count: 0, balance: "0.00"),
                bucket(.noDueDate, count: 0, balance: "0.00")
            ]
        ).toDomain()

        XCTAssertEqual(page.payables.map(\.id), ["pbl_1"])
        XCTAssertEqual(page.nextCursor, "cursor_2")
        XCTAssertTrue(page.hasMore)
        XCTAssertEqual(page.asOf, "2026-07-24")
        XCTAssertEqual(envelope.requestId, "req_1")
        XCTAssertEqual(envelope.idempotencyReplayed, false)
        XCTAssertEqual(aging.currency, "USD")
        XCTAssertEqual(aging.asOf, "2026-07-24")
        XCTAssertEqual(aging.buckets.map(\.code), AdminPayableAgingBucketCode.allCases)
        XCTAssertEqual(aging.buckets[1].balance.amount, Decimal(string: "30.00"))
    }

    func testCurrencyAndBalanceReconciliationMismatchesAreRejected() {
        XCTAssertThrowsError(try makeDTO(balanceCurrency: "EUR").toDomain())
        XCTAssertThrowsError(try makeDTO(balance: "61.99").toDomain())
    }

    func testUnsupportedStatusesInvalidDatesAndDuplicateAllocationsAreRejected() {
        XCTAssertThrowsError(try makeDTO(settlementStatus: "VOIDED").toDomain())
        XCTAssertThrowsError(try makeDTO(effectiveStatus: "DUE_SOON").toDomain())
        XCTAssertThrowsError(try makeDTO(dueDate: "15/08/2026").toDomain())
        XCTAssertThrowsError(try makeDTO(allocationIds: ["palloc_1", "palloc_1"]).toDomain())
    }

    func testAgingRejectsUnknownOrRepeatedBucketsAndNegativeCounts() {
        let unknown = AdminPayableAgingResponseDTO(
            currency: "USD",
            asOf: "2026-07-24",
            buckets: [AdminPayableAgingBucketDTO(code: "FUTURE", count: 1, balance: money("1.00"))]
        )
        let repeated = AdminPayableAgingResponseDTO(
            currency: "USD",
            asOf: "2026-07-24",
            buckets: [bucket(.current, count: 1, balance: "1.00"), bucket(.current, count: 1, balance: "1.00")]
        )
        let negative = AdminPayableAgingResponseDTO(
            currency: "USD",
            asOf: "2026-07-24",
            buckets: [bucket(.current, count: -1, balance: "1.00")]
        )

        XCTAssertThrowsError(try unknown.toDomain())
        XCTAssertThrowsError(try repeated.toDomain())
        XCTAssertThrowsError(try negative.toDomain())
    }

    private func makeDTO(
        settlementStatus: String = "PARTIALLY_PAID",
        effectiveStatus: String = "PARTIALLY_PAID",
        dueDate: String = "2026-08-15",
        balance: String = "62.00",
        balanceCurrency: String = "USD",
        allocationIds: [String] = ["palloc_1"]
    ) -> AdminPayableDTO {
        AdminPayableDTO(
            id: "pbl_1",
            branchId: "br_1",
            supplierId: "sup_1",
            sourceType: "SUPPLIER_DOCUMENT",
            sourceId: "sdoc_1",
            currency: "USD",
            originalAmount: money("112.00"),
            paidAmount: money("50.00"),
            balance: money(balance, currency: balanceCurrency),
            dueDate: dueDate,
            settlementStatus: settlementStatus,
            effectiveStatus: effectiveStatus,
            allocationIds: allocationIds,
            createdAt: "2026-07-23T14:00:00Z",
            createdBy: "usr_create",
            updatedAt: "2026-07-24T15:00:00Z",
            updatedBy: "usr_update",
            version: 2
        )
    }

    private func bucket(
        _ code: AdminPayableAgingBucketCode,
        count: Int64,
        balance: String
    ) -> AdminPayableAgingBucketDTO {
        AdminPayableAgingBucketDTO(code: code.rawValue, count: count, balance: money(balance))
    }

    private func money(_ amount: String, currency: String = "USD") -> AdminProcurementMoneyDTO {
        AdminProcurementMoneyDTO(amount: amount, currency: currency)
    }
}
