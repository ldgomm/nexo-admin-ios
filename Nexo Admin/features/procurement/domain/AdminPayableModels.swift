//
//  AdminPayableModels.swift
//  Nexo Admin
//
//  Created by José Ruiz on 29/7/26.
//
//  27R.N — Read-only payable ageing and due-date control domain.
//

import Foundation

enum AdminPayableSettlementStatus: String, Sendable {
    case open = "OPEN"
    case partiallyPaid = "PARTIALLY_PAID"
    case paid = "PAID"
    case cancelled = "CANCELLED"

    var title: String {
        switch self {
        case .open: return "Pendiente"
        case .partiallyPaid: return "Pago parcial"
        case .paid: return "Pagada"
        case .cancelled: return "Cancelada"
        }
    }
}

enum AdminPayableEffectiveStatus: String, CaseIterable, Identifiable, Sendable {
    case open = "OPEN"
    case partiallyPaid = "PARTIALLY_PAID"
    case paid = "PAID"
    case overdue = "OVERDUE"
    case cancelled = "CANCELLED"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .open: return "Pendiente"
        case .partiallyPaid: return "Pago parcial"
        case .paid: return "Pagada"
        case .overdue: return "Vencida"
        case .cancelled: return "Cancelada"
        }
    }

    var systemImage: String {
        switch self {
        case .open: return "clock.fill"
        case .partiallyPaid: return "circle.lefthalf.filled"
        case .paid: return "checkmark.circle.fill"
        case .overdue: return "exclamationmark.triangle.fill"
        case .cancelled: return "xmark.octagon.fill"
        }
    }

    var explanation: String {
        switch self {
        case .open:
            return "El backend informa un saldo pendiente para la fecha de corte."
        case .partiallyPaid:
            return "El backend informa pagos aplicados y un saldo todavía pendiente."
        case .paid:
            return "El backend informa que el saldo quedó completamente pagado."
        case .overdue:
            return "El backend evalúa la obligación como vencida para la fecha de corte."
        case .cancelled:
            return "El backend informa que la obligación está cancelada."
        }
    }
}

enum AdminPayableStatusFilter: String, CaseIterable, Identifiable, Sendable {
    case all = "ALL"
    case outstanding = "OUTSTANDING"
    case open = "OPEN"
    case partiallyPaid = "PARTIALLY_PAID"
    case overdue = "OVERDUE"
    case paid = "PAID"
    case cancelled = "CANCELLED"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: return "Todos"
        case .outstanding: return "Con saldo"
        case .open: return "Pendientes"
        case .partiallyPaid: return "Pago parcial"
        case .overdue: return "Vencidas"
        case .paid: return "Pagadas"
        case .cancelled: return "Canceladas"
        }
    }

    var apiValues: [AdminPayableEffectiveStatus] {
        switch self {
        case .all: return []
        case .outstanding: return [.open, .partiallyPaid, .overdue]
        case .open: return [.open]
        case .partiallyPaid: return [.partiallyPaid]
        case .overdue: return [.overdue]
        case .paid: return [.paid]
        case .cancelled: return [.cancelled]
        }
    }

    var apiValue: String? {
        let values = apiValues.map(\.rawValue)
        return values.isEmpty ? nil : values.joined(separator: ",")
    }
}

enum AdminPayableAgingBucketCode: String, CaseIterable, Identifiable, Sendable {
    case current = "CURRENT"
    case due1To30 = "DUE_1_30"
    case due31To60 = "DUE_31_60"
    case due61To90 = "DUE_61_90"
    case due91Plus = "DUE_91_PLUS"
    case noDueDate = "NO_DUE_DATE"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .current: return "Al día o por vencer"
        case .due1To30: return "Vencida 1–30 días"
        case .due31To60: return "Vencida 31–60 días"
        case .due61To90: return "Vencida 61–90 días"
        case .due91Plus: return "Vencida 91+ días"
        case .noDueDate: return "Sin fecha de vencimiento"
        }
    }

    var systemImage: String {
        switch self {
        case .current: return "calendar.badge.clock"
        case .due1To30: return "exclamationmark.circle"
        case .due31To60: return "exclamationmark.triangle"
        case .due61To90: return "exclamationmark.triangle.fill"
        case .due91Plus: return "xmark.octagon.fill"
        case .noDueDate: return "calendar.badge.questionmark"
        }
    }
}

struct AdminPayable: Identifiable, Equatable, Sendable {
    let id: String
    let branchId: String
    let supplierId: String
    let sourceType: String
    let sourceId: String
    let currency: String
    let originalAmount: AdminProcurementMoney
    let paidAmount: AdminProcurementMoney
    let balance: AdminProcurementMoney
    let dueDate: String
    let settlementStatus: AdminPayableSettlementStatus
    let effectiveStatus: AdminPayableEffectiveStatus
    let allocationIds: [String]
    let createdAt: String
    let createdBy: String
    let updatedAt: String
    let updatedBy: String
    let version: Int64

    var sourceTitle: String {
        switch sourceType.uppercased() {
        case "SUPPLIER_DOCUMENT": return "Documento de proveedor"
        case "OPENING_BALANCE": return "Saldo inicial"
        case "ADJUSTMENT": return "Ajuste operativo"
        default:
            return sourceType
                .replacingOccurrences(of: "_", with: " ")
                .lowercased()
                .localizedCapitalized
        }
    }

    var allocationCountTitle: String {
        allocationIds.count == 1
            ? "1 aplicación de pago"
            : "\(allocationIds.count) aplicaciones de pago"
    }
}

struct AdminPayablePresentation: Identifiable, Equatable, Sendable {
    let payable: AdminPayable
    let supplierName: String?
    let sourceDocumentNumber: String?

    var id: String { payable.id }

    var supplierTitle: String {
        supplierName?.trimmedOrNil ?? "Proveedor no disponible"
    }

    var sourceTitle: String {
        sourceDocumentNumber?.trimmedOrNil ?? payable.sourceTitle
    }
}

struct AdminPayablePage: Equatable, Sendable {
    let payables: [AdminPayable]
    let nextCursor: String?
    let hasMore: Bool
    let asOf: String
}

struct AdminPayableEnvelope: Equatable, Sendable {
    let payable: AdminPayable
    let requestId: String?
    let idempotencyReplayed: Bool?
}

struct AdminPayableAgingBucket: Identifiable, Equatable, Sendable {
    var id: String { code.rawValue }
    let code: AdminPayableAgingBucketCode
    let count: Int64
    let balance: AdminProcurementMoney
}

struct AdminPayableAging: Equatable, Sendable {
    let currency: String
    let asOf: String
    let buckets: [AdminPayableAgingBucket]
}

struct AdminPayableListQuery: Equatable, Sendable {
    let branchId: String?
    let supplierId: String?
    let status: AdminPayableStatusFilter
    let dueFrom: String?
    let dueTo: String?
    let currency: String?
    let asOf: String?
    let limit: Int
    let cursor: String?
}

struct AdminPayableAgingQuery: Equatable, Sendable {
    let branchId: String?
    let supplierId: String?
    let currency: String?
    let asOf: String?
}

enum AdminPayableAccess {
    static func canViewList(_ permissions: Set<String>) -> Bool {
        PermissionSet(permissions).can(PermissionCatalog.payablesView)
    }

    static func canViewAging(_ permissions: Set<String>) -> Bool {
        PermissionSet(permissions).can(PermissionCatalog.payablesAgingView)
    }

    static func canEnter(_ permissions: Set<String>) -> Bool {
        canViewList(permissions) || canViewAging(permissions)
    }
}
