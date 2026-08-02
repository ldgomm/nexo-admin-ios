//
//  AdminFinanceControlSnapshotValidatorTests.swift
//  Nexo AdminTests
//
//  Created by José Ruiz on 29/7/26.
//

import XCTest
@testable import Nexo_Admin

class AdminFinanceControlSnapshotValidatorTests: XCTestCase {
    private let validator = AdminFinanceControlSnapshotValidator()

    func testAcceptsBackendOperationalSnapshot() {
        XCTAssertNoThrow(
            try validator.validate(
                AdminFinanceControlTestFixtures.snapshot()
            )
        )
    }

    func testRejectsLocalSource() {
        XCTAssertThrowsError(
            try validator.validate(
                AdminFinanceControlTestFixtures.snapshot(source: .local)
            )
        ) { error in
            XCTAssertEqual(
                error as? AdminFinanceControlSnapshotValidationError,
                .nonBackendSource
            )
        }
    }

    func testRejectsIncompleteScope() {
        XCTAssertThrowsError(
            try validator.validate(
                AdminFinanceControlTestFixtures.snapshot(
                    organizationId: " "
                )
            )
        ) { error in
            XCTAssertEqual(
                error as? AdminFinanceControlSnapshotValidationError,
                .incompleteScope
            )
        }
    }

    func testRejectsAuthoritativeAccountingClaim() {
        XCTAssertThrowsError(
            try validator.validate(
                AdminFinanceControlTestFixtures.snapshot(
                    authoritativeAccounting: true
                )
            )
        ) { error in
            XCTAssertEqual(
                error as? AdminFinanceControlSnapshotValidationError,
                .authoritativeAccountingNotAllowed
            )
        }
    }

    func testRejectsPostedAccountingStatus() {
        XCTAssertThrowsError(
            try validator.validate(
                AdminFinanceControlTestFixtures.snapshot(
                    accountingStatus: .accountingPosted
                )
            )
        ) { error in
            XCTAssertEqual(
                error as? AdminFinanceControlSnapshotValidationError,
                .unsafeAccountingStatus
            )
        }
    }

    func testRejectsImpossibleCoverageCounts() {
        XCTAssertThrowsError(
            try validator.validate(
                AdminFinanceControlTestFixtures.snapshot(
                    requiredRubrics: 4,
                    reconciledRubrics: 5
                )
            )
        ) { error in
            XCTAssertEqual(
                error as? AdminFinanceControlSnapshotValidationError,
                .invalidCoverageCounts
            )
        }
    }

    func testRejectsClaimBeyondVerifiedCapability() {
        XCTAssertThrowsError(
            try validator.validate(
                AdminFinanceControlTestFixtures.snapshot(
                    verifiedCapabilityCodes: ["CAPABILITY_A"],
                    claimedCapabilityCodes: ["CAPABILITY_B"]
                )
            )
        ) { error in
            XCTAssertEqual(
                error as? AdminFinanceControlSnapshotValidationError,
                .unverifiedComplianceClaim
            )
        }
    }

    func testRejectsComplianceStatementWithoutEvidence() {
        XCTAssertThrowsError(
            try validator.validate(
                AdminFinanceControlTestFixtures.snapshot(
                    verificationEvidenceIds: []
                )
            )
        ) { error in
            XCTAssertEqual(
                error as? AdminFinanceControlSnapshotValidationError,
                .missingComplianceEvidence
            )
        }
    }

    func testRejectsUnmaskedEvidenceReference() {
        XCTAssertThrowsError(
            try validator.validate(
                AdminFinanceControlTestFixtures.snapshot(
                    maskedExternalReference: "123456789012"
                )
            )
        ) { error in
            XCTAssertEqual(
                error as? AdminFinanceControlSnapshotValidationError,
                .unmaskedExternalReference
            )
        }
    }
}
