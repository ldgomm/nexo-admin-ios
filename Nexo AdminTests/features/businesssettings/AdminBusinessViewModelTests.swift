//
//  AdminBusinessViewModelTests.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import XCTest
@testable import Nexo_Admin

@MainActor
final class AdminBusinessViewModelTests: XCTestCase {
    func testLoadPublishesOverview() async {
        let repository = AdminBusinessTestRepository()
        let viewModel = AdminBusinessViewModel(repository: repository)

        await viewModel.load()

        XCTAssertEqual(viewModel.business?.taxId, "1790012345001")
        XCTAssertEqual(viewModel.activities.count, 1)
        XCTAssertEqual(viewModel.branches.count, 1)
    }

    func testUpdateBusinessRefreshesProfile() async {
        let repository = AdminBusinessTestRepository()
        let viewModel = AdminBusinessViewModel(repository: repository)
        await viewModel.load()

        let ok = await viewModel.updateBusiness(
            UpdateAdminBusinessProfileInput(
                countryCode: "EC",
                taxId: "1790099999001",
                legalName: "Nexo Actualizado S.A.S.",
                commercialName: "Nexo Actualizado",
                defaultCurrency: "USD",
                timezone: "America/Guayaquil",
                reason: "Prueba actualización"
            )
        )

        XCTAssertTrue(ok)
        XCTAssertEqual(viewModel.business?.commercialName, "Nexo Actualizado")
        XCTAssertEqual(viewModel.business?.version, 2)
    }

    func testSaveActivityCreatesAndReloadsOverview() async {
        let repository = AdminBusinessTestRepository()
        let viewModel = AdminBusinessViewModel(repository: repository)
        await viewModel.load()

        let ok = await viewModel.saveActivity(
            SaveAdminActivityInput(
                id: nil,
                code: "services",
                name: "Servicios",
                description: nil,
                activityType: "services",
                workflowMode: "service_order",
                status: "active",
                requiresScheduling: true,
                tracksInventory: false,
                allowsReceivables: true,
                sortOrder: 2,
                reason: "Prueba actividad"
            )
        )

        XCTAssertTrue(ok)
        XCTAssertEqual(viewModel.activities.count, 2)
        XCTAssertTrue(viewModel.activities.contains(where: { $0.name == "Servicios" }))
    }

    func testSaveBranchCreatesAndReloadsOverview() async {
        let repository = AdminBusinessTestRepository()
        let viewModel = AdminBusinessViewModel(repository: repository)
        await viewModel.load()

        let ok = await viewModel.saveBranch(
            SaveAdminBranchInput(
                id: nil,
                code: "002",
                name: "Sucursal Norte",
                type: "branch",
                status: "active",
                location: AdminBranchLocation(countryCode: "EC", province: "Pichincha", city: "Quito", sector: "Norte", addressLine: "Av. Principal", latitude: nil, longitude: nil, privacyMode: "private"),
                businessHoursId: "hours_main",
                clearLocation: false,
                clearBusinessHoursId: false,
                reason: "Prueba sucursal"
            )
        )

        XCTAssertTrue(ok)
        XCTAssertEqual(viewModel.branches.count, 2)
        XCTAssertTrue(viewModel.branches.contains(where: { $0.name == "Sucursal Norte" }))
    }

    func testSaveEmissionPointCreatesAndReloadsOverview() async {
        let repository = AdminBusinessTestRepository()
        let viewModel = AdminBusinessViewModel(repository: repository)
        await viewModel.load()

        let ok = await viewModel.saveEmissionPoint(
            SaveAdminEmissionPointInput(
                id: nil,
                branchId: "br_1",
                establishmentCode: "001",
                emissionPointCode: "001",
                displayName: "Caja 1",
                status: "active",
                reason: "Prueba punto de emisión"
            )
        )

        XCTAssertTrue(ok)
        XCTAssertEqual(viewModel.emissionPoints.count, 1)
        XCTAssertEqual(viewModel.emissionPoints.first?.displayName, "Caja 1")
    }

    func testValidationRejectsMissingReason() async {
        let repository = AdminBusinessTestRepository()
        let viewModel = AdminBusinessViewModel(repository: repository)
        await viewModel.load()

        let ok = await viewModel.saveActivity(
            SaveAdminActivityInput(
                id: nil,
                code: "bad",
                name: "Bad",
                description: nil,
                activityType: "retail",
                workflowMode: "quick_sale",
                status: "active",
                requiresScheduling: false,
                tracksInventory: false,
                allowsReceivables: true,
                sortOrder: 0,
                reason: ""
            )
        )

        XCTAssertFalse(ok)
        XCTAssertEqual(viewModel.errorMessage, "Ingresa un motivo para auditar este cambio.")
    }
}
