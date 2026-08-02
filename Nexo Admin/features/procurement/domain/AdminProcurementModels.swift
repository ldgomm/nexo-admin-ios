//
//  AdminProcurementModels.swift
//  Nexo Admin
//
//  Created by José Ruiz on 29/7/26.
//
//  27R.N.1B — Procurement readiness domain.
//

import Foundation

struct AdminProcurementMoney: Equatable, Sendable {
    let amount: Decimal
    let currency: String

    var formatted: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.currencySymbol = currency == "USD" ? "$" : currency
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: amount as NSDecimalNumber) ?? "\(currency) \(amount)"
    }
}

struct AdminProcurementReconciliationCheck: Identifiable, Equatable, Sendable {
    var id: String { name }
    let name: String
    let expected: String
    let actual: String
    let unit: String
    let passed: Bool
}

struct AdminProcurementReportCatalogEntry: Identifiable, Equatable, Sendable {
    var id: String { reportType }
    let reportType: String
    let title: String
    let description: String
    let jsonPath: String
    let csvPath: String
    let implementation: String
}

struct AdminProcurementReportCatalog: Equatable, Sendable {
    let contractVersion: Int
    let reports: [AdminProcurementReportCatalogEntry]
    let financeFactsPath: String
    let financeFactsCsvPath: String
    let accountingEntriesGenerated: Bool
}

struct AdminProcurementOperationalHealth: Equatable, Sendable {
    let reportType: String
    let title: String
    let branchId: String?
    let currency: String
    let asOf: String
    let generatedAt: String
    let matchingRowCount: Int
    let totalAmount: AdminProcurementMoney
    let openBalance: AdminProcurementMoney
    let reconciliationChecks: [AdminProcurementReconciliationCheck]
    let hasMore: Bool
}

struct AdminProcurementFinanceHealth: Equatable, Sendable {
    let organizationId: String
    let branchId: String?
    let currency: String
    let generatedAt: String
    let matchingFactCount: Int
    let accountingEntriesGenerated: Bool
    let reconciliationChecks: [AdminProcurementReconciliationCheck]
    let hasMore: Bool
}

struct AdminProcurementFinanceSourceFactReplayReadiness: Equatable, Sendable {
    let contractVersion: Int
    let schemaVersion: Int
    let organizationId: String
    let branchId: String?
    let supplierId: String?
    let currency: String
    let effectiveFrom: String?
    let effectiveTo: String?
    let snapshotAt: String
    let returnedFactCount: Int
    let hasMore: Bool
    let nextCursorAvailable: Bool
    let maxPageSize: Int
    let supportedFactTypes: [String]
    let reservedFactTypes: [String]
    let replayMode: String
    let readOnly: Bool
    let accountingEntriesGenerated: Bool
    let postable: Bool
    let limitations: [String]
}

enum AdminProcurementAccountingCompletenessClassification: String, Equatable, Sendable {
    case passExisting = "PASS_EXISTING"
    case documentFutureGap = "DOCUMENT_FUTURE_GAP"
    case notApplicable = "NOT_APPLICABLE"

    var title: String {
        switch self {
        case .passExisting: return "Fuente lista"
        case .documentFutureGap: return "Brecha futura"
        case .notApplicable: return "Fuera de 27R"
        }
    }

    var systemImage: String {
        switch self {
        case .passExisting: return "checkmark.circle.fill"
        case .documentFutureGap: return "exclamationmark.triangle.fill"
        case .notApplicable: return "arrow.forward.circle.fill"
        }
    }
}

struct AdminProcurementAccountingCompletenessItem: Identifiable, Equatable, Sendable {
    let id: String
    let title: String
    let displayTitle: String
    let authoritativeEvidence: String
    let v1ReplayStatus: String
    let classification: AdminProcurementAccountingCompletenessClassification
    let classificationNote: String?
    let futureOwnerAction: String
}

struct AdminProcurementAccountingCompletenessMatrix: Equatable, Sendable {
    let contractVersion: Int
    let matrixVersion: String
    let acceptedStage: String
    let organizationId: String
    let currency: String
    let scope: String
    let sourceDocument: String
    let totalItemCount: Int
    let passExistingCount: Int
    let futureGapCount: Int
    let notApplicableCount: Int
    let items: [AdminProcurementAccountingCompletenessItem]
    let readOnly: Bool
    let accountingEntriesGenerated: Bool
    let postable: Bool
    let limitations: [String]
}

