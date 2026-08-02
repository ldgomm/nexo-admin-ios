//
//  AdminSupplierPaymentMapperTests.swift
//  Nexo AdminTests
//
//  Created by José Ruiz on 29/7/26.
//
//  27R.N — Supplier-payment mapping, money and lifecycle reconciliation.
//

import Foundation
import XCTest
@testable import Nexo_Admin

class AdminSupplierPaymentMapperTests: XCTestCase {
    func testRecordedPaymentMapsCanonicalMoneyAllocationsAndSensitiveFields() throws {
        let payment = try AdminSupplierPaymentDTO.fixture().toDomain()

        XCTAssertEqual(payment.id, "spay_1")
        XCTAssertEqual(payment.status, .recorded)
        XCTAssertEqual(payment.amount.amount, Decimal(string: "50.00"))
        XCTAssertEqual(payment.amount.currency, "USD")
        XCTAssertEqual(payment.method, .bankTransfer)
        XCTAssertEqual(payment.reference, "TRX-001")
        XCTAssertEqual(payment.allocations.first?.status, .applied)
        XCTAssertEqual(payment.allocations.first?.payableBalanceAfter.amount, Decimal(string: "62.00"))
        XCTAssertEqual(payment.version, 2)
    }

    func testVoidedPaymentRequiresReversedAllocationsAndVoidEvidence() throws {
        let payment = try AdminSupplierPaymentDTO.fixture(
            status: "VOIDED",
            allocations: [.fixture(status: "REVERSED")],
            voidedAt: "2026-07-24T16:00:00Z",
            voidedBy: "usr_void",
            voidReason: "Pago duplicado",
            version: 3
        ).toDomain()

        XCTAssertEqual(payment.status, .voided)
        XCTAssertEqual(payment.allocations.first?.status, .reversed)
        XCTAssertEqual(payment.voidedBy, "usr_void")
        XCTAssertEqual(payment.voidReason, "Pago duplicado")
    }

    func testRedactedPaymentAllowsAbsentSensitiveFieldsWithoutInventingValues() throws {
        let payment = try AdminSupplierPaymentDTO.fixture(
            method: nil,
            reference: nil,
            attachmentIds: nil,
            cashMovementId: nil,
            notes: nil
        ).toDomain()

        XCTAssertNil(payment.method)
        XCTAssertNil(payment.reference)
        XCTAssertNil(payment.attachmentIds)
        XCTAssertNil(payment.cashMovementId)
        XCTAssertNil(payment.notes)
    }

    func testPaymentRejectsAllocationTotalMismatch() {
        let dto = AdminSupplierPaymentDTO.fixture(
            amount: "51.00",
            allocations: [.fixture(amount: "50.00")]
        )

        XCTAssertThrowsError(try dto.toDomain())
    }

    func testPaymentRejectsDuplicatePayableAllocations() {
        let first = AdminSupplierPaymentAllocationDTO.fixture(id: "palloc_1", payableId: "pbl_1")
        let second = AdminSupplierPaymentAllocationDTO.fixture(
            id: "palloc_2",
            payableId: "pbl_1",
            amount: "50.00"
        )
        let dto = AdminSupplierPaymentDTO.fixture(
            amount: "100.00",
            allocations: [first, second]
        )

        XCTAssertThrowsError(try dto.toDomain())
    }

    func testRecordedPaymentRejectsMissingRecordedEvidence() {
        let dto = AdminSupplierPaymentDTO.fixture(recordedAt: nil, recordedBy: nil)

        XCTAssertThrowsError(try dto.toDomain())
    }

    func testAppliedAllocationRejectsReversalEvidence() {
        let dto = AdminSupplierPaymentDTO.fixture(
            allocations: [
                .fixture(
                    status: "APPLIED",
                    reversedAt: "2026-07-24T16:00:00Z",
                    reversedBy: "usr_void",
                    reversalReason: "Duplicado"
                )
            ]
        )

        XCTAssertThrowsError(try dto.toDomain())
    }

