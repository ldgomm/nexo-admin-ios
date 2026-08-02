//
//  AdminFinanceControlTestFixtures.swift
//  Nexo AdminTests
//
//  Created by José Ruiz on 29/7/26.
//

import Foundation
@testable import Nexo_Admin

enum AdminFinanceControlTestFixtures {
    static func snapshot(
        source: AdminFinanceControlSource = .backend,
        organizationId: String = "org_synthetic",
        authoritativeAccounting: Bool = false,
        accountingStatus: AdminFinanceAccountingStatus = .operationalNotPosted,
        requiredRubrics: Int = 8,
        reconciledRubrics: Int = 8,
        coverageBlockingCount: Int = 0,
        cutoverBlockingCount: Int = 0,
        overlapCount: Int = 0,
        gapCount: Int = 0,
        backendEligibleForApproval: Bool = true,
        approvalEvidenceIds: [String] = ["evidence_cutover"],
        coverageEvidenceIds: [String] = ["evidence_coverage"],
        verifiedCapabilityCodes: [String] = ["CAPABILITY_A"],
        claimedCapabilityCodes: [String] = ["CAPABILITY_A"],
        complianceStatement: String? = "Verified synthetic capability.",
        verificationEvidenceIds: [String] = ["evidence_capability"],
        maskedExternalReference: String? = "•••• 9012",
        capabilities: AdminFinanceControlCapabilities = .init(
            canReviewImportBatch: true,
            canReviewReconciliationException: true,
            canApproveCutover: true,
            canViewEvidence: true
        )
    ) -> AdminFinanceControlSnapshot {
        AdminFinanceControlSnapshot(
            source: source,
            scope: AdminFinanceResolvedScope(
                organizationId: organizationId,
                organizationName: "Synthetic Retail",
                legalEntityId: "entity_1",
                legalEntityName: "Synthetic Retail Entity",
                ledgerId: "ledger_1",
                ledgerName: "Operating ledger",
                periodId: "period_2026_07",
                periodLabel: "July 2026",
                localeIdentifier: "fr_FR",
                functionalCurrencyCode: "EUR"
            ),
            accountingStatus: accountingStatus,
            authoritativeAccounting: authoritativeAccounting,
            configuration: AdminFinanceConfigurationSummary(
                ledgerPolicyVersion: "policy-v1",
                chartVersion: "chart-v1",
                fiscalYearRule: "CALENDAR",
                periodStatus: "OPEN",
                categoryPolicyStatus: "READY",
                costCentrePolicyStatus: "READY"
            ),
            dimensions: [
                AdminFinanceDimensionOversight(
                    id: "dimension_chart",
                    kind: .chart,
                    displayName: "Chart",
                    status: "READY",
                    activeCount: 12,
                    blockingIssueCount: 0,
                    evidenceIds: ["evidence_chart"]
                ),
                AdminFinanceDimensionOversight(
                    id: "dimension_category",
                    kind: .category,
                    displayName: "Categories",
                    status: "READY",
                    activeCount: 6,
                    blockingIssueCount: 0,
                    evidenceIds: ["evidence_category"]
                ),
                AdminFinanceDimensionOversight(
                    id: "dimension_cost_centre",
                    kind: .costCentre,
                    displayName: "Cost centres",
                    status: "READY",
                    activeCount: 2,
                    blockingIssueCount: 0,
                    evidenceIds: ["evidence_cost_centre"]
                )
            ],
            periods: [
                AdminFinancePeriodOversight(
                    id: "period_2026_07",
                    label: "July 2026",
                    status: "OPEN",
                    lockVersion: "lock-v1",
                    unresolvedCount: coverageBlockingCount,
                    evidenceIds: ["evidence_period"]
                )
            ],
            importBatches: [
                AdminFinanceImportBatchSummary(
                    id: "import_1",
                    fileDisplayName: "history.csv",
                    status: "READY_FOR_REVIEW",
                    acceptedRows: 10,
                    rejectedRows: 1,
                    errorCount: 1,
                    checksumPrefix: "ab12cd34",
                    reviewerDisplayName: nil,
                    evidenceIds: ["evidence_import"]
                )
            ],
            coverage: AdminFinanceCoverageSummary(
                replayStatus: "PASS",
                backfillStatus: "PASS",
                coverageStatus: "READY",
                requiredRubrics: requiredRubrics,
                reconciledRubrics: reconciledRubrics,
                unresolvedBlockingCount: coverageBlockingCount,
                exactDifferenceExplanation: nil,
                evidenceIds: coverageEvidenceIds
            ),
            reconciliationExceptions: [
                AdminFinanceReconciliationException(
                    id: "exception_1",
                    classification: "UNMATCHED",
                    title: "Synthetic exception",
                    explanation: "Reviewable source difference.",
                    status: "OPEN",
                    blocking: false,
                    evidenceIds: ["evidence_exception"]
                )
            ],
            cutover: AdminFinanceCutoverSummary(
                status: "READY_FOR_APPROVAL",
                proposedDate: "2026-08-01",
                backendEligibleForApproval: backendEligibleForApproval,
                unresolvedBlockingCount: cutoverBlockingCount,
                overlapCount: overlapCount,
                gapCount: gapCount,
                approvalEvidenceIds: approvalEvidenceIds
            ),
            jurisdiction: AdminFinanceJurisdictionCapabilitySummary(
                jurisdictionCode: "XZ",
                packIdentifier: "synthetic-pack",
                packVersion: "v1",
                verifiedCapabilityCodes: verifiedCapabilityCodes,
                claimedCapabilityCodes: claimedCapabilityCodes,
                unverifiedCapabilityCodes: ["CAPABILITY_PENDING"],
                complianceStatement: complianceStatement,
                verificationEvidenceIds: verificationEvidenceIds
            ),
            evidence: [
                AdminFinanceEvidenceReference(
                    id: "evidence_1",
                    kind: "SOURCE",
                    displayName: "Synthetic source",
                    occurredAt: "2026-07-29T16:00:00Z",
                    actorDisplayName: "Reviewer",
                    maskedExternalReference: maskedExternalReference
                )
            ],
            capabilities: capabilities,
            generatedAt: "2026-07-29T16:00:00Z",
            sourceRevision: "revision_1"
        )
    }

