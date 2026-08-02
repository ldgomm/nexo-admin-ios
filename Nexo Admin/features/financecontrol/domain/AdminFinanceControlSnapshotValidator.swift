//
//  AdminFinanceControlSnapshotValidator.swift
//  Nexo Admin
//
//  Created by José Ruiz on 29/7/26.
//

import Foundation

enum AdminFinanceControlSnapshotValidationError: Error, Equatable, Sendable {
    case nonBackendSource
    case incompleteScope
    case authoritativeAccountingNotAllowed
    case unsafeAccountingStatus
    case missingLocale
    case missingCurrency
    case invalidCoverageCounts
    case invalidCutoverCounts
    case unverifiedComplianceClaim
    case missingComplianceEvidence
    case unmaskedExternalReference
}

struct AdminFinanceControlSnapshotValidator: Sendable {
    func validate(_ snapshot: AdminFinanceControlSnapshot) throws {
        guard snapshot.source == .backend else {
            throw AdminFinanceControlSnapshotValidationError.nonBackendSource
        }
        guard requiredScopeValues(snapshot.scope).allSatisfy({
            isPresent($0)
        }) else {
            throw AdminFinanceControlSnapshotValidationError.incompleteScope
        }
        guard snapshot.authoritativeAccounting == false else {
            throw AdminFinanceControlSnapshotValidationError
                .authoritativeAccountingNotAllowed
        }
        guard snapshot.accountingStatus == .operationalNotPosted else {
            throw AdminFinanceControlSnapshotValidationError
                .unsafeAccountingStatus
        }
        guard isPresent(snapshot.scope.localeIdentifier) else {
            throw AdminFinanceControlSnapshotValidationError.missingLocale
        }
        guard normalizedCurrency(
            snapshot.scope.functionalCurrencyCode
        ).count == 3 else {
            throw AdminFinanceControlSnapshotValidationError.missingCurrency
        }
        guard snapshot.coverage.requiredRubrics >= 0,
              snapshot.coverage.reconciledRubrics >= 0,
              snapshot.coverage.reconciledRubrics <=
                snapshot.coverage.requiredRubrics,
              snapshot.coverage.unresolvedBlockingCount >= 0 else {
            throw AdminFinanceControlSnapshotValidationError.invalidCoverageCounts
        }
        guard snapshot.cutover.unresolvedBlockingCount >= 0,
              snapshot.cutover.overlapCount >= 0,
              snapshot.cutover.gapCount >= 0 else {
            throw AdminFinanceControlSnapshotValidationError.invalidCutoverCounts
        }

        let verified = Set(
            snapshot.jurisdiction.verifiedCapabilityCodes.map(normalizedCode)
        )
        let claimed = Set(
            snapshot.jurisdiction.claimedCapabilityCodes.map(normalizedCode)
        )
        guard claimed.isSubset(of: verified) else {
            throw AdminFinanceControlSnapshotValidationError
                .unverifiedComplianceClaim
        }

        if let statement = snapshot.jurisdiction.complianceStatement,
           isPresent(statement) {
            guard !claimed.isEmpty else {
                throw AdminFinanceControlSnapshotValidationError
                    .unverifiedComplianceClaim
            }
            guard !snapshot.jurisdiction.verificationEvidenceIds.isEmpty else {
                throw AdminFinanceControlSnapshotValidationError
                    .missingComplianceEvidence
            }
        }

        for item in snapshot.evidence {
            if let reference = item.maskedExternalReference,
               isPresent(reference),
               !isMasked(reference) {
                throw AdminFinanceControlSnapshotValidationError
                    .unmaskedExternalReference
            }
        }
    }

    private func requiredScopeValues(
        _ scope: AdminFinanceResolvedScope
    ) -> [String] {
        [
            scope.organizationId,
            scope.organizationName,
            scope.legalEntityId,
            scope.legalEntityName,
            scope.ledgerId,
            scope.ledgerName,
            scope.periodId,
            scope.periodLabel
        ]
    }

    private func isPresent(_ value: String) -> Bool {
        !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func normalizedCurrency(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    }

    private func normalizedCode(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    }

    private func isMasked(_ value: String) -> Bool {
        let normalized = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return normalized.contains("•") ||
            normalized.contains("*") ||
            normalized.hasPrefix("…")
    }
}
