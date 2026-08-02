//
//  AdminFinanceCutoverApprovalPolicy.swift
//  Nexo Admin
//
//  Created by José Ruiz on 29/7/26.
//

import Foundation

enum AdminFinanceCutoverApprovalBlocker: Error, Equatable, Sendable {
    case missingPermissionOrCapability
    case backendNotEligible
    case unresolvedBlockingItems
    case overlapOrGapDetected
    case missingEvidence
    case missingReason
}

struct AdminFinanceCutoverApprovalPolicy: Sendable {
    func validate(
        snapshot: AdminFinanceControlSnapshot,
        accessPolicy: AdminFinanceControlAccessPolicy,
        reason: String
    ) throws {
        guard accessPolicy.allows(
            .approveCutover,
            capabilities: snapshot.capabilities
        ) else {
            throw AdminFinanceCutoverApprovalBlocker
                .missingPermissionOrCapability
        }
        guard snapshot.cutover.backendEligibleForApproval else {
            throw AdminFinanceCutoverApprovalBlocker.backendNotEligible
        }
        guard snapshot.cutover.unresolvedBlockingCount == 0,
              snapshot.coverage.unresolvedBlockingCount == 0 else {
            throw AdminFinanceCutoverApprovalBlocker.unresolvedBlockingItems
        }
        guard snapshot.cutover.overlapCount == 0,
              snapshot.cutover.gapCount == 0 else {
            throw AdminFinanceCutoverApprovalBlocker.overlapOrGapDetected
        }
        guard !snapshot.cutover.approvalEvidenceIds.isEmpty,
              !snapshot.coverage.evidenceIds.isEmpty else {
            throw AdminFinanceCutoverApprovalBlocker.missingEvidence
        }
        guard !reason.trimmingCharacters(
            in: .whitespacesAndNewlines
        ).isEmpty else {
            throw AdminFinanceCutoverApprovalBlocker.missingReason
        }
    }
}