struct AdminProcurementContractSnapshot: Equatable, Sendable {
    let catalog: AdminProcurementReportCatalog
    let payableHealth: AdminProcurementOperationalHealth
    let financeHealth: AdminProcurementFinanceHealth
    let financeSourceFactReplayReadiness: AdminProcurementFinanceSourceFactReplayReadiness
    let accountingCompletenessMatrix: AdminProcurementAccountingCompletenessMatrix
}

enum AdminProcurementReadinessStatus: String, Equatable, Sendable {
    case ready
    case warning
    case blocked

    var title: String {
        switch self {
        case .ready: return "Listo"
        case .warning: return "Revisar"
        case .blocked: return "Bloqueado"
        }
    }

    var systemImage: String {
        switch self {
        case .ready: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .blocked: return "xmark.octagon.fill"
        }
    }
}

struct AdminProcurementReadinessCheck: Identifiable, Equatable, Sendable {
    let id: String
    let title: String
    let detail: String
    let status: AdminProcurementReadinessStatus
    let required: Bool
}

struct AdminProcurementReadinessSection: Identifiable, Equatable, Sendable {
    let id: String
    let title: String
    let checks: [AdminProcurementReadinessCheck]
}

struct AdminProcurementReadinessReport: Equatable, Sendable {
    let organizationName: String
    let branchName: String
    let currency: String
    let generatedAt: Date
    let backendGeneratedAt: String
    let reportCount: Int?
    let matchingPayableCount: Int?
    let openPayableBalance: AdminProcurementMoney?
    let financeFactCount: Int?
    let financeSourceFactSchemaVersion: Int?
    let financeSourceFactTypeCount: Int?
    let accountingCompletenessMatrix: AdminProcurementAccountingCompletenessMatrix?
    let sections: [AdminProcurementReadinessSection]

    var checks: [AdminProcurementReadinessCheck] { sections.flatMap(\.checks) }
    var blockedCount: Int { checks.filter { $0.required && $0.status == .blocked }.count }
    var warningCount: Int { checks.filter { $0.status == .warning }.count }
    var readyCount: Int { checks.filter { $0.status == .ready }.count }
    var isReady: Bool { blockedCount == 0 }

    var overallStatus: AdminProcurementReadinessStatus {
        if !isReady { return .blocked }
        return warningCount == 0 ? .ready : .warning
    }

    var summaryTitle: String {
        switch overallStatus {
        case .ready: return "Compras listas para control administrativo"
        case .warning: return "Compras operables con permisos pendientes"
        case .blocked: return "Readiness de compras bloqueado"
        }
    }

    var summaryMessage: String {
        if blockedCount > 0 {
            return "Hay \(blockedCount) bloqueos en módulos, contratos o reconciliación backend."
        }
        if warningCount > 0 {
            return "Los contratos están sanos; el usuario actual tiene \(warningCount) capacidades por revisar."
        }
        return "Módulos, contratos, reconciliación y permisos de consulta están listos."
    }
}

enum AdminProcurementReadinessAccess {
    static let requiredPermissions: Set<String> = [
        PermissionCatalog.modulesView,
        PermissionCatalog.reportsDashboardView,
        PermissionCatalog.procurementAuditView,
        PermissionCatalog.purchaseOrdersView,
        PermissionCatalog.purchaseOrdersCostView,
        PermissionCatalog.purchaseReceiptsView,
        PermissionCatalog.supplierDocumentsView,
        PermissionCatalog.payablesView,
        PermissionCatalog.payablesAgingView,
        PermissionCatalog.supplierPaymentsView
    ]

    static func allows(_ permissions: Set<String>) -> Bool {
        let permissionSet = PermissionSet(permissions)
        let canInspectModules = permissionSet.canAny([
            PermissionCatalog.modulesView,
            PermissionCatalog.modulesManage
        ])
        let remaining = requiredPermissions.subtracting([PermissionCatalog.modulesView])
        return canInspectModules && remaining.allSatisfy { permissionSet.can($0) }
    }
}
