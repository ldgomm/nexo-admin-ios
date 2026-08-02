//
//  AdminPurchaseReceiptModels.swift
//  Nexo Admin
//
//  Created by José Ruiz on 29/7/26.
//
//  27R.N.4 — Read-only receipt and canonical inventory-effect review domain.
//

import Foundation

enum AdminPurchaseReceiptStatus: String, CaseIterable, Identifiable, Sendable {
    case draft = "DRAFT"
    case confirming = "CONFIRMING"
    case confirmed = "CONFIRMED"
    case cancelled = "CANCELLED"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .draft: return "Borrador"
        case .confirming: return "Confirmando"
        case .confirmed: return "Confirmada"
        case .cancelled: return "Cancelada"
        }
    }

    var systemImage: String {
        switch self {
        case .draft: return "doc.badge.ellipsis"
        case .confirming: return "clock.arrow.circlepath"
        case .confirmed: return "checkmark.circle.fill"
        case .cancelled: return "xmark.octagon.fill"
        }
    }
}

enum AdminPurchaseReceiptStatusFilter: String, CaseIterable, Identifiable, Sendable {
    case all = "ALL"
    case draft = "DRAFT"
    case confirming = "CONFIRMING"
    case confirmed = "CONFIRMED"
    case cancelled = "CANCELLED"

    var id: String { rawValue }
    var apiValue: String? { self == .all ? nil : rawValue }

    var title: String {
        guard self != .all, let status = AdminPurchaseReceiptStatus(rawValue: rawValue) else {
            return "Todos"
        }
        return status.title
    }
}

enum AdminPurchaseReceiptEffectStatus: String, Sendable {
    case notApplicable = "NOT_APPLICABLE"
    case unverifiable = "UNVERIFIABLE"
    case pending = "PENDING"
    case quantityReconciled = "QUANTITY_RECONCILED"

    var title: String {
        switch self {
        case .notApplicable: return "Sin efecto aplicable"
        case .unverifiable: return "Revisión requerida"
        case .pending: return "Pendiente"
        case .quantityReconciled: return "Cantidad conciliada"
        }
    }
}

enum AdminPurchaseReceiptQuantityReconciliationStatus: String, Sendable {
    case noEffectExpected = "NO_EFFECT_EXPECTED"
    case pending = "PENDING"
    case reviewRequired = "REVIEW_REQUIRED"
    case quantityReconciled = "QUANTITY_RECONCILED"

    var title: String {
        switch self {
        case .noEffectExpected: return "Sin efecto esperado"
        case .pending: return "Efecto pendiente"
        case .reviewRequired: return "Revisión requerida"
        case .quantityReconciled: return "Cantidad conciliada"
        }
    }
}

enum AdminPurchaseReceiptValueStatus: String, Sendable {
    case redacted = "REDACTED"
    case notApplicable = "NOT_APPLICABLE"
    case notRecorded = "NOT_RECORDED"
    case pending = "PENDING"
    case valueReconciled = "VALUE_RECONCILED"
    case unverifiable = "UNVERIFIABLE"

    var title: String {
        switch self {
        case .redacted: return "Valor restringido"
        case .notApplicable: return "Valor no aplicable"
        case .notRecorded: return "Valor no registrado"
        case .pending: return "Valor pendiente"
        case .valueReconciled: return "Valor y moneda conciliados"
        case .unverifiable: return "Valor no verificable"
        }
    }
}

enum AdminPurchaseReceiptReconciliationScope: String, Sendable {
    case quantityValueReconciled = "QUANTITY_VALUE_RECONCILED"
    case quantityReconciled = "QUANTITY_RECONCILED"
    case none = "NONE"

    var title: String {
        switch self {
        case .quantityValueReconciled: return "Cantidad, valor y moneda conciliados"
        case .quantityReconciled: return "Solo cantidad conciliada"
        case .none: return "Sin conciliación"
        }
    }
}

struct AdminPurchaseTrackedUnit: Equatable, Sendable {
    let trackingType: String
    let trackingValue: String
    let notes: String?
}

struct AdminPurchaseReceiptLine: Identifiable, Equatable, Sendable {
    let id: String
    let purchaseOrderLineId: String?
    let kind: AdminPurchaseLineKind
    let catalogItemId: String?
    let itemSnapshot: AdminPurchaseItemSnapshot?
    let receivedQuantity: AdminPurchaseQuantity
    let acceptedQuantity: Decimal
    let rejectedQuantity: Decimal
    let unitCode: String
    let unitCost: AdminProcurementMoney?
    let warehouseId: String
    let trackedUnits: [AdminPurchaseTrackedUnit]
    let inventoryMovementId: String?
    let notes: String?

    var acceptedQuantityFormatted: String {
        formatted(acceptedQuantity)
    }

