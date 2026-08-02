//
//  AdminSupplierPaymentModels.swift
//  Nexo Admin
//
//  Created by José Ruiz on 29/7/26.
//
//  27R.N — Supplier-payment review and permission-controlled void domain.
//

import Foundation

enum AdminSupplierPaymentStatus: String, CaseIterable, Identifiable, Sendable {
    case processing = "PROCESSING"
    case recorded = "RECORDED"
    case voiding = "VOIDING"
    case voided = "VOIDED"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .processing: return "Procesando"
        case .recorded: return "Registrado"
        case .voiding: return "Anulando"
        case .voided: return "Anulado"
        }
    }

    var systemImage: String {
        switch self {
        case .processing: return "hourglass"
        case .recorded: return "checkmark.circle.fill"
        case .voiding: return "arrow.triangle.2.circlepath.circle"
        case .voided: return "xmark.octagon.fill"
        }
    }

    var explanation: String {
        switch self {
        case .processing:
            return "El backend todavía procesa el registro. No debe repetirse el pago desde Admin."
        case .recorded:
            return "El backend registró el pago y sus aplicaciones operativas."
        case .voiding:
            return "El backend está anulando el pago y restaurando sus aplicaciones con trazabilidad."
        case .voided:
            return "El pago fue anulado con evidencia. Su historial y aplicaciones originales no se eliminaron."
        }
    }
}

enum AdminSupplierPaymentAllocationStatus: String, Sendable {
    case applied = "APPLIED"
    case reversed = "REVERSED"

    var title: String {
        switch self {
        case .applied: return "Aplicada"
        case .reversed: return "Revertida"
        }
    }
}

enum AdminSupplierPaymentMethod: String, CaseIterable, Identifiable, Sendable {
    case cash = "CASH"
    case bankTransfer = "BANK_TRANSFER"
    case card = "CARD"
    case check = "CHECK"
    case other = "OTHER"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .cash: return "Efectivo"
        case .bankTransfer: return "Transferencia bancaria"
        case .card: return "Tarjeta"
        case .check: return "Cheque"
        case .other: return "Otro"
        }
    }
}

enum AdminSupplierPaymentStatusFilter: String, CaseIterable, Identifiable, Sendable {
    case all = "ALL"
    case processing = "PROCESSING"
    case recorded = "RECORDED"
    case voiding = "VOIDING"
    case voided = "VOIDED"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: return "Todos"
        case .processing: return "Procesando"
        case .recorded: return "Registrados"
        case .voiding: return "Anulando"
        case .voided: return "Anulados"
        }
    }

    var apiValues: [AdminSupplierPaymentStatus] {
        switch self {
        case .all: return []
        case .processing: return [.processing]
        case .recorded: return [.recorded]
        case .voiding: return [.voiding]
        case .voided: return [.voided]
        }
    }

    var apiValue: String? {
        let values = apiValues.map(\.rawValue)
        return values.isEmpty ? nil : values.joined(separator: ",")
    }
}

enum AdminSupplierPaymentMethodFilter: String, CaseIterable, Identifiable, Sendable {
    case all = "ALL"
    case cash = "CASH"
    case bankTransfer = "BANK_TRANSFER"
    case card = "CARD"
    case check = "CHECK"
    case other = "OTHER"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: return "Todos"
        case .cash: return "Efectivo"
        case .bankTransfer: return "Transferencia bancaria"
        case .card: return "Tarjeta"
        case .check: return "Cheque"
        case .other: return "Otro"
        }
    }

    var apiValue: String? {
        self == .all ? nil : rawValue
    }
}

struct AdminSupplierPaymentAllocation: Identifiable, Equatable, Sendable {
    let id: String
    let payableId: String
    let amount: AdminProcurementMoney
    let payableBalanceBefore: AdminProcurementMoney
    let payableBalanceAfter: AdminProcurementMoney
    let status: AdminSupplierPaymentAllocationStatus
    let createdAt: String
    let createdBy: String
    let reversedAt: String?
    let reversedBy: String?
    let reversalReason: String?
}

struct AdminSupplierPayment: Identifiable, Equatable, Sendable {
    let id: String
    let branchId: String
    let supplierId: String
    let paymentNumber: String
    let paymentDate: String
    let currency: String
    let amount: AdminProcurementMoney
    let method: AdminSupplierPaymentMethod?
    let reference: String?
    let status: AdminSupplierPaymentStatus
    let allocations: [AdminSupplierPaymentAllocation]
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

    var allocationCountTitle: String {
        allocations.count == 1
            ? "1 aplicación"
            : "\(allocations.count) aplicaciones"
    }
}

struct AdminSupplierPaymentPresentation: Identifiable, Equatable, Sendable {
    let payment: AdminSupplierPayment
    let supplierName: String?

    var id: String { payment.id }

    var supplierTitle: String {
        supplierName?.trimmedOrNil ?? "Proveedor no disponible"
    }
}

struct AdminSupplierPaymentPage: Equatable, Sendable {
    let supplierPayments: [AdminSupplierPayment]
    let nextCursor: String?
    let hasMore: Bool
}

struct AdminSupplierPaymentEnvelope: Equatable, Sendable {
    let supplierPayment: AdminSupplierPayment
    let requestId: String?
    let idempotencyReplayed: Bool?
}

struct AdminSupplierPaymentMutationResult: Equatable, Sendable {
    let supplierPayment: AdminSupplierPayment
    let requestId: String?
    let idempotencyReplayed: Bool?
}

struct AdminSupplierPaymentListQuery: Equatable, Sendable {
    let branchId: String?
    let supplierId: String?
    let status: AdminSupplierPaymentStatusFilter
    let paymentFrom: String?
    let paymentTo: String?
    let method: AdminSupplierPaymentMethodFilter
    let query: String?
    let limit: Int
    let cursor: String?
}

struct AdminSupplierPaymentVoidInput: Equatable, Sendable {
    let reason: String
    let expectedVersion: Int64
    let idempotencyKey: String
}

enum AdminSupplierPaymentAccess {
    static func canView(_ permissions: Set<String>) -> Bool {
        PermissionSet(permissions).can(PermissionCatalog.supplierPaymentsView)
    }

    static func canViewSensitive(_ permissions: Set<String>) -> Bool {
        PermissionSet(permissions).can(PermissionCatalog.supplierPaymentsSensitiveView)
    }

    static func canVoid(_ status: AdminSupplierPaymentStatus, permissions: Set<String>) -> Bool {
        status == .recorded && PermissionSet(permissions).can(PermissionCatalog.supplierPaymentsVoid)
    }

    static func canViewAudit(_ permissions: Set<String>) -> Bool {
        PermissionSet(permissions).can(PermissionCatalog.procurementAuditView)
    }
}
