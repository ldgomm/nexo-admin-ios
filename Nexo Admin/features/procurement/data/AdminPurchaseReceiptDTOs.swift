//
//  AdminPurchaseReceiptDTOs.swift
//  Nexo Admin
//
//  27R.N.4 — Exact read-only purchase receipt and inventory-effect wire contracts.
//

import Foundation

struct AdminPurchaseReceiptListRequestDTO: Equatable, Sendable {
    let branchId: String?
    let supplierId: String?
    let purchaseOrderId: String?
    let status: String?
    let receivedFrom: String?
    let receivedTo: String?
    let limit: Int
    let cursor: String?
}

struct AdminPurchaseTrackedUnitDTO: Decodable, Sendable {
    let trackingType: String
    let trackingValue: String
    let notes: String?
}

struct AdminPurchaseReceiptLineDTO: Decodable, Sendable {
    let id: String
    let purchaseOrderLineId: String?
    let kind: String
    let catalogItemId: String?
    let itemSnapshot: AdminPurchaseItemSnapshotDTO?
    let receivedQuantity: AdminPurchaseQuantityDTO
    let acceptedQuantity: String
    let rejectedQuantity: String
    let unitCode: String
    let unitCost: AdminProcurementMoneyDTO?
    let warehouseId: String
    let trackedUnits: [AdminPurchaseTrackedUnitDTO]
    let inventoryMovementId: String?
    let notes: String?
}

struct AdminPurchaseReceiptDTO: Decodable, Sendable {
    let id: String
    let branchId: String
    let supplierId: String
    let purchaseOrderId: String?
    let receiptNumber: String
    let status: String
    let warehouseId: String
    let receivedAt: String
    let lines: [AdminPurchaseReceiptLineDTO]
    let inventoryMovementIds: [String]
    let attachmentIds: [String]
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

struct AdminPurchaseReceiptListResponseDTO: Decodable, Sendable {
    let purchaseReceipts: [AdminPurchaseReceiptDTO]
    let nextCursor: String?
    let hasMore: Bool
}

struct AdminPurchaseReceiptResponseMetaDTO: Decodable, Sendable {
    let requestId: String?
    let idempotencyReplayed: Bool?
}

struct AdminPurchaseReceiptEnvelopeDTO: Decodable, Sendable {
    let data: AdminPurchaseReceiptDTO
    let meta: AdminPurchaseReceiptResponseMetaDTO
}

struct AdminPurchaseReceiptInventoryEffectLineDTO: Decodable, Sendable {
    let receiptLineId: String
    let kind: String
    let catalogItemId: String?
    let receiptAcceptedQuantity: AdminPurchaseQuantityDTO
    let warehouseId: String
    let inventoryMovementId: String?
    let effectStatus: String
    let movementType: String?
    let direction: String?
    let movementQuantity: AdminPurchaseQuantityDTO?
    let quantityBefore: String?
    let quantityAfter: String?
    let sourceType: String?
    let sourceId: String?
    let sourceLineId: String?
    let occurredAt: String?
    let createdBy: String?
    let unitCost: AdminProcurementMoneyDTO?
    let totalCost: AdminProcurementMoneyDTO?
    let valueStatus: String
}

struct AdminPurchaseReceiptInventoryEffectsDTO: Decodable, Sendable {
    let receiptId: String
    let receiptNumber: String
    let receiptStatus: String
    let branchId: String
    let supplierId: String
    let purchaseOrderId: String?
    let warehouseId: String
    let quantityReconciliationStatus: String
    let valueReconciliationStatus: String
    let costsVisible: Bool
    let limitations: [String]
    let lines: [AdminPurchaseReceiptInventoryEffectLineDTO]
}

struct AdminPurchaseReceiptInventoryEffectsEnvelopeDTO: Decodable, Sendable {
    let data: AdminPurchaseReceiptInventoryEffectsDTO
    let meta: AdminPurchaseReceiptResponseMetaDTO
}
