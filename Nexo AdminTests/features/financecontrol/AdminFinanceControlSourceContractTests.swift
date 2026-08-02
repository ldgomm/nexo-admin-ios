//
//  AdminFinanceControlSourceContractTests.swift
//  Nexo AdminTests
//
//  Created by José Ruiz on 29/7/26.
//

import Foundation
import XCTest
@testable import Nexo_Admin

class AdminFinanceControlSourceContractTests: XCTestCase {
    func testAllAdministrativeFinanceSurfacesRemainDeclared() {
        XCTAssertEqual(
            Set(AdminFinanceControlSurface.allCases),
            Set([
                .organisationAndLedger,
                .chartCategoryAndCostCentre,
                .periods,
                .importBatches,
                .replayBackfillAndCoverage,
                .reconciliationExceptions,
                .cutoverApproval,
                .jurisdictionCapabilities,
                .auditAndEvidence
            ])
        )
    }

    func testFeatureHasNoCountryDefaultsOrLocalFinancialTotals() throws {
        let repositoryRoot = try locateRepositoryRoot()
        let featureRoot = repositoryRoot
            .appendingPathComponent("Nexo Admin")
            .appendingPathComponent("features")
            .appendingPathComponent("financecontrol")

        let source = try swiftSource(in: featureRoot)
        let forbidden = [
            "America/Guayaquil",
            "\"USD\"",
            "\"$\"",
            "country == ",
            ".reduce(",
            "authoritativeAccounting: true",
            "SRI"
        ]

        for token in forbidden {
            XCTAssertFalse(
                source.contains(token),
                "Forbidden Admin finance UX token: \(token)"
            )
        }

        XCTAssertTrue(source.contains("OPERATIONAL_NOT_POSTED"))
        XCTAssertTrue(source.contains("runtimeEndpointUnavailable"))
        XCTAssertTrue(source.contains("/api/v1/admin/finance/control/snapshot"))
        XCTAssertTrue(source.contains("expectedSourceRevision"))
        XCTAssertTrue(source.contains("verifiedCapabilityCodes"))
        XCTAssertTrue(source.contains("maskedExternalReference"))
        XCTAssertTrue(source.contains("case backend = \"BACKEND\""))
    }

    func testAdminHomeUsesPermissionAwareFinanceNavigation() throws {
        let repositoryRoot = try locateRepositoryRoot()
        let home = repositoryRoot
            .appendingPathComponent("Nexo Admin")
            .appendingPathComponent(
                "features/businesssettings/presentation/AdminBusinessHomeView.swift"
            )
        let source = try String(contentsOf: home, encoding: .utf8)

        XCTAssertTrue(source.contains("canViewFinanceControl"))
        XCTAssertTrue(source.contains("AdminFinanceControlAccessPolicy"))
        XCTAssertTrue(source.contains("repository: financeControlRepository"))
        XCTAssertFalse(
            source.contains("AdminFinanceControlDeferredRepository()")
        )
        XCTAssertTrue(source.contains("Control financiero"))
    }

    func testSensitiveActionsRequirePermissionCapabilityAndEvidence() throws {
        let repositoryRoot = try locateRepositoryRoot()
        let featureRoot = repositoryRoot
            .appendingPathComponent("Nexo Admin")
            .appendingPathComponent("features")
            .appendingPathComponent("financecontrol")
        let source = try swiftSource(in: featureRoot)

        XCTAssertTrue(source.contains("finance.cutover.approve"))
        XCTAssertTrue(source.contains("backendEligibleForApproval"))
        XCTAssertTrue(source.contains("approvalEvidenceIds"))
        XCTAssertTrue(source.contains("missingReason"))
        XCTAssertTrue(source.contains("unverifiedComplianceClaim"))
    }

    private func locateRepositoryRoot() throws -> URL {
        var candidate = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()

        for _ in 0..<8 {
            let adminDirectory = candidate.appendingPathComponent("Nexo Admin")
            if FileManager.default.fileExists(atPath: adminDirectory.path) {
                return candidate
            }
            candidate.deleteLastPathComponent()
        }

        throw NSError(
            domain: "AdminFinanceControlSourceContractTests",
            code: 1
        )
    }

    private func swiftSource(in root: URL) throws -> String {
        guard let enumerator = FileManager.default.enumerator(
            at: root,
            includingPropertiesForKeys: nil
        ) else {
            throw NSError(
                domain: "AdminFinanceControlSourceContractTests",
                code: 2
            )
        }

        var source = ""
        for case let fileURL as URL in enumerator
            where fileURL.pathExtension == "swift" {
            source += try String(contentsOf: fileURL, encoding: .utf8)
            source.append("\n")
        }
        return source
    }
}
