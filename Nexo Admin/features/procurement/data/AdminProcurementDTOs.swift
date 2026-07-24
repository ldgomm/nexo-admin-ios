//
//  AdminProcurementDTOs.swift
//  Nexo Admin
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
