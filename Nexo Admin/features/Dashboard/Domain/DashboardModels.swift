//
//  DashboardModels.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import Foundation

enum DashboardAlertSeverity: String, Codable, Equatable, Sendable {
    case info
    case warning
    case critical
    case success

    var priority: Int {
        switch self {
        case .critical: return 0
        case .warning: return 1
        case .info: return 2
        case .success: return 3
        }
    }

    var title: String {
        switch self {
        case .critical: return "Crítica"
        case .warning: return "Advertencia"
        case .info: return "Info"
        case .success: return "OK"
        }
    }
}

enum DashboardAlertCategory: String, Codable, Equatable, Sendable {
    case operational
    case sri
    case signature
    case cash
    case document
    case catalog
    case user
    case receivable
    case tax
    case unknown

    var title: String {
        switch self {
        case .operational: return "Operación"
        case .sri: return "SRI"
        case .signature: return "Firma"
        case .cash: return "Caja"
        case .document: return "Comprobantes"
        case .catalog: return "Catálogo"
        case .user: return "Usuarios"
        case .receivable: return "Cuentas por cobrar"
        case .tax: return "Tributario"
        case .unknown: return "General"
        }
    }
}

struct DashboardMoney: Codable, Equatable, Sendable {
    let amount: Decimal
    let currency: String

    static let zeroUSD = DashboardMoney(amount: 0, currency: "USD")

    var formatted: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.currencySymbol = currency == "USD" ? "$" : currency
        formatter.locale = Locale(identifier: "es_EC")
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: amount as NSDecimalNumber) ?? "\(currency) \(amount)"
    }

    func divided(by denominator: Int) -> DashboardMoney {
        guard denominator > 0 else { return DashboardMoney(amount: 0, currency: currency) }
        let result = NSDecimalNumber(decimal: amount).dividing(by: NSDecimalNumber(value: denominator)).decimalValue
        return DashboardMoney(amount: result, currency: currency)
    }
}

struct DashboardStatusCount: Identifiable, Equatable, Sendable {
    let status: String
    let count: Int

    var id: String { status }

    var label: String {
        status
            .replacingOccurrences(of: "_", with: " ")
            .capitalized
    }
}

struct DashboardTopItem: Identifiable, Equatable, Sendable {
    let id: String
    let catalogItemId: String?
    let name: String
    let quantity: Decimal
    let netTotal: DashboardMoney
    let lineTotal: DashboardMoney

    var quantityText: String {
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        return formatter.string(from: quantity as NSDecimalNumber) ?? "\(quantity)"
    }
}

struct DashboardSalesSummary: Equatable, Sendable {
    let grossTotal: DashboardMoney
    let netTotal: DashboardMoney
    let collectedTotal: DashboardMoney
    let receivableTotal: DashboardMoney
    let salesCount: Int
    let closedCount: Int
    let canceledCount: Int
    let pendingCount: Int
    let itemCount: Int
    let averageTicket: DashboardMoney
    let byOperationalStatus: [DashboardStatusCount]
    let byPaymentStatus: [DashboardStatusCount]
    let byDocumentStatus: [DashboardStatusCount]

    static let empty = DashboardSalesSummary(
        grossTotal: .zeroUSD,
        netTotal: .zeroUSD,
        collectedTotal: .zeroUSD,
        receivableTotal: .zeroUSD,
        salesCount: 0,
        closedCount: 0,
        canceledCount: 0,
        pendingCount: 0,
        itemCount: 0,
        averageTicket: .zeroUSD,
        byOperationalStatus: [],
        byPaymentStatus: [],
        byDocumentStatus: []
    )
}

struct DashboardCashSummary: Equatable, Sendable {
    let status: String
    let openedBy: String?
    let openedAt: String?
    let openSessionCount: Int
    let closedSessionCount: Int
    let movementCount: Int
    let expectedCash: DashboardMoney
    let cashSales: DashboardMoney
    let cashInflow: DashboardMoney
    let cashOutflow: DashboardMoney
    let netCashMovement: DashboardMoney
    let difference: DashboardMoney?
    let byMovementType: [DashboardStatusCount]

    var isOpen: Bool { status.lowercased() == "open" || openSessionCount > 0 }

    static let empty = DashboardCashSummary(
        status: "closed",
        openedBy: nil,
        openedAt: nil,
        openSessionCount: 0,
        closedSessionCount: 0,
        movementCount: 0,
        expectedCash: .zeroUSD,
        cashSales: .zeroUSD,
        cashInflow: .zeroUSD,
        cashOutflow: .zeroUSD,
        netCashMovement: .zeroUSD,
        difference: nil,
        byMovementType: []
    )
}

