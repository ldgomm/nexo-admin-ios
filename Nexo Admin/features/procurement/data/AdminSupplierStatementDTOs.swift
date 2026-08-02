//
//  AdminSupplierStatementDTOs.swift
//  Nexo Admin
//
//  Created by José Ruiz on 29/7/26.
//
//  27R.N — Frozen supplier-statement and export request contracts.
//

import Foundation

struct AdminSupplierStatementRequestDTO: Sendable {
    let supplierId: String
    let branchId: String?
    let currency: String
    let from: String?
    let to: String?
    let asOf: String?
    let limit: Int
    let cursor: String?
}

struct AdminProcurementOperationalExportRequestDTO: Sendable {
    let reportType: String
    let branchId: String?
    let supplierId: String?
    let category: String?
    let catalogItemId: String?
    let paymentMethod: String?
    let attachmentSourceType: String?
    let currency: String
    let from: String?
    let to: String?
    let asOf: String?
}

struct AdminSupplierStatementLineDTO: Decodable, Sendable {
    let id: String
    let occurredAt: String
    let sourceType: String
    let sourceId: String
    let description: String
    let charge: AdminProcurementMoneyDTO
    let credit: AdminProcurementMoneyDTO
    let runningBalance: AdminProcurementMoneyDTO
    let currency: String
    let auditResourceType: String
    let auditResourceId: String
}

struct AdminSupplierStatementResponseDTO: Decodable, Sendable {
    let supplierId: String
    let branchId: String?
    let currency: String
    let from: String?
    let to: String?
    let asOf: String
    let openingBalance: AdminProcurementMoneyDTO
    let lines: [AdminSupplierStatementLineDTO]
    let closingBalance: AdminProcurementMoneyDTO
    let nextCursor: String?
    let hasMore: Bool
}
