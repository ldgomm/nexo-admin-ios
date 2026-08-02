//
//  AdminSupplierPaymentDTOs.swift
//  Nexo Admin
//
//  Created by José Ruiz on 29/7/26.
//
//  27R.N — Exact Admin supplier-payment review and void wire contracts.
//

import Foundation

struct AdminSupplierPaymentListRequestDTO: Equatable, Sendable {
    let branchId: String?
    let supplierId: String?
    let status: String?
    let paymentFrom: String?
    let paymentTo: String?
    let method: String?
    let query: String?
    let limit: Int
    let cursor: String?
}

struct AdminSupplierPaymentVoidRequestDTO: Encodable, Equatable, Sendable {
    let reason: String
    let expectedVersion: Int64
}

struct AdminSupplierPaymentAllocationDTO: Decodable, Sendable {
    let id: String
    let payableId: String
    let amount: AdminProcurementMoneyDTO
    let payableBalanceBefore: AdminProcurementMoneyDTO
    let payableBalanceAfter: AdminProcurementMoneyDTO
    let status: String
    let createdAt: String
    let createdBy: String
    let reversedAt: String?
    let reversedBy: String?
    let reversalReason: String?
}

struct AdminSupplierPaymentDTO: Decodable, Sendable {
    let id: String
    let branchId: String
    let supplierId: String
    let paymentNumber: String
    let paymentDate: String
    let currency: String
    let amount: AdminProcurementMoneyDTO
    let method: String?
    let reference: String?
    let status: String
    let allocations: [AdminSupplierPaymentAllocationDTO]
    let attachmentIds: [String]?
    let cashMovementId: String?
    let notes: String?
    let createdAt: String
    let createdBy: String
    let updatedAt: String
    let updatedBy: String
    let recordedAt: String?
    let recordedBy: String?
    let voidedAt: String?
    let voidedBy: String?
    let voidReason: String?
    let version: Int64
}

struct AdminSupplierPaymentListResponseDTO: Decodable, Sendable {
    let supplierPayments: [AdminSupplierPaymentDTO]
    let nextCursor: String?
    let hasMore: Bool
}

struct AdminSupplierPaymentResponseMetaDTO: Decodable, Sendable {
    let requestId: String?
    let idempotencyReplayed: Bool?
}

struct AdminSupplierPaymentEnvelopeDTO: Decodable, Sendable {
    let data: AdminSupplierPaymentDTO
    let meta: AdminSupplierPaymentResponseMetaDTO
}
