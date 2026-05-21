//
//  AdminCatalogViewModelTests.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import XCTest
@testable import Nexo_Admin

@MainActor
final class AdminCatalogViewModelTests: XCTestCase {
    func testLoadGetsLocalItemsAndRequests() async {
        let repository = AdminCatalogTestRepository()
        let viewModel = AdminCatalogViewModel(repository: repository)

        await viewModel.load()

        XCTAssertEqual(viewModel.localItems.count, 2)
        XCTAssertEqual(viewModel.requests.count, 1)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testUpdateItemRequiresReason() async {
        let repository = AdminCatalogTestRepository()
        let viewModel = AdminCatalogViewModel(repository: repository)
        await viewModel.load()

        let ok = await viewModel.updateItem(
            SaveAdminCatalogLocalItemInput(
                id: "ocat_cuy_entero",
                localName: "Cuy completo",
                localPrice: nil,
                taxProfileCode: nil,
                identifiers: nil,
                status: nil,
                reason: ""
            )
        )

        XCTAssertFalse(ok)
        XCTAssertNotNil(viewModel.errorMessage)
    }

    func testUpdateItemReplacesLocalItem() async {
        let repository = AdminCatalogTestRepository()
        let viewModel = AdminCatalogViewModel(repository: repository)
        await viewModel.load()

        let ok = await viewModel.updateItem(
            SaveAdminCatalogLocalItemInput(
                id: "ocat_cuy_entero",
                localName: "Cuy completo",
                localPrice: AdminCatalogMoney(amount: 25),
                taxProfileCode: "iva_current_full",
                identifiers: nil,
                status: nil,
                reason: "Cambio de precio"
            )
        )

        XCTAssertTrue(ok)
        XCTAssertEqual(viewModel.localItems.first(where: { $0.id == "ocat_cuy_entero" })?.localName, "Cuy completo")
        XCTAssertEqual(viewModel.successMessage, "Ítem de catálogo actualizado.")
    }

    func testSearchMasterLoadsTemplates() async {
        let repository = AdminCatalogTestRepository()
        let viewModel = AdminCatalogViewModel(repository: repository)

        await viewModel.searchMaster()

        XCTAssertEqual(viewModel.masterTemplates.count, 2)
    }

    func testCopyTemplateAddsLocalItem() async {
        let repository = AdminCatalogTestRepository(localItems: [])
        let viewModel = AdminCatalogViewModel(repository: repository)

        let ok = await viewModel.copyTemplate(
            CopyAdminCatalogTemplateInput(
                templateId: "tpl_cuy_entero",
                branchId: "br_main",
                activityId: "act_restaurant",
                localPrice: AdminCatalogMoney(amount: 24),
                taxProfileCode: "iva_current_full",
                reason: "Preparar menú"
            )
        )

        XCTAssertTrue(ok)
        XCTAssertEqual(viewModel.localItems.count, 1)
        XCTAssertEqual(viewModel.localItems.first?.templateId, "tpl_cuy_entero")
    }

    func testCreateRequestAddsRequest() async {
        let repository = AdminCatalogTestRepository(requests: [])
        let viewModel = AdminCatalogViewModel(repository: repository)

        let ok = await viewModel.createRequest(
            CreateAdminCatalogRequestInput(
                requestedName: "Extreme slide",
                requestedType: "SERVICE",
                description: "Nueva experiencia",
                suggestedCategoryId: nil,
                suggestedTaxProfileCode: "iva_current_full",
                identifiers: []
            )
        )

        XCTAssertTrue(ok)
        XCTAssertEqual(viewModel.requests.count, 1)
        XCTAssertEqual(viewModel.requests.first?.requestedName, "Extreme slide")
    }

    func testStatusTransitionsUpdateItem() async {
        let repository = AdminCatalogTestRepository()
        let viewModel = AdminCatalogViewModel(repository: repository)
        await viewModel.load()
        let item = viewModel.localItems.first!

        let ok = await viewModel.deactivateItem(item, reason: "Pausar temporalmente")

        XCTAssertTrue(ok)
        XCTAssertEqual(viewModel.localItems.first?.status, "PAUSED")
    }
}
