//
//  AdminFinanceControlModels.swift
//  Nexo Admin
//
//  Created by José Ruiz on 29/7/26.
//
//  28R.M — safe administrative finance-control contracts.
//

import Foundation

enum AdminFinanceControlSource: String, Codable, Equatable, Sendable {
    case backend = "BACKEND"
    case local = "LOCAL"
}

enum AdminFinanceAccountingStatus: String, Codable, Equatable, Sendable {
    case operationalNotPosted = "OPERATIONAL_NOT_POSTED"
    case accountingPosted = "ACCOUNTING_POSTED"
    case unknown = "UNKNOWN"

    var safeDisplayTitle: String {
        switch self {
        case .operationalNotPosted:
            return "Operativo · no contabilizado"
        case .accountingPosted, .unknown:
            return "Estado no disponible"
        }
    }
}

struct AdminFinanceResolvedScope: Codable, Equatable, Sendable {
    let organizationId: String
    let organizationName: String
    let legalEntityId: String
    let legalEntityName: String
    let ledgerId: String
    let ledgerName: String
    let periodId: String
    let periodLabel: String
    let localeIdentifier: String
    let functionalCurrencyCode: String
}

struct AdminFinanceConfigurationSummary: Codable, Equatable, Sendable {
    let ledgerPolicyVersion: String
    let chartVersion: String
    let fiscalYearRule: String
    let periodStatus: String
    let categoryPolicyStatus: String
    let costCentrePolicyStatus: String
}

enum AdminFinanceOversightKind: String, Codable, Equatable, Sendable {
    case chart = "CHART"
    case category = "CATEGORY"
    case costCentre = "COST_CENTRE"
}

struct AdminFinanceDimensionOversight: Codable, Equatable, Identifiable, Sendable {
    let id: String
    let kind: AdminFinanceOversightKind
    let displayName: String
    let status: String
    let activeCount: Int
    let blockingIssueCount: Int
    let evidenceIds: [String]
}

struct AdminFinancePeriodOversight: Codable, Equatable, Identifiable, Sendable {
    let id: String
    let label: String
    let status: String
    let lockVersion: String
    let unresolvedCount: Int
    let evidenceIds: [String]
}

struct AdminFinanceImportBatchSummary: Codable, Equatable, Identifiable, Sendable {
    let id: String
    let fileDisplayName: String
    let status: String
    let acceptedRows: Int
    let rejectedRows: Int
    let errorCount: Int
    let checksumPrefix: String
    let reviewerDisplayName: String?
    let evidenceIds: [String]
}

struct AdminFinanceCoverageSummary: Codable, Equatable, Sendable {
    let replayStatus: String
    let backfillStatus: String
    let coverageStatus: String
    let requiredRubrics: Int
    let reconciledRubrics: Int
    let unresolvedBlockingCount: Int
    let exactDifferenceExplanation: String?
    let evidenceIds: [String]
}

struct AdminFinanceReconciliationException: Codable, Equatable, Identifiable, Sendable {
    let id: String
    let classification: String
    let title: String
    let explanation: String
    let status: String
    let blocking: Bool
    let evidenceIds: [String]
}

struct AdminFinanceCutoverSummary: Codable, Equatable, Sendable {
    let status: String
    let proposedDate: String?
    let backendEligibleForApproval: Bool
    let unresolvedBlockingCount: Int
    let overlapCount: Int
    let gapCount: Int
    let approvalEvidenceIds: [String]
}

struct AdminFinanceJurisdictionCapabilitySummary: Codable, Equatable, Sendable {
    let jurisdictionCode: String
    let packIdentifier: String
    let packVersion: String
    let verifiedCapabilityCodes: [String]
    let claimedCapabilityCodes: [String]
    let unverifiedCapabilityCodes: [String]
    let complianceStatement: String?
    let verificationEvidenceIds: [String]
}

struct AdminFinanceEvidenceReference: Codable, Equatable, Identifiable, Sendable {
    let id: String
    let kind: String
    let displayName: String
    let occurredAt: String
    let actorDisplayName: String?
    let maskedExternalReference: String?
}

struct AdminFinanceControlCapabilities: Codable, Equatable, Sendable {
    let canReviewImportBatch: Bool
    let canReviewReconciliationException: Bool
    let canApproveCutover: Bool
    let canViewEvidence: Bool

    init(
        canReviewImportBatch: Bool = false,
        canReviewReconciliationException: Bool = false,
        canApproveCutover: Bool = false,
        canViewEvidence: Bool = false
    ) {
        self.canReviewImportBatch = canReviewImportBatch
        self.canReviewReconciliationException = canReviewReconciliationException
        self.canApproveCutover = canApproveCutover
        self.canViewEvidence = canViewEvidence
    }
}

struct AdminFinanceControlActionReceipt: Codable, Equatable, Sendable {
    let actionId: String
    let status: String
    let evidenceId: String
    let sourceRevision: String
}

struct AdminFinanceControlSnapshot: Codable, Equatable, Sendable {
    let source: AdminFinanceControlSource
    let scope: AdminFinanceResolvedScope
    let accountingStatus: AdminFinanceAccountingStatus
    let authoritativeAccounting: Bool
    let configuration: AdminFinanceConfigurationSummary
    let dimensions: [AdminFinanceDimensionOversight]
    let periods: [AdminFinancePeriodOversight]
    let importBatches: [AdminFinanceImportBatchSummary]
    let coverage: AdminFinanceCoverageSummary
    let reconciliationExceptions: [AdminFinanceReconciliationException]
    let cutover: AdminFinanceCutoverSummary
    let jurisdiction: AdminFinanceJurisdictionCapabilitySummary
    let evidence: [AdminFinanceEvidenceReference]
    let capabilities: AdminFinanceControlCapabilities
    let generatedAt: String
    let sourceRevision: String
}

enum AdminFinanceControlSurface: String, CaseIterable, Equatable, Hashable, Sendable {
    case organisationAndLedger
    case chartCategoryAndCostCentre
    case periods
    case importBatches
    case replayBackfillAndCoverage
    case reconciliationExceptions
    case cutoverApproval
    case jurisdictionCapabilities
    case auditAndEvidence
}
