//
//  AdminFinanceCutoverApprovalPolicyTests.swift
//  Nexo AdminTests
//
//  Created by José Ruiz on 29/7/26.
//

import XCTest
@testable import Nexo_Admin

class AdminFinanceCutoverApprovalPolicyTests: XCTestCase {
    private let policy = AdminFinanceCutoverApprovalPolicy()
    private let access = AdminFinanceControlAccessPolicy(
        effectivePermissions: ["*"]
    )

    func testAllowsFullyEvidencedBackendEligibleCutover() {
        XCTAssertNoThrow(
            try policy.validate(
                snapshot: AdminFinanceControlTestFixtures.snapshot(),
                accessPolicy: access,
                reason: "Reviewed and approved."
            )
        )
    }

    func testBlocksWithoutPermission() {
        XCTAssertThrowsError(
            try policy.validate(
                snapshot: AdminFinanceControlTestFixtures.snapshot(),
                accessPolicy: .init(effectivePermissions: []),
                reason: "Reviewed."
            )
        ) { error in
            XCTAssertEqual(
                error as? AdminFinanceCutoverApprovalBlocker,
                .missingPermissionOrCapability
            )
        }
    }

    func testBlocksWhenBackendIsNotEligible() {
        XCTAssertThrowsError(
            try policy.validate(
                snapshot: AdminFinanceControlTestFixtures.snapshot(
                    backendEligibleForApproval: false
                ),
                accessPolicy: access,
                reason: "Reviewed."
            )
        ) { error in
            XCTAssertEqual(
                error as? AdminFinanceCutoverApprovalBlocker,
                .backendNotEligible
            )
        }
    }

    func testBlocksUnresolvedItems() {
        XCTAssertThrowsError(
            try policy.validate(
                snapshot: AdminFinanceControlTestFixtures.snapshot(
                    coverageBlockingCount: 1
                ),
                accessPolicy: access,
                reason: "Reviewed."
            )
        ) { error in
            XCTAssertEqual(
                error as? AdminFinanceCutoverApprovalBlocker,
                .unresolvedBlockingItems
            )
        }
    }

    func testBlocksOverlapOrGap() {
        XCTAssertThrowsError(
            try policy.validate(
                snapshot: AdminFinanceControlTestFixtures.snapshot(
                    overlapCount: 1
                ),
                accessPolicy: access,
                reason: "Reviewed."
            )
        ) { error in
            XCTAssertEqual(
                error as? AdminFinanceCutoverApprovalBlocker,
                .overlapOrGapDetected
            )
        }
    }

    func testBlocksWithoutEvidence() {
        XCTAssertThrowsError(
            try policy.validate(
                snapshot: AdminFinanceControlTestFixtures.snapshot(
                    approvalEvidenceIds: []
                ),
                accessPolicy: access,
                reason: "Reviewed."
            )
        ) { error in
            XCTAssertEqual(
                error as? AdminFinanceCutoverApprovalBlocker,
                .missingEvidence
            )
        }
    }

    func testBlocksBlankReason() {
        XCTAssertThrowsError(
            try policy.validate(
                snapshot: AdminFinanceControlTestFixtures.snapshot(),
                accessPolicy: access,
                reason: " "
            )
        ) { error in
            XCTAssertEqual(
                error as? AdminFinanceCutoverApprovalBlocker,
                .missingReason
            )
        }
    }
}
