//
//  AdminSupplierStatementModels.swift
//  Nexo Admin
//
//  Created by José Ruiz on 29/7/26.
//
//  27R.N — Read-only supplier statement and canonical procurement exports.
//

import Foundation

enum AdminSupplierStatementSourceType: Equatable, Sendable {
    case supplierDocument
    case sourcePayment
    case paymentAllocation
    case paymentAllocationReversal
    case unsupported(String)

    init(wireValue: String) {
        switch wireValue.trimmingCharacters(in: .whitespacesAndNewlines).uppercased() {
        case "SUPPLIER_DOCUMENT": self = .supplierDocument
        case "SOURCE_PAYMENT": self = .sourcePayment
        case "PAYMENT_ALLOCATION": self = .paymentAllocation
        case "PAYMENT_ALLOCATION_REVERSAL": self = .paymentAllocationReversal
        default: self = .unsupported(wireValue)
        }
    }

    var wireValue: String {
        switch self {
        case .supplierDocument: return "SUPPLIER_DOCUMENT"
        case .sourcePayment: return "SOURCE_PAYMENT"
        case .paymentAllocation: return "PAYMENT_ALLOCATION"
        case .paymentAllocationReversal: return "PAYMENT_ALLOCATION_REVERSAL"
        case .unsupported(let value): return value
        }
    }

    var title: String {
        switch self {
        case .supplierDocument: return "Documento de proveedor"
        case .sourcePayment: return "Pago al registrar documento"
        case .paymentAllocation: return "Aplicación de pago"
        case .paymentAllocationReversal: return "Reverso de aplicación"
        case .unsupported(let value):
            return value
                .replacingOccurrences(of: "_", with: " ")
                .lowercased()
                .localizedCapitalized
        }
    }

    var systemImage: String {
        switch self {
        case .supplierDocument: return "doc.text.fill"
        case .sourcePayment: return "banknote.fill"
        case .paymentAllocation: return "arrow.down.circle.fill"
        case .paymentAllocationReversal: return "arrow.uturn.backward.circle.fill"
        case .unsupported: return "questionmark.circle"
        }
    }
}

struct AdminSupplierStatementLine: Identifiable, Equatable, Sendable {
    let id: String
    let occurredAt: String
    let sourceType: AdminSupplierStatementSourceType
    let sourceId: String
    let description: String
    let charge: AdminProcurementMoney
    let credit: AdminProcurementMoney
    let runningBalance: AdminProcurementMoney
    let currency: String
    let auditResourceType: String
    let auditResourceId: String

    var occurredDate: String {
        let value = occurredAt.trimmingCharacters(in: .whitespacesAndNewlines)
        return value.count >= 10 ? String(value.prefix(10)) : value
    }

    var auditTitle: String {
        switch auditResourceType.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "supplier_document": return "Evidencia del documento"
        case "supplier_payment": return "Evidencia del pago"
        case "payable": return "Evidencia de la cuenta por pagar"
        case "payment_allocation": return "Evidencia de la aplicación"
        default: return "Evidencia de origen"
        }
    }
}

struct AdminSupplierStatement: Equatable, Sendable {
    let supplierId: String
    let branchId: String?
    let currency: String
    let from: String?
    let to: String?
    let asOf: String
    let openingBalance: AdminProcurementMoney
    let lines: [AdminSupplierStatementLine]
    let closingBalance: AdminProcurementMoney
    let nextCursor: String?
    let hasMore: Bool
}

struct AdminSupplierStatementQuery: Equatable, Sendable {
    let supplierId: String
    let branchId: String?
    let currency: String
    let from: String?
    let to: String?
    let asOf: String?
    let limit: Int
    let cursor: String?
}

struct AdminProcurementOperationalExportQuery: Equatable, Sendable {
    let reportType: String
    let branchId: String?
    let supplierId: String?
    let category: String?
    let catalogItemId: String?
    let paymentMethod: String?
    let attachmentSourceType: String?
    let currency: String
    let from: String?
    let to: String?
    let asOf: String?
}

struct AdminProcurementDownloadedFile: Identifiable, Equatable, Sendable {
    let localURL: URL
    let fileName: String
    let contentType: String
    let sizeBytes: Int
    let exportType: String
    let exportVersion: String
    let rowCount: Int

    var id: String { localURL.absoluteString }
}

enum AdminSupplierStatementAccess {
    static func canView(_ permissions: Set<String>) -> Bool {
        PermissionSet(permissions).can(PermissionCatalog.supplierStatementsView)
    }

    static func canExport(_ permissions: Set<String>) -> Bool {
        canView(permissions) && PermissionSet(permissions).can(PermissionCatalog.supplierStatementsExport)
    }

    static func canBrowseSuppliers(_ permissions: Set<String>) -> Bool {
        PermissionSet(permissions).can(PermissionCatalog.suppliersView)
    }

    static func canViewAudit(_ permissions: Set<String>) -> Bool {
        PermissionSet(permissions).can(PermissionCatalog.procurementAuditView)
    }
}

enum AdminProcurementExportAccess {
    static func canViewCatalog(_ permissions: Set<String>) -> Bool {
        PermissionSet(permissions).can(PermissionCatalog.reportsDashboardView)
    }

    static func canExport(_ permissions: Set<String>) -> Bool {
        canViewCatalog(permissions) && PermissionSet(permissions).can(PermissionCatalog.reportsExport)
    }
}