    var rejectedQuantityFormatted: String {
        formatted(rejectedQuantity)
    }

    private func formatted(_ value: Decimal) -> String {
        AdminPurchaseQuantity(
            value: value,
            unitCode: unitCode,
            allowsDecimal: receivedQuantity.allowsDecimal
        ).formatted
    }
}

struct AdminPurchaseReceipt: Identifiable, Equatable, Sendable {
    let id: String
    let branchId: String
    let supplierId: String
    let purchaseOrderId: String?
    let receiptNumber: String
    let status: AdminPurchaseReceiptStatus
    let warehouseId: String
    let receivedAt: String
    let lines: [AdminPurchaseReceiptLine]
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

    var highLevelEffectTitle: String {
        switch status {
        case .draft, .cancelled: return "Sin efecto de inventario"
        case .confirming: return "Efecto pendiente"
        case .confirmed:
            return inventoryMovementIds.isEmpty ? "Revisión de efecto requerida" : "Con evidencia de inventario"
        }
    }
}

struct AdminPurchaseReceiptPage: Equatable, Sendable {
    let receipts: [AdminPurchaseReceipt]
    let nextCursor: String?
    let hasMore: Bool
}

struct AdminPurchaseReceiptEnvelope: Equatable, Sendable {
    let receipt: AdminPurchaseReceipt
    let requestId: String?
    let idempotencyReplayed: Bool?
}

struct AdminPurchaseReceiptListQuery: Equatable, Sendable {
    let branchId: String?
    let supplierId: String?
    let purchaseOrderId: String?
    let status: AdminPurchaseReceiptStatusFilter
    let receivedFrom: String?
    let receivedTo: String?
    let limit: Int
    let cursor: String?
}

struct AdminPurchaseReceiptInventoryEffectLine: Identifiable, Equatable, Sendable {
    var id: String { receiptLineId }

    let receiptLineId: String
    let kind: AdminPurchaseLineKind
    let catalogItemId: String?
    let receiptAcceptedQuantity: AdminPurchaseQuantity
    let warehouseId: String
    let inventoryMovementId: String?
    let effectStatus: AdminPurchaseReceiptEffectStatus
    let movementType: String?
    let direction: String?
    let movementQuantity: AdminPurchaseQuantity?
    let quantityBefore: Decimal?
    let quantityAfter: Decimal?
    let sourceType: String?
    let sourceId: String?
    let sourceLineId: String?
    let occurredAt: String?
    let createdBy: String?
    let unitCost: AdminProcurementMoney?
    let totalCost: AdminProcurementMoney?
    let valueStatus: AdminPurchaseReceiptValueStatus
}

struct AdminPurchaseReceiptInventoryEffects: Equatable, Sendable {
    let receiptId: String
    let receiptNumber: String
    let receiptStatus: AdminPurchaseReceiptStatus
    let branchId: String
    let supplierId: String
    let purchaseOrderId: String?
    let warehouseId: String
    let quantityStatus: AdminPurchaseReceiptQuantityReconciliationStatus
    let valueStatus: AdminPurchaseReceiptValueStatus
    let costsVisible: Bool
    let limitations: [String]
    let lines: [AdminPurchaseReceiptInventoryEffectLine]
    let requestId: String?

    var reconciliationScope: AdminPurchaseReceiptReconciliationScope {
        switch (quantityStatus, valueStatus) {
        case (.quantityReconciled, .valueReconciled):
            return .quantityValueReconciled
        case (.quantityReconciled, _):
            return .quantityReconciled
        default:
            return .none
        }
    }

    var movementValueOrCurrencyNotRecorded: Bool {
        limitations.contains("MOVEMENT_VALUE_OR_CURRENCY_NOT_RECORDED")
    }

    var trackedUnitEffectIsOutsideContract: Bool {
        limitations.contains("TRACKED_UNIT_EFFECT_NOT_RECONCILED_BY_THIS_CONTRACT")
    }
}

enum AdminPurchaseReceiptAccess {
    static func canView(_ permissions: Set<String>) -> Bool {
        PermissionSet(permissions).can(PermissionCatalog.purchaseReceiptsView)
    }

    static func canViewInventoryEffects(_ permissions: Set<String>) -> Bool {
        let permissionSet = PermissionSet(permissions)
        return permissionSet.can(PermissionCatalog.purchaseReceiptsView)
            && permissionSet.can(PermissionCatalog.inventoryView)
    }

    static func canViewCosts(_ permissions: Set<String>) -> Bool {
        PermissionSet(permissions).can(PermissionCatalog.purchaseOrdersCostView)
    }

    static func canViewAudit(_ permissions: Set<String>) -> Bool {
        PermissionSet(permissions).can(PermissionCatalog.procurementAuditView)
    }
}
