//
//  AdminSupplierDocumentModels.swift
//  Nexo Admin
//
//  Created by José Ruiz on 29/7/26.
//
//  27R.N — Read-only supplier document register domain.
//

import Foundation

enum AdminSupplierDocumentType: String, CaseIterable, Identifiable, Sendable {
    case supplierInvoice = "SUPPLIER_INVOICE"
    case expense = "EXPENSE"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .supplierInvoice: return "Factura de proveedor"
        case .expense: return "Gasto"
        }
    }

    var systemImage: String {
        switch self {
        case .supplierInvoice: return "doc.text.fill"
        case .expense: return "receipt.fill"
        }
    }
}

enum AdminSupplierDocumentTypeFilter: String, CaseIterable, Identifiable, Sendable {
    case all = "ALL"
    case supplierInvoice = "SUPPLIER_INVOICE"
    case expense = "EXPENSE"

    var id: String { rawValue }
    var apiValue: String? { self == .all ? nil : rawValue }

    var title: String {
        guard self != .all, let type = AdminSupplierDocumentType(rawValue: rawValue) else {
            return "Todos"
        }
        return type.title
    }
}

enum AdminSupplierDocumentStatus: String, CaseIterable, Identifiable, Sendable {
    case draft = "DRAFT"
    case confirming = "CONFIRMING"
    case confirmed = "CONFIRMED"
    case cancelled = "CANCELLED"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .draft: return "Borrador"
        case .confirming: return "Confirmando"
        case .confirmed: return "Confirmado"
        case .cancelled: return "Cancelado"
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

enum AdminSupplierDocumentStatusFilter: String, CaseIterable, Identifiable, Sendable {
    case all = "ALL"
    case draft = "DRAFT"
    case confirming = "CONFIRMING"
    case confirmed = "CONFIRMED"
    case cancelled = "CANCELLED"

    var id: String { rawValue }
    var apiValue: String? { self == .all ? nil : rawValue }

    var title: String {
        guard self != .all, let status = AdminSupplierDocumentStatus(rawValue: rawValue) else {
            return "Todos"
        }
        return status.title
    }
}

enum AdminSupplierDocumentAccountingStatus: String, Sendable {
    case notPrepared = "NOT_PREPARED"
    case futureReview = "FUTURE_REVIEW"

    var title: String {
        switch self {
        case .notPrepared: return "No preparado"
        case .futureReview: return "Revisión futura"
        }
    }
}

struct AdminSupplierDocumentSourceTotals: Equatable, Sendable {
    let total: AdminProcurementMoney
    let taxTotal: AdminProcurementMoney
}

struct AdminSupplierDocumentSourcePayment: Equatable, Sendable {
    let amount: AdminProcurementMoney
    let method: String
    let paymentDate: String
    let reference: String?
}

struct AdminSupplierDocumentLine: Identifiable, Equatable, Sendable {
    let id: String
    let kind: AdminPurchaseLineKind
    let catalogItemId: String?
    let catalogItemSnapshot: AdminPurchaseItemSnapshot?
    let purchaseOrderLineId: String?
    let purchaseReceiptLineId: String?
    let descriptionSnapshot: String
    let quantity: AdminPurchaseQuantity
    let unitCost: AdminProcurementMoney
    let discountAmount: AdminProcurementMoney
    let priceTaxMode: AdminPurchasePriceTaxMode
    let taxProfileId: String
    let taxProfileVersion: Int64
    let taxes: [AdminPurchaseTax]
    let grossAmount: AdminProcurementMoney
    let netAmount: AdminProcurementMoney
    let taxAmount: AdminProcurementMoney
    let lineTotal: AdminProcurementMoney
    let expenseCategoryCode: String?
    let notes: String?
}

struct AdminSupplierDocument: Identifiable, Equatable, Sendable {
    let id: String
    let branchId: String
    let supplierId: String
    let documentType: AdminSupplierDocumentType
    let status: AdminSupplierDocumentStatus
    let documentNumber: String
    let documentNumberNormalized: String
    let accessKey: String?
    let authorizationNumber: String?
    let documentDate: String
    let dueDate: String?
    let currency: String
    let purchaseOrderIds: [String]
    let purchaseReceiptIds: [String]
    let lines: [AdminSupplierDocumentLine]
    let subtotal: AdminProcurementMoney
    let discountTotal: AdminProcurementMoney
    let taxTotal: AdminProcurementMoney
    let total: AdminProcurementMoney
    let sourceTotals: AdminSupplierDocumentSourceTotals?
    let sourcePayment: AdminSupplierDocumentSourcePayment?
    let payableAmount: AdminProcurementMoney
    let payableId: String?
    let attachmentIds: [String]
    let accountingStatus: AdminSupplierDocumentAccountingStatus
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

struct AdminSupplierDocumentPage: Equatable, Sendable {
    let supplierDocuments: [AdminSupplierDocument]
    let nextCursor: String?
    let hasMore: Bool
}

struct AdminSupplierDocumentEnvelope: Equatable, Sendable {
    let supplierDocument: AdminSupplierDocument
    let requestId: String?
    let idempotencyReplayed: Bool?
}

struct AdminSupplierDocumentListQuery: Equatable, Sendable {
    let branchId: String?
    let supplierId: String?
    let documentType: AdminSupplierDocumentTypeFilter
    let status: AdminSupplierDocumentStatusFilter
    let documentDateFrom: String?
    let documentDateTo: String?
    let dueDateFrom: String?
    let dueDateTo: String?
    let query: String?
    let limit: Int
    let cursor: String?
}

enum AdminSupplierDocumentAccess {
    static func canView(_ permissions: Set<String>) -> Bool {
        PermissionSet(permissions).can(PermissionCatalog.supplierDocumentsView)
    }
}
