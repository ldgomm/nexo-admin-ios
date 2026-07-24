//
//  AdminSupplierContractTests.swift
//  Nexo AdminTests
//
//  27R.N.2 — Supplier wire and permission contract.
//

import Foundation
import XCTest
@testable import Nexo_Admin

final class AdminSupplierContractTests: XCTestCase {
    func testRoutesStayInsideExactAdminProcurementNamespace() {
        XCTAssertEqual(AdminProcurementRoutes.suppliers, "/api/v1/admin/procurement/suppliers")
        XCTAssertEqual(
            AdminProcurementRoutes.supplier("sup/one ?"),
            "/api/v1/admin/procurement/suppliers/sup%2Fone%20%3F"
        )
        XCTAssertEqual(
            AdminProcurementRoutes.supplierStatus("sup_1"),
            "/api/v1/admin/procurement/suppliers/sup_1/status"
        )
    }

    func testPermissionConstantsMatchServerWireContract() {
        XCTAssertEqual(PermissionCatalog.suppliersView, "suppliers.view")
        XCTAssertEqual(PermissionCatalog.suppliersSensitiveView, "suppliers.sensitive_view")
        XCTAssertEqual(PermissionCatalog.suppliersCreate, "suppliers.create")
        XCTAssertEqual(PermissionCatalog.suppliersUpdate, "suppliers.update")
        XCTAssertEqual(PermissionCatalog.suppliersStatusManage, "suppliers.status_manage")
    }

    func testWriteMappingSortsCategoriesAndPreservesExpectedVersion() throws {
        let input = AdminSupplierWriteInput(
            legalName: "  Proveedor Uno S.A.  ",
            tradeName: " Proveedor Uno ",
            identificationType: .ruc,
            identificationNumber: " 1799999999001 ",
            email: " compras@example.test ",
            phone: "",
            address: " Quito ",
            categories: [" Retail ", "insumos", "retail"],
            contacts: [],
            paymentTermsMode: .netDays,
            netDays: 30,
            paymentTermsLabel: "ignored",
            paymentTermsNotes: " Crédito aprobado ",
            notes: " Interno ",
            expectedVersion: 7,
            idempotencyKey: "idem_1"
        )

        let data = try JSONEncoder().encode(input.toDTO())
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])

        XCTAssertEqual(object["legalName"] as? String, "Proveedor Uno S.A.")
        XCTAssertEqual(object["categories"] as? [String], ["insumos", "retail"])
        XCTAssertEqual(object["defaultCurrency"] as? String, "USD")
        XCTAssertEqual((object["paymentTerms"] as? [String: Any])?["mode"] as? String, "NET_DAYS")
        XCTAssertEqual(object["expectedVersion"] as? Int, 7)
    }

    func testListMappingClampsLimitAndUsesExactStatus() {
        let dto = AdminSupplierListQuery(
            query: " proveedor ",
            status: .blocked,
            category: " insumos ",
            limit: 500,
            cursor: " cursor_1 "
        ).toDTO()

        XCTAssertEqual(dto.query, "proveedor")
        XCTAssertEqual(dto.status, "BLOCKED")
        XCTAssertEqual(dto.category, "insumos")
        XCTAssertEqual(dto.limit, 100)
        XCTAssertEqual(dto.cursor, "cursor_1")
    }
}
