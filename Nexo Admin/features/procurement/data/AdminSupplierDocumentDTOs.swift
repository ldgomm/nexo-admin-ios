//
//  AdminSupplierDocumentDTOs.swift
//  Nexo Admin
//
//  Created by José Ruiz on 29/7/26.
//
//  27R.N — Exact read-only supplier document wire contracts.
//

import Foundation

struct AdminSupplierDocumentListRequestDTO: Equatable, Sendable {
    let branchId: String?
    let supplierId: String?
    let documentType: String?
    let status: String?
    let documentDateFrom: String?
    let documentDateTo: String?
    let dueDateFrom: String?
    let dueDateTo: String?
    let query: String?
    let limit: Int
    let cursor: String?
}

struct AdminSupplierDocumentSourceTotalsDTO: Decodable, Sendable {
    let total: AdminProcurementMoneyDTO
    let taxTotal: AdminProcurementMoneyDTO
}

struct AdminSupplierDocumentSourcePaymentDTO: Decodable, Sendable {
    let amount: AdminProcurementMoneyDTO
    let method: String
    let paymentDate: String
    let reference: String?
}

struct AdminSupplierDocumentLineDTO: Decodable, Sendable {
    let id: String
    let kind: String
    let catalogItemId: String?
    let catalogItemSnapshot: AdminPurchaseItemSnapshotDTO?
    let purchaseOrderLineId: String?
    let purchaseReceiptLineId: String?
    let descriptionSnapshot: String
    let quantity: AdminPurchaseQuantityDTO
    let unitCost: AdminProcurementMoneyDTO
    let discountAmount: AdminProcurementMoneyDTO
    let priceTaxMode: String
    let taxProfileId: String
    let taxProfileVersion: Int64
    let taxes: [AdminPurchaseTaxDTO]
    let grossAmount: AdminProcurementMoneyDTO
    let netAmount: AdminProcurementMoneyDTO
    let taxAmount: AdminProcurementMoneyDTO
    let lineTotal: AdminProcurementMoneyDTO
    let expenseCategoryCode: String?
    let notes: String?
}

struct AdminSupplierDocumentDTO: Decodable, Sendable {
    let id: String
    let branchId: String
    let supplierId: String
    let documentType: String
    let status: String
    let documentNumber: String
    let documentNumberNormalized: String
    let accessKey: String?
    let authorizationNumber: String?
    let documentDate: String
    let dueDate: String?
    let currency: String
    let purchaseOrderIds: [String]
    let purchaseReceiptIds: [String]
    let lines: [AdminSupplierDocumentLineDTO]
    let subtotal: AdminProcurementMoneyDTO
    let discountTotal: AdminProcurementMoneyDTO
    let taxTotal: AdminProcurementMoneyDTO
    let total: AdminProcurementMoneyDTO
    let sourceTotals: AdminSupplierDocumentSourceTotalsDTO?
    let sourcePayment: AdminSupplierDocumentSourcePaymentDTO?
    let payableAmount: AdminProcurementMoneyDTO
    let payableId: String?
    let attachmentIds: [String]
    let accountingStatus: String
    let notes: String?
    let createdAt: String
    let createdBy: String
    let updatedAt: String
    let updatedBy: String
    let confirmedAt: String?
    let confirmedBy: String?
    let cancelledAt: String?
    let cancelledBy: String?
    let cancellationReason: String?
    let version: Int64
}

struct AdminSupplierDocumentListResponseDTO: Decodable, Sendable {
    let supplierDocuments: [AdminSupplierDocumentDTO]
    let nextCursor: String?
    let hasMore: Bool
}

struct AdminSupplierDocumentResponseMetaDTO: Decodable, Sendable {
    let requestId: String?
    let idempotencyReplayed: Bool?
}

struct AdminSupplierDocumentEnvelopeDTO: Decodable, Sendable {
    let data: AdminSupplierDocumentDTO
    let meta: AdminSupplierDocumentResponseMetaDTO
}
