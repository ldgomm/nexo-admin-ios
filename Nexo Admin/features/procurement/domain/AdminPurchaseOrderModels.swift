//
//  AdminPurchaseOrderModels.swift
//  Nexo Admin
//
//  27R.N.3 — Read-only purchase order oversight domain.
//

import Foundation

enum AdminPurchaseOrderStatus: String, CaseIterable, Identifiable, Sendable {
    case draft = "DRAFT"
    case sent = "SENT"
    case partiallyReceived = "PARTIALLY_RECEIVED"
    case received = "RECEIVED"
    case cancelled = "CANCELLED"
    case closed = "CLOSED"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .draft: return "Borrador"
        case .sent: return "Enviada"
        case .partiallyReceived: return "Recepción parcial"
        case .received: return "Recibida"
        case .cancelled: return "Cancelada"
        case .closed: return "Cerrada"
        }
    }

    var systemImage: String {
        switch self {
        case .draft: return "doc.badge.ellipsis"
        case .sent: return "paperplane.fill"
        case .partiallyReceived: return "shippingbox.and.arrow.backward.fill"
        case .received: return "checkmark.circle.fill"
        case .cancelled: return "xmark.octagon.fill"
        case .closed: return "lock.circle.fill"
        }
    }
}

enum AdminPurchaseOrderStatusFilter: String, CaseIterable, Identifiable, Sendable {
    case all = "ALL"
    case draft = "DRAFT"
    case sent = "SENT"
    case partiallyReceived = "PARTIALLY_RECEIVED"
    case received = "RECEIVED"
    case cancelled = "CANCELLED"
    case closed = "CLOSED"

    var id: String { rawValue }
    var apiValue: String? { self == .all ? nil : rawValue }

    var title: String {
        guard self != .all, let status = AdminPurchaseOrderStatus(rawValue: rawValue) else {
            return "Todos"
        }
        return status.title
    }
}

enum AdminPurchaseLineKind: String, Sendable {
    case stockItem = "STOCK_ITEM"
    case service = "SERVICE"
    case expense = "EXPENSE"
    case other = "OTHER"

    var title: String {
        switch self {
        case .stockItem: return "Producto"
        case .service: return "Servicio"
        case .expense: return "Gasto"
        case .other: return "Otro"
        }
    }
}

enum AdminPurchasePriceTaxMode: String, Sendable {
    case taxExclusive = "TAX_EXCLUSIVE"
    case taxInclusive = "TAX_INCLUSIVE"

    var title: String {
        switch self {
        case .taxExclusive: return "Impuesto no incluido"
        case .taxInclusive: return "Impuesto incluido"
        }
    }
}

struct AdminPurchaseQuantity: Equatable, Sendable {
    let value: Decimal
    let unitCode: String
    let allowsDecimal: Bool

    var formatted: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = allowsDecimal ? 6 : 0
        return formatter.string(from: value as NSDecimalNumber) ?? "\(value)"
    }
}

struct AdminPurchaseTax: Equatable, Sendable {
    let taxCode: String?
    let rateCode: String?
    let rate: Decimal
    let taxableBase: AdminProcurementMoney
    let amount: AdminProcurementMoney
}

struct AdminPurchaseItemSnapshot: Equatable, Sendable {
    let catalogItemId: String
    let localName: String
    let sku: String?
    let unitCode: String
    let taxProfileId: String
    let taxProfileVersion: Int64
}

struct AdminPurchaseOrderLine: Identifiable, Equatable, Sendable {
    let id: String
    let kind: AdminPurchaseLineKind
    let catalogItemId: String?
    let catalogItemSnapshot: AdminPurchaseItemSnapshot?
    let descriptionSnapshot: String
    let orderedQuantity: AdminPurchaseQuantity
    let receivedQuantity: Decimal
    let unitCost: AdminProcurementMoney?
    let discountAmount: AdminProcurementMoney?
    let priceTaxMode: AdminPurchasePriceTaxMode
    let taxProfileId: String
    let taxProfileVersion: Int64
    let taxes: [AdminPurchaseTax]?
    let grossAmount: AdminProcurementMoney?
    let netAmount: AdminProcurementMoney?
    let taxAmount: AdminProcurementMoney?
    let lineTotal: AdminProcurementMoney?
    let targetWarehouseId: String?
    let notes: String?

    var receivedQuantityFormatted: String {
        AdminPurchaseQuantity(
            value: receivedQuantity,
            unitCode: orderedQuantity.unitCode,
            allowsDecimal: orderedQuantity.allowsDecimal
        ).formatted
    }
}

struct AdminPurchaseSupplierSnapshot: Equatable, Sendable {
    let supplierId: String
    let legalName: String
    let tradeName: String?
    let identificationType: AdminSupplierIdentificationType?
    let identificationNumber: String?
    let paymentTerms: AdminSupplierPaymentTerms
    let defaultCurrency: String

    var displayName: String { tradeName?.trimmedOrNil ?? legalName }
}

struct AdminPurchaseOrder: Identifiable, Equatable, Sendable {
    let id: String
    let branchId: String
    let supplierId: String
    let orderNumber: String
    let status: AdminPurchaseOrderStatus
    let currency: String
    let lines: [AdminPurchaseOrderLine]
    let subtotal: AdminProcurementMoney?
    let discountTotal: AdminProcurementMoney?
    let taxTotal: AdminProcurementMoney?
    let total: AdminProcurementMoney?
    let expectedDate: String?
    let supplierSnapshot: AdminPurchaseSupplierSnapshot
    let paymentTermsSnapshot: AdminSupplierPaymentTerms
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
    let costsVisible: Bool
}

struct AdminPurchaseOrderPage: Equatable, Sendable {
    let purchaseOrders: [AdminPurchaseOrder]
    let nextCursor: String?
    let hasMore: Bool
}

struct AdminPurchaseOrderEnvelope: Equatable, Sendable {
    let purchaseOrder: AdminPurchaseOrder
    let requestId: String?
    let idempotencyReplayed: Bool?
}

struct AdminPurchaseOrderListQuery: Equatable, Sendable {
    let branchId: String?
    let supplierId: String?
    let status: AdminPurchaseOrderStatusFilter
    let expectedFrom: String?
    let expectedTo: String?
    let query: String?
    let limit: Int
    let cursor: String?
}

enum AdminPurchaseOrderAccess {
    static func canView(_ permissions: Set<String>) -> Bool {
        PermissionSet(permissions).can(PermissionCatalog.purchaseOrdersView)
    }

    static func canViewCosts(_ permissions: Set<String>) -> Bool {
        PermissionSet(permissions).can(PermissionCatalog.purchaseOrdersCostView)
    }
}
