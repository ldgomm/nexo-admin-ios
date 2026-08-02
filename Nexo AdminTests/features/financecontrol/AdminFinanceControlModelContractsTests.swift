//
//  AdminFinanceControlModelContractsTests.swift
//  Nexo AdminTests
//
//  Created by José Ruiz on 29/7/26.
//

import XCTest
@testable import Nexo_Admin

class AdminFinanceControlModelContractsTests: XCTestCase {
    func testAccountingStatusNeverLabelsPostedAsSafe() {
        XCTAssertEqual(
            AdminFinanceAccountingStatus.operationalNotPosted.safeDisplayTitle,
            "Operativo · no contabilizado"
        )
        XCTAssertEqual(
            AdminFinanceAccountingStatus.accountingPosted.safeDisplayTitle,
            "Estado no disponible"
        )
    }

    func testSnapshotCarriesEveryRequiredOversightArea() {
        let snapshot = AdminFinanceControlTestFixtures.snapshot()

        XCTAssertFalse(snapshot.scope.organizationId.isEmpty)
        XCTAssertFalse(snapshot.scope.legalEntityId.isEmpty)
        XCTAssertFalse(snapshot.scope.ledgerId.isEmpty)
        XCTAssertEqual(Set(snapshot.dimensions.map(\.kind)), [
            .chart,
            .category,
            .costCentre
        ])
        XCTAssertFalse(snapshot.periods.isEmpty)
        XCTAssertFalse(snapshot.importBatches.isEmpty)
        XCTAssertFalse(snapshot.reconciliationExceptions.isEmpty)
        XCTAssertFalse(snapshot.evidence.isEmpty)
    }

    func testJurisdictionClaimsAreDistinctFromPendingCapabilities() {
        let jurisdiction =
            AdminFinanceControlTestFixtures.snapshot().jurisdiction

        XCTAssertEqual(
            jurisdiction.claimedCapabilityCodes,
            jurisdiction.verifiedCapabilityCodes
        )
        XCTAssertFalse(jurisdiction.unverifiedCapabilityCodes.isEmpty)
        XCTAssertFalse(jurisdiction.verificationEvidenceIds.isEmpty)
    }
}
