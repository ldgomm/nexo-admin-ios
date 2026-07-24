//
//  AdminPurchaseOrderDTOs.swift
//  Nexo Admin
//
//  27R.N.3 — Exact read-only purchase order wire contracts.
//

import Foundation

struct AdminPurchaseOrderListRequestDTO: Equatable, Sendable {
    let branchId: String?
    let supplierId: String?
    let status: String?
    let expectedFrom: String?
    let expectedTo: String?
    let query: String?
    let limit: Int
    let cursor: String?
}

struct AdminPurchaseQuantityDTO: Decodable, Sendable {
    let value: String
    let unitCode: String
    let allowsDecimal: Bool
}

struct AdminPurchaseTaxDTO: Decodable, Sendable {
    let taxCode: String?
    let rateCode: String?
    let rate: String
    let taxableBase: AdminProcurementMoneyDTO
    let amount: AdminProcurementMoneyDTO
}

struct AdminPurchaseItemSnapshotDTO: Decodable, Sendable {
    let catalogItemId: String
    let localName: String
    let sku: String?
    let unitCode: String
    let taxProfileId: String
    let taxProfileVersion: Int64
}

struct AdminPurchaseOrderLineDTO: Decodable, Sendable {
    let id: String
    let kind: String
    let catalogItemId: String?
    let catalogItemSnapshot: AdminPurchaseItemSnapshotDTO?
    let descriptionSnapshot: String
    let orderedQuantity: AdminPurchaseQuantityDTO
    let receivedQuantity: String
    let unitCost: AdminProcurementMoneyDTO?
    let discountAmount: AdminProcurementMoneyDTO?
    let priceTaxMode: String
    let taxProfileId: String
    let taxProfileVersion: Int64
    let taxes: [AdminPurchaseTaxDTO]?
    let grossAmount: AdminProcurementMoneyDTO?
    let netAmount: AdminProcurementMoneyDTO?
    let taxAmount: AdminProcurementMoneyDTO?
    let lineTotal: AdminProcurementMoneyDTO?
    let targetWarehouseId: String?
    let notes: String?
}

struct AdminPurchaseSupplierSnapshotDTO: Decodable, Sendable {
    let supplierId: String
    let legalName: String
    let tradeName: String?
    let identificationType: String?
    let identificationNumber: String?
    let paymentTerms: AdminSupplierPaymentTermsDTO
    let defaultCurrency: String
}

struct AdminPurchaseOrderDTO: Decodable, Sendable {
    let id: String
    let branchId: String
    let supplierId: String
    let orderNumber: String
    let status: String
    let currency: String
    let lines: [AdminPurchaseOrderLineDTO]
    let subtotal: AdminProcurementMoneyDTO?
    let discountTotal: AdminProcurementMoneyDTO?
    let taxTotal: AdminProcurementMoneyDTO?
    let total: AdminProcurementMoneyDTO?
    let expectedDate: String?
    let supplierSnapshot: AdminPurchaseSupplierSnapshotDTO
    let paymentTermsSnapshot: AdminSupplierPaymentTermsDTO
    let notes: String?
    let attachmentIds: [String]
    let createdAt: String
    let createdBy: String
    let updatedAt: String
    let updatedBy: String
    let sentAt: String?
    let sentBy: String?
    let closedAt: String?
    let closedBy: String?
    let closeReason: String?
    let cancelledAt: String?
    let cancelledBy: String?
    let cancellationReason: String?
    let version: Int64
}

struct AdminPurchaseOrderListResponseDTO: Decodable, Sendable {
    let purchaseOrders: [AdminPurchaseOrderDTO]
    let nextCursor: String?
    let hasMore: Bool
}

struct AdminPurchaseOrderResponseMetaDTO: Decodable, Sendable {
    let requestId: String?
    let idempotencyReplayed: Bool?
}

struct AdminPurchaseOrderEnvelopeDTO: Decodable, Sendable {
    let data: AdminPurchaseOrderDTO
    let meta: AdminPurchaseOrderResponseMetaDTO
}