    static let receipt = AdminFinanceControlActionReceipt(
        actionId: "action_1",
        status: "ACCEPTED",
        evidenceId: "evidence_action_1",
        sourceRevision: "revision_2"
    )
}

class AdminFinanceControlRepositoryStub:
    AdminFinanceControlRepository,
    @unchecked Sendable
{
    let snapshotResult: Result<
        AdminFinanceControlSnapshot,
        AdminFinanceControlRepositoryError
    >
    let commandResult: Result<
        AdminFinanceControlActionReceipt,
        AdminFinanceControlRepositoryError
    >

    private(set) var loadCount = 0
    private(set) var reviewedImportBatches: [(String, String)] = []
    private(set) var reviewedExceptions: [(String, String)] = []
    private(set) var cutoverReasons: [String] = []

    init(
        snapshotResult: Result<
            AdminFinanceControlSnapshot,
            AdminFinanceControlRepositoryError
        >,
        commandResult: Result<
            AdminFinanceControlActionReceipt,
            AdminFinanceControlRepositoryError
        > = .success(AdminFinanceControlTestFixtures.receipt)
    ) {
        self.snapshotResult = snapshotResult
        self.commandResult = commandResult
    }

    func loadSnapshot() async throws -> AdminFinanceControlSnapshot {
        loadCount += 1
        return try snapshotResult.get()
    }

    func reviewImportBatch(
        id: String,
        reason: String,
        expectedSourceRevision: String
    ) async throws -> AdminFinanceControlActionReceipt {
        reviewedImportBatches.append((id, reason))
        return try commandResult.get()
    }

    func reviewReconciliationException(
        id: String,
        reason: String,
        expectedSourceRevision: String
    ) async throws -> AdminFinanceControlActionReceipt {
        reviewedExceptions.append((id, reason))
        return try commandResult.get()
    }

    func approveCutover(
        reason: String,
        expectedSourceRevision: String
    ) async throws -> AdminFinanceControlActionReceipt {
        cutoverReasons.append(reason)
        return try commandResult.get()
    }
}
