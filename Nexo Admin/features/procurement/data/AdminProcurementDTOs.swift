//
//  AdminProcurementDTOs.swift
//  Nexo Admin
//
//  Created by José Ruiz on 29/7/26.
//
//  27R.N.1B — Procurement readiness and health contracts.
//

import Foundation

struct AdminProcurementReportCatalogEntryDTO: Decodable, Sendable {
    let reportType: String
    let title: String
    let description: String
    let jsonPath: String
    let csvPath: String
    let implementation: String
}

struct AdminProcurementReportCatalogDTO: Decodable, Sendable {
    let contractVersion: Int
    let reports: [AdminProcurementReportCatalogEntryDTO]
    let financeFactsPath: String
    let financeFactsCsvPath: String
    let accountingEntriesGenerated: Bool
}

struct AdminProcurementMoneyDTO: Decodable, Sendable {
    let amount: String
    let currency: String
}

struct AdminProcurementReconciliationDTO: Decodable, Sendable {
    let name: String
    let expected: String
    let actual: String
    let unit: String
    let passed: Bool
}

struct AdminProcurementOperationalHealthDTO: Decodable, Sendable {
    let reportType: String
    let title: String
    let branchId: String?
    let currency: String
    let asOf: String
    let generatedAt: String
    let matchingRowCount: Int
    let totalAmount: AdminProcurementMoneyDTO
    let openBalance: AdminProcurementMoneyDTO
    let reconciliationChecks: [AdminProcurementReconciliationDTO]
    let hasMore: Bool
}

struct AdminProcurementFinanceHealthDTO: Decodable, Sendable {
    let organizationId: String
    let branchId: String?
    let currency: String
    let generatedAt: String
    let matchingFactCount: Int
    let accountingEntriesGenerated: Bool
    let reconciliationChecks: [AdminProcurementReconciliationDTO]
    let hasMore: Bool
}

struct AdminProcurementFinanceSourceFactReplayReadinessDTO: Decodable, Sendable {
    let contractVersion: Int
    let schemaVersion: Int
    let organizationId: String
    let branchId: String?
    let supplierId: String?
    let currency: String
    let effectiveFrom: String?
    let effectiveTo: String?
    let snapshotAt: String
    let returnedFactCount: Int
    let hasMore: Bool
    let nextCursorAvailable: Bool
    let maxPageSize: Int
    let supportedFactTypes: [String]
    let reservedFactTypes: [String]
    let replayMode: String
    let readOnly: Bool
    let accountingEntriesGenerated: Bool
    let postable: Bool
    let limitations: [String]
}

struct AdminProcurementAccountingCompletenessItemDTO: Decodable, Sendable {
    let id: String
    let title: String
    let displayTitle: String
    let authoritativeEvidence: String
    let v1ReplayStatus: String
    let classification: String
    let classificationNote: String?
    let futureOwnerAction: String
}

struct AdminProcurementAccountingCompletenessMatrixDTO: Decodable, Sendable {
    let contractVersion: Int
    let matrixVersion: String
    let acceptedStage: String
    let organizationId: String
    let currency: String
    let scope: String
    let sourceDocument: String
    let totalItemCount: Int
    let passExistingCount: Int
    let futureGapCount: Int
    let notApplicableCount: Int
    let items: [AdminProcurementAccountingCompletenessItemDTO]
    let readOnly: Bool
    let accountingEntriesGenerated: Bool
    let postable: Bool
    let limitations: [String]
}
