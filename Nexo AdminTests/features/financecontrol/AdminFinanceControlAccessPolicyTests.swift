//
//  AdminFinanceControlAccessPolicyTests.swift
//  Nexo AdminTests
//
//  Created by José Ruiz on 29/7/26.
//

import XCTest
@testable import Nexo_Admin

class AdminFinanceControlAccessPolicyTests: XCTestCase {
    func testNoPermissionCannotOpenSurface() {
        let policy = AdminFinanceControlAccessPolicy(
            effectivePermissions: []
        )

        XCTAssertFalse(policy.canViewSurface)
        XCTAssertFalse(policy.canView(.organisationAndLedger))
    }

    func testSingleReadPermissionOnlyOpensItsArea() {
        let policy = AdminFinanceControlAccessPolicy(
            effectivePermissions: [
                AdminFinanceControlPermission.periodsView
            ]
        )

        XCTAssertTrue(policy.canViewSurface)
        XCTAssertTrue(policy.canView(.periods))
        XCTAssertFalse(policy.canView(.cutoverApproval))
        XCTAssertFalse(policy.canView(.auditAndEvidence))
    }

    func testSuperuserCanViewEveryArea() {
        let policy = AdminFinanceControlAccessPolicy(
            effectivePermissions: ["*"]
        )

        XCTAssertTrue(policy.canViewSurface)
        for surface in AdminFinanceControlSurface.allCases {
            XCTAssertTrue(policy.canView(surface))
        }
    }

    func testCutoverApprovalNeedsPermissionAndBackendCapability() {
        let allowed = AdminFinanceControlAccessPolicy(
            effectivePermissions: [
                AdminFinanceControlPermission.cutoverApprove
            ]
        )

        XCTAssertFalse(
            allowed.allows(
                .approveCutover,
                capabilities: .init(canApproveCutover: false)
            )
        )
        XCTAssertTrue(
            allowed.allows(
                .approveCutover,
                capabilities: .init(canApproveCutover: true)
            )
        )
    }

    func testReadPermissionNeverGrantsReviewAction() {
        let policy = AdminFinanceControlAccessPolicy(
            effectivePermissions: [
                AdminFinanceControlPermission.importsView
            ]
        )

        XCTAssertFalse(
            policy.allows(
                .reviewImportBatch,
                capabilities: .init(canReviewImportBatch: true)
            )
        )
    }

    func testEvidenceNeedsPermissionAndCapability() {
        let policy = AdminFinanceControlAccessPolicy(
            effectivePermissions: [
                AdminFinanceControlPermission.evidenceView
            ]
        )

        XCTAssertFalse(
            policy.allows(
                .viewEvidence,
                capabilities: .init(canViewEvidence: false)
            )
        )
        XCTAssertTrue(
            policy.allows(
                .viewEvidence,
                capabilities: .init(canViewEvidence: true)
            )
        )
    }
}