    func testEnvelopeAndPagePreserveMetaAndCursor() throws {
        let envelope = try AdminSupplierPaymentEnvelopeDTO(
            data: .fixture(),
            meta: AdminSupplierPaymentResponseMetaDTO(
                requestId: "req_1",
                idempotencyReplayed: true
            )
        ).toMutationDomain()
        let page = try AdminSupplierPaymentListResponseDTO(
            supplierPayments: [.fixture()],
            nextCursor: " cursor_2 ",
            hasMore: true
        ).toDomain()

        XCTAssertEqual(envelope.supplierPayment.id, "spay_1")
        XCTAssertEqual(envelope.requestId, "req_1")
        XCTAssertEqual(envelope.idempotencyReplayed, true)
        XCTAssertEqual(page.supplierPayments.map(\.id), ["spay_1"])
        XCTAssertEqual(page.nextCursor, "cursor_2")
        XCTAssertTrue(page.hasMore)
    }
}

private extension AdminSupplierPaymentDTO {
    static func fixture(
        amount: String = "50.00",
        method: String? = "BANK_TRANSFER",
        reference: String? = "TRX-001",
        status: String = "RECORDED",
        allocations: [AdminSupplierPaymentAllocationDTO] = [.fixture()],
        attachmentIds: [String]? = ["patt_1"],
        cashMovementId: String? = "cmov_1",
        notes: String? = "Pago de prueba",
        recordedAt: String? = "2026-07-24T15:00:00Z",
        recordedBy: String? = "usr_record",
        voidedAt: String? = nil,
        voidedBy: String? = nil,
        voidReason: String? = nil,
        version: Int64 = 2
    ) -> AdminSupplierPaymentDTO {
        AdminSupplierPaymentDTO(
            id: "spay_1",
            branchId: "br_1",
            supplierId: "sup_1",
            paymentNumber: "SP-202607-000001",
            paymentDate: "2026-07-24",
            currency: "USD",
            amount: money(amount),
            method: method,
            reference: reference,
            status: status,
            allocations: allocations,
            attachmentIds: attachmentIds,
            cashMovementId: cashMovementId,
            notes: notes,
            createdAt: "2026-07-24T13:00:00Z",
            createdBy: "usr_create",
            updatedAt: voidedAt ?? "2026-07-24T15:00:00Z",
            updatedBy: voidedBy ?? "usr_record",
            recordedAt: recordedAt,
            recordedBy: recordedBy,
            voidedAt: voidedAt,
            voidedBy: voidedBy,
            voidReason: voidReason,
            version: version
        )
    }

    static func money(_ amount: String) -> AdminProcurementMoneyDTO {
        AdminProcurementMoneyDTO(amount: amount, currency: "USD")
    }
}

private extension AdminSupplierPaymentAllocationDTO {
    static func fixture(
        id: String = "palloc_1",
        payableId: String = "pbl_1",
        amount: String = "50.00",
        status: String = "APPLIED",
        reversedAt: String? = nil,
        reversedBy: String? = nil,
        reversalReason: String? = nil
    ) -> AdminSupplierPaymentAllocationDTO {
        let effectiveReversedAt = status == "REVERSED"
            ? (reversedAt ?? "2026-07-24T16:00:00Z")
            : reversedAt
        let effectiveReversedBy = status == "REVERSED"
            ? (reversedBy ?? "usr_void")
            : reversedBy
        let effectiveReason = status == "REVERSED"
            ? (reversalReason ?? "Pago duplicado")
            : reversalReason
        return AdminSupplierPaymentAllocationDTO(
            id: id,
            payableId: payableId,
            amount: AdminSupplierPaymentDTO.money(amount),
            payableBalanceBefore: AdminSupplierPaymentDTO.money("112.00"),
            payableBalanceAfter: AdminSupplierPaymentDTO.money("62.00"),
            status: status,
            createdAt: "2026-07-24T14:00:00Z",
            createdBy: "usr_record",
            reversedAt: effectiveReversedAt,
            reversedBy: effectiveReversedBy,
            reversalReason: effectiveReason
        )
    }
}
