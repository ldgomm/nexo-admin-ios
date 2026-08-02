//
//  AdminSupplierMapperTests.swift
//  Nexo AdminTests
//
//  Created by José Ruiz on 29/7/26.
//
//  27R.N.2 — Supplier response mapping.
//

import XCTest
@testable import Nexo_Admin

class AdminSupplierMapperTests: XCTestCase {
    func testFullSupplierMapsSensitiveFieldsAndPaymentTerms() throws {
        let supplier = try makeDTO().toDomain()

        XCTAssertEqual(supplier.id, "sup_1")
        XCTAssertEqual(supplier.status, .active)
        XCTAssertEqual(supplier.identificationType, .ruc)
        XCTAssertEqual(supplier.identificationNumber, "1799999999001")
        XCTAssertEqual(supplier.categories, ["insumos", "retail"])
        XCTAssertEqual(supplier.contacts?.first?.id, "scon_1")
        XCTAssertEqual(supplier.paymentTerms.mode, .netDays)
        XCTAssertEqual(supplier.paymentTerms.netDays, 30)
        XCTAssertTrue(supplier.sensitiveFieldsAvailable)
    }

    func testRedactedSupplierPreservesNilSensitiveBoundary() throws {
        let supplier = try makeDTO(
            identificationNumber: nil,
            email: nil,
            phone: nil,
            address: nil,
            contacts: nil,
            notes: nil
        ).toDomain()

        XCTAssertEqual(supplier.identificationType, .ruc)
        XCTAssertNil(supplier.identificationNumber)
        XCTAssertNil(supplier.contacts)
        XCTAssertFalse(supplier.sensitiveFieldsAvailable)
    }

    func testUnknownServerEnumFailsClosed() {
        XCTAssertThrowsError(try makeDTO(status: "DELETED").toDomain())
        XCTAssertThrowsError(try makeDTO(paymentMode: "MONTH_END").toDomain())
    }

    func testEnvelopePreservesIdempotencyReplayMetadata() throws {
        let result = try AdminSupplierEnvelopeDTO(
            data: makeDTO(),
            meta: AdminSupplierResponseMetaDTO(
                requestId: "req_1",
                idempotencyReplayed: true
            )
        ).toDomain()

        XCTAssertEqual(result.supplier.id, "sup_1")
        XCTAssertEqual(result.requestId, "req_1")
        XCTAssertEqual(result.idempotencyReplayed, true)
    }

    private func makeDTO(
        status: String = "ACTIVE",
        identificationNumber: String? = "1799999999001",
        email: String? = "compras@example.test",
        phone: String? = "022000000",
        address: String? = "Quito",
        contacts: [AdminSupplierContactDTO]? = [
            AdminSupplierContactDTO(
                id: "scon_1",
                name: "Ana Proveedor",
                role: "Ventas",
                email: "ana@example.test",
                phone: "0990000000",
                isPrimary: true,
                notes: nil
            )
        ],
        notes: String? = "Interno",
        paymentMode: String = "NET_DAYS"
    ) -> AdminSupplierDTO {
        AdminSupplierDTO(
            id: "sup_1",
            legalName: "Proveedor Uno S.A.",
            tradeName: "Proveedor Uno",
            identificationType: "RUC",
            identificationNumber: identificationNumber,
            email: email,
            phone: phone,
            address: address,
            categories: ["retail", "insumos"],
            contacts: contacts,
            paymentTerms: AdminSupplierPaymentTermsDTO(
                mode: paymentMode,
                netDays: paymentMode == "NET_DAYS" ? 30 : nil,
                label: nil,
                notes: nil
            ),
            defaultCurrency: "USD",
            status: status,
            notes: notes,
            createdAt: "2026-07-14T12:00:00Z",
            createdBy: "usr_create",
            updatedAt: "2026-07-21T12:00:00Z",
            updatedBy: "usr_update",
            version: 2
        )
    }
}
