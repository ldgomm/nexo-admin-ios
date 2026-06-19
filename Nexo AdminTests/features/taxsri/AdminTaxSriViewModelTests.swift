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
        XCTAssertEqual(viewModel.homologationRuns.count, 3)
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

@MainActor
final class AdminElectronicSignatureStateTests: XCTestCase {
    func testUploadedSignatureCanOnlyBeValidatedOrRevoked() {
        let signature = makeSignature(status: "UPLOADED", effectiveStatus: "UPLOADED", usable: false)

        XCTAssertEqual(signature.displayStatusTitle, "Cargada")
        XCTAssertTrue(signature.canValidate)
        XCTAssertFalse(signature.canActivate)
        XCTAssertTrue(signature.canRevoke)
    }

    func testValidSignatureCanBeActivatedButNotValidatedAgain() {
        let signature = makeSignature(status: "VALID", effectiveStatus: "VALID", usable: false)

        XCTAssertEqual(signature.displayStatusTitle, "Válida")
        XCTAssertFalse(signature.canValidate)
        XCTAssertTrue(signature.canActivate)
        XCTAssertTrue(signature.canRevoke)
    }

    func testRevokedSignatureHasNoSensitiveActions() {
        let signature = makeSignature(status: "REVOKED", effectiveStatus: "REVOKED", usable: false)

        XCTAssertEqual(signature.displayStatusTitle, "Revocada")
        XCTAssertFalse(signature.canValidate)
        XCTAssertFalse(signature.canActivate)
        XCTAssertFalse(signature.canRevoke)
        XCTAssertTrue(signature.requiresNewUpload)
    }

    func testViewModelRejectsInvalidSignatureFileExtension() async {
        let repository = AdminTaxSriTestRepository()
        let viewModel = AdminTaxSriViewModel(repository: repository)

        await viewModel.uploadSignature(
            alias: "Firma",
            fileName: "firma.txt",
            fileData: Data("abc".utf8),
            password: "secret",
            reason: "test"
        )

        XCTAssertEqual(viewModel.errorMessage, "Selecciona un archivo de firma .p12 o .pfx.")
    }

    private func makeSignature(
        status: String,
        effectiveStatus: String,
        usable: Bool
    ) -> AdminElectronicSignature {
        AdminElectronicSignature(
            id: "sig_test_\(status)",
            organizationId: "org_altos",
            alias: "Firma test",
            subject: "ALTOS DEL MURCO",
            issuer: "Entidad certificadora",
            serialNumber: "SERIAL",
            validFrom: "2026-01-01",
            validTo: "2027-01-01",
            status: status,
            effectiveStatus: effectiveStatus,
            usable: usable,
            expiresInDays: 100,
            expiresSoon: false,
            uploadedBy: "test",
            uploadedAt: "now",
            lastUsedAt: nil,
            lastValidatedAt: nil,
            createdAt: "now"
        )
    }
}
