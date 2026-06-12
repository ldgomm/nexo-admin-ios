//
//  AdminTaxSriViewModelTests.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import XCTest
@testable import Nexo_Admin

@MainActor
final class AdminTaxSriViewModelTests: XCTestCase {
    func testLoadSummaryPopulatesAllSections() async {
        let repository = AdminTaxSriTestRepository()
        let viewModel = AdminTaxSriViewModel(repository: repository)

        await viewModel.load()

        XCTAssertEqual(viewModel.taxSettings?.organizationId, "org_altos")
        XCTAssertEqual(viewModel.taxProfiles.count, 5)
        XCTAssertEqual(viewModel.signatures.count, 1)
        XCTAssertEqual(viewModel.readiness?.status, "blocked")
        XCTAssertEqual(viewModel.homologationRuns.count, 1)
    }

    func testRunReadinessUpdatesChecklist() async {
        let repository = AdminTaxSriTestRepository()
        let viewModel = AdminTaxSriViewModel(repository: repository)

        await viewModel.runReadiness()

        XCTAssertEqual(viewModel.readiness?.score, 78)
        XCTAssertEqual(viewModel.successMessage, "Readiness SRI ejecutado.")
    }

    func testProductionGateRejectsWrongConfirmation() async {
        let repository = AdminTaxSriTestRepository()
        let viewModel = AdminTaxSriViewModel(repository: repository)

        await viewModel.requestProductionEnable(confirmationText: "OK", reason: "test")

        XCTAssertNotNil(viewModel.errorMessage)
    }

    func testUploadSignatureClearsThroughRepository() async {
        let repository = AdminTaxSriTestRepository()
        let viewModel = AdminTaxSriViewModel(repository: repository)

        await viewModel.uploadSignature(alias: "Nueva", fileName: "firma.p12", fileData: Data("abc".utf8), password: "secret", reason: "rotación")

        XCTAssertEqual(viewModel.signatures.first?.alias, "Nueva")
    }
}
