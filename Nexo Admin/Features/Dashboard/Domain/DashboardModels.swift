//
//  DashboardModels.swift
//  Nexo Admin
//
//  Created by José Ruiz on 20/5/26.
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
}

enum DashboardAlertCategory: String, Codable, Equatable, Sendable {
    case operational
    case sri
    case signature
    case cash
    case document
    case catalog
    case user
    case unknown
}

struct DashboardMoney: Codable, Equatable, Sendable {
    let amount: Decimal
    let currency: String

    static let zeroUSD = DashboardMoney(amount: 0, currency: "USD")

    var formatted: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: amount as NSDecimalNumber) ?? "\(currency) \(amount)"
    }
}

struct DashboardSalesSummary: Equatable, Sendable {
    let grossTotal: DashboardMoney
    let netTotal: DashboardMoney
    let collectedTotal: DashboardMoney
    let receivableTotal: DashboardMoney
    let salesCount: Int
    let canceledCount: Int
    let pendingCount: Int
    let averageTicket: DashboardMoney

    static let empty = DashboardSalesSummary(
        grossTotal: .zeroUSD,
        netTotal: .zeroUSD,
        collectedTotal: .zeroUSD,
        receivableTotal: .zeroUSD,
        salesCount: 0,
        canceledCount: 0,
        pendingCount: 0,
        averageTicket: .zeroUSD
    )
}

struct DashboardCashSummary: Equatable, Sendable {
    let status: String
    let openedBy: String?
    let openedAt: String?
    let expectedCash: DashboardMoney
    let cashSales: DashboardMoney
    let cashInflow: DashboardMoney
    let cashOutflow: DashboardMoney
    let difference: DashboardMoney?

    var isOpen: Bool { status.lowercased() == "open" }

    static let empty = DashboardCashSummary(
        status: "closed",
        openedBy: nil,
        openedAt: nil,
        expectedCash: .zeroUSD,
        cashSales: .zeroUSD,
        cashInflow: .zeroUSD,
        cashOutflow: .zeroUSD,
        difference: nil
    )
}

struct DashboardDocumentSummary: Equatable, Sendable {
    let authorizedCount: Int
    let rejectedCount: Int
    let pendingCount: Int
    let returnedCount: Int
    let lastAuthorizedAt: String?

    static let empty = DashboardDocumentSummary(
        authorizedCount: 0,
        rejectedCount: 0,
        pendingCount: 0,
        returnedCount: 0,
        lastAuthorizedAt: nil
    )
}

struct DashboardSignatureSummary: Equatable, Sendable {
    let status: String
    let ownerName: String?
    let expiresAt: String?
    let daysUntilExpiration: Int?
    let lastTestStatus: String?

    var requiresAttention: Bool {
        let normalized = status.lowercased()
        if ["expired", "revoked", "test_failed", "blocked", "not_configured"].contains(normalized) {
            return true
        }
        if let daysUntilExpiration { return daysUntilExpiration <= 30 }
        return false
    }

    static let empty = DashboardSignatureSummary(
        status: "not_configured",
        ownerName: nil,
        expiresAt: nil,
        daysUntilExpiration: nil,
        lastTestStatus: nil
    )
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
    let sales: DashboardSalesSummary
    let cash: DashboardCashSummary
    let documents: DashboardDocumentSummary
    let signature: DashboardSignatureSummary
    let alerts: [DashboardAlert]
    let quickActions: [DashboardQuickAction]

    static let empty = DashboardSummary(
        generatedAt: "",
        sales: .empty,
        cash: .empty,
        documents: .empty,
        signature: .empty,
        alerts: [],
        quickActions: []
    )
}
