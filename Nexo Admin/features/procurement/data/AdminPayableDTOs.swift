//
//  AdminPayableDTOs.swift
//  Nexo Admin
//
//  Created by José Ruiz on 29/7/26.
//
//  27R.N — Exact read-only payable list, detail and ageing wire contracts.
//

import Foundation

struct AdminPayableListRequestDTO: Equatable, Sendable {
    let branchId: String?
    let supplierId: String?
    let effectiveStatus: String?
    let dueFrom: String?
    let dueTo: String?
    let currency: String?
    let asOf: String?
    let limit: Int
    let cursor: String?
}

struct AdminPayableAgingRequestDTO: Equatable, Sendable {
    let branchId: String?
    let supplierId: String?
    let currency: String?
    let asOf: String?
}

struct AdminPayableDTO: Decodable, Sendable {
    let id: String
    let branchId: String
    let supplierId: String
    let sourceType: String
    let sourceId: String
    let currency: String
    let originalAmount: AdminProcurementMoneyDTO
    let paidAmount: AdminProcurementMoneyDTO
    let balance: AdminProcurementMoneyDTO
    let dueDate: String
    let settlementStatus: String
    let effectiveStatus: String
    let allocationIds: [String]
    let createdAt: String
    let createdBy: String
    let updatedAt: String
    let updatedBy: String
    let version: Int64
}

struct AdminPayableListResponseDTO: Decodable, Sendable {
    let payables: [AdminPayableDTO]
    let nextCursor: String?
    let hasMore: Bool
    let asOf: String
}

struct AdminPayableResponseMetaDTO: Decodable, Sendable {
    let requestId: String?
    let idempotencyReplayed: Bool?
}

struct AdminPayableEnvelopeDTO: Decodable, Sendable {
    let data: AdminPayableDTO
    let meta: AdminPayableResponseMetaDTO
}

struct AdminPayableAgingBucketDTO: Decodable, Sendable {
    let code: String
    let count: Int64
    let balance: AdminProcurementMoneyDTO
}

struct AdminPayableAgingResponseDTO: Decodable, Sendable {
    let currency: String
    let asOf: String
    let buckets: [AdminPayableAgingBucketDTO]
}
