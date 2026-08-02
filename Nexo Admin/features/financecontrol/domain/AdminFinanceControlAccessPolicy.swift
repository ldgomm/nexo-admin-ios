//
//  AdminFinanceControlAccessPolicy.swift
//  Nexo Admin
//
//  Created by José Ruiz on 29/7/26.
//

import Foundation

enum AdminFinanceControlPermission {
    static let configurationView = "finance.configuration.view"
    static let dimensionsView = "finance.dimensions.view"
    static let periodsView = "finance.periods.view"
    static let importsView = "finance.import.view"
    static let importsReview = "finance.import.review"
    static let coverageView = "finance.coverage.view"
    static let reconciliationView = "finance.reconciliation.view"
    static let reconciliationReview = "finance.reconciliation.review"
    static let cutoverView = "finance.cutover.view"
    static let cutoverApprove = "finance.cutover.approve"
    static let jurisdictionView = "finance.jurisdiction_capabilities.view"
    static let evidenceView = "finance.evidence.view"

    static let surfaceReadPermissions: Set<String> = [
        configurationView,
        dimensionsView,
        periodsView,
        importsView,
        coverageView,
        reconciliationView,
        cutoverView,
        jurisdictionView,
        evidenceView
    ]
}

enum AdminFinanceControlAction: Equatable, Sendable {
    case reviewImportBatch
    case reviewReconciliationException
    case approveCutover
    case viewEvidence
}

struct AdminFinanceControlAccessPolicy: Equatable, Sendable {
    private let effectivePermissions: Set<String>

    init(effectivePermissions: Set<String>) {
        self.effectivePermissions = Set(
            effectivePermissions.compactMap { permission in
                let normalized = permission.trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
                return normalized.isEmpty ? nil : normalized
            }
        )
    }

    var canViewSurface: Bool {
        isSuperuser ||
        !effectivePermissions.isDisjoint(
            with: AdminFinanceControlPermission.surfaceReadPermissions
        )
    }

    func canView(_ surface: AdminFinanceControlSurface) -> Bool {
        guard !isSuperuser else { return true }
        return allows(permission(for: surface))
    }

    func allows(
        _ action: AdminFinanceControlAction,
        capabilities: AdminFinanceControlCapabilities
    ) -> Bool {
        switch action {
        case .reviewImportBatch:
            return allows(AdminFinanceControlPermission.importsReview) &&
                capabilities.canReviewImportBatch
        case .reviewReconciliationException:
            return allows(AdminFinanceControlPermission.reconciliationReview) &&
                capabilities.canReviewReconciliationException
        case .approveCutover:
            return allows(AdminFinanceControlPermission.cutoverApprove) &&
                capabilities.canApproveCutover
        case .viewEvidence:
            return allows(AdminFinanceControlPermission.evidenceView) &&
                capabilities.canViewEvidence
        }
    }

    private var isSuperuser: Bool {
        effectivePermissions.contains("*")
    }

    private func allows(_ permission: String) -> Bool {
        isSuperuser || effectivePermissions.contains(permission)
    }

    private func permission(
        for surface: AdminFinanceControlSurface
    ) -> String {
        switch surface {
        case .organisationAndLedger:
            return AdminFinanceControlPermission.configurationView
        case .chartCategoryAndCostCentre:
            return AdminFinanceControlPermission.dimensionsView
        case .periods:
            return AdminFinanceControlPermission.periodsView
        case .importBatches:
            return AdminFinanceControlPermission.importsView
        case .replayBackfillAndCoverage:
            return AdminFinanceControlPermission.coverageView
        case .reconciliationExceptions:
            return AdminFinanceControlPermission.reconciliationView
        case .cutoverApproval:
            return AdminFinanceControlPermission.cutoverView
        case .jurisdictionCapabilities:
            return AdminFinanceControlPermission.jurisdictionView
        case .auditAndEvidence:
            return AdminFinanceControlPermission.evidenceView
        }
    }
}