struct DashboardDocumentSummary: Equatable, Sendable {
    let totalCount: Int
    let authorizedCount: Int
    let rejectedCount: Int
    let pendingCount: Int
    let returnedCount: Int
    let documentGrandTotal: DashboardMoney
    let taxTotal: DashboardMoney
    let lastAuthorizedAt: String?

    static let empty = DashboardDocumentSummary(
        totalCount: 0,
        authorizedCount: 0,
        rejectedCount: 0,
        pendingCount: 0,
        returnedCount: 0,
        documentGrandTotal: .zeroUSD,
        taxTotal: .zeroUSD,
        lastAuthorizedAt: nil
    )
}

struct DashboardSignatureSummary: Equatable, Sendable {
    let status: String
    let ownerName: String?
    let expiresAt: String?
    let daysUntilExpiration: Int?
    let lastTestStatus: String?
    let sourceAvailable: Bool

    var requiresAttention: Bool {
        guard sourceAvailable else { return false }
        let normalized = status.lowercased()
        if ["expired", "revoked", "test_failed", "blocked", "not_configured"].contains(normalized) {
            return true
        }
        if let daysUntilExpiration { return daysUntilExpiration <= 30 }
        return false
    }

    static let unavailable = DashboardSignatureSummary(
        status: "unavailable",
        ownerName: nil,
        expiresAt: nil,
        daysUntilExpiration: nil,
        lastTestStatus: nil,
        sourceAvailable: false
    )

    static let empty = DashboardSignatureSummary(
        status: "not_configured",
        ownerName: nil,
        expiresAt: nil,
        daysUntilExpiration: nil,
        lastTestStatus: nil,
        sourceAvailable: true
    )
}

struct DashboardTaxSummary: Equatable, Sendable {
    let documentCount: Int
    let authorizedDocumentCount: Int
    let taxTotal: DashboardMoney
    let byTaxRate: [DashboardTaxRateLine]

    static let empty = DashboardTaxSummary(
        documentCount: 0,
        authorizedDocumentCount: 0,
        taxTotal: .zeroUSD,
        byTaxRate: []
    )
}

struct DashboardTaxRateLine: Identifiable, Equatable, Sendable {
    let taxCode: String
    let rateCode: String
    let rate: Decimal
    let taxableBase: DashboardMoney
    let taxAmount: DashboardMoney
    let documentCount: Int

    var id: String { "\(taxCode)-\(rateCode)-\(rate)" }
}

struct DashboardAlert: Identifiable, Equatable, Sendable {
    let id: String
    let title: String
    let message: String
    let severity: DashboardAlertSeverity
    let category: DashboardAlertCategory
    let createdAt: String?
    let actionTitle: String?
    let destination: DashboardQuickActionDestination?
}

struct DashboardQuickAction: Identifiable, Equatable, Sendable {
    let id: String
    let title: String
    let subtitle: String
    let systemImage: String
    let requiredPermissions: Set<String>
    let destination: DashboardQuickActionDestination

    func isVisible(for permissions: Set<String>) -> Bool {
        permissions.contains(PermissionCatalog.all) || requiredPermissions.isEmpty || !permissions.isDisjoint(with: requiredPermissions)
    }
}

enum DashboardQuickActionDestination: String, Codable, Equatable, Sendable {
    case users
    case roles
    case business
    case branches
    case emissionPoints
    case catalog
    case catalogRequests
    case tax
    case signature
    case sri
    case cash
    case documents
    case audit
    case support
}

struct DashboardSummary: Equatable, Sendable {
    let generatedAt: String
    let businessDate: String
    let period: DashboardPeriod
    let sales: DashboardSalesSummary
    let cash: DashboardCashSummary
    let documents: DashboardDocumentSummary
    let tax: DashboardTaxSummary
    let signature: DashboardSignatureSummary
    let pendingReceivables: DashboardMoney
    let topItems: [DashboardTopItem]
    let alerts: [DashboardAlert]
    let quickActions: [DashboardQuickAction]

    static let empty = DashboardSummary(
        generatedAt: "",
        businessDate: "",
        period: .today,
        sales: .empty,
        cash: .empty,
        documents: .empty,
        tax: .empty,
        signature: .unavailable,
        pendingReceivables: .zeroUSD,
        topItems: [],
        alerts: [],
        quickActions: []
    )
}
