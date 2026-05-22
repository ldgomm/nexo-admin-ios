//
//  AdminOperationsModels.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import Foundation

struct AdminOperationsMoney: Codable, Equatable, Sendable {
    let amount: String
    let currency: String

    static let zero = AdminOperationsMoney(amount: "0.00", currency: "USD")

    var decimalValue: Decimal {
        Decimal(string: amount.replacingOccurrences(of: ",", with: ".")) ?? .zero
    }

    var formatted: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter.string(from: decimalValue as NSDecimalNumber) ?? "\(currency) \(amount)"
    }
}

struct AdminOperationsDateRange: Equatable, Sendable {
    var from: Date
    var to: Date
    var timezone: String

    static func today(calendar: Calendar = .current, timezone: String = TimeZone.current.identifier) -> AdminOperationsDateRange {
        let start = calendar.startOfDay(for: Date())
        let end = calendar.date(byAdding: .day, value: 1, to: start) ?? Date()
        return AdminOperationsDateRange(from: start, to: end, timezone: timezone)
    }

    static func lastSevenDays(calendar: Calendar = .current, timezone: String = TimeZone.current.identifier) -> AdminOperationsDateRange {
        let end = Date()
        let start = calendar.date(byAdding: .day, value: -7, to: end) ?? end
        return AdminOperationsDateRange(from: start, to: end, timezone: timezone)
    }

    static func lastThirtyDays(calendar: Calendar = .current, timezone: String = TimeZone.current.identifier) -> AdminOperationsDateRange {
        let end = Date()
        let start = calendar.date(byAdding: .day, value: -30, to: end) ?? end
        return AdminOperationsDateRange(from: start, to: end, timezone: timezone)
    }
}

struct AdminStatusCount: Identifiable, Codable, Equatable, Sendable {
    let status: String
    let count: Int
    var id: String { status }
}

struct AdminTopItemReportLine: Identifiable, Codable, Equatable, Sendable {
    let catalogItemId: String?
    let name: String
    let quantity: String
    let netTotal: AdminOperationsMoney
    let lineTotal: AdminOperationsMoney
    var id: String { catalogItemId ?? name }
}

struct AdminOperationalAlert: Identifiable, Codable, Equatable, Sendable {
    let code: String
    let severity: String
    let message: String
    let actionHint: String?
    var id: String { code }
}

struct AdminCashMovement: Identifiable, Codable, Equatable, Sendable {
    let id: String
    let cashSessionId: String
    let branchId: String?
    let type: String
    let direction: String
    let amount: AdminOperationsMoney
    let occurredAt: String
    let referenceType: String?
    let referenceId: String?
    let notes: String?

    var signedAmountTitle: String {
        direction.lowercased() == "out" ? "-\(amount.formatted)" : amount.formatted
    }
}

struct AdminCashSession: Identifiable, Codable, Equatable, Sendable {
    let id: String
    let branchId: String?
    let openedBy: String?
    let openedAt: String
    let status: String
    let openingBalance: AdminOperationsMoney
    let expectedCashAmount: AdminOperationsMoney
    let countedCashAmount: AdminOperationsMoney?
    let differenceAmount: AdminOperationsMoney?
    let movementCount: Int
    let closingStartedAt: String?
    let closedAt: String?
    let canceledAt: String?
    let movements: [AdminCashMovement]

    var isOpen: Bool { status.lowercased() == "open" || closedAt == nil && canceledAt == nil }
    var displayTitle: String { isOpen ? "Caja abierta" : "Caja cerrada" }
}

struct AdminSalesSummaryReport: Codable, Equatable, Sendable {
    let from: String
    let to: String
    let saleCount: Int
    let closedSaleCount: Int
    let canceledSaleCount: Int
    let openSaleCount: Int
    let itemCount: Int
    let subtotal: AdminOperationsMoney
    let discountTotal: AdminOperationsMoney
    let taxTotal: AdminOperationsMoney
    let grandTotal: AdminOperationsMoney
    let paidTotal: AdminOperationsMoney
    let receivableTotal: AdminOperationsMoney
    let byOperationalStatus: [AdminStatusCount]
    let byPaymentStatus: [AdminStatusCount]
    let byDocumentStatus: [AdminStatusCount]
    let topItems: [AdminTopItemReportLine]
}

struct AdminCashSummaryReport: Codable, Equatable, Sendable {
    let from: String
    let to: String
    let openSessionCount: Int
    let closedSessionCount: Int
    let movementCount: Int
    let cashInTotal: AdminOperationsMoney
    let cashOutTotal: AdminOperationsMoney
    let netCashMovement: AdminOperationsMoney
    let expectedOpenCashTotal: AdminOperationsMoney
    let countedClosedCashTotal: AdminOperationsMoney
    let differenceClosedCashTotal: AdminOperationsMoney
    let byMovementType: [AdminStatusCount]
}

struct AdminTaxSummaryLine: Identifiable, Codable, Equatable, Sendable {
    let taxCode: String
    let rateCode: String
    let rate: String
    let taxableBase: AdminOperationsMoney
    let taxAmount: AdminOperationsMoney
    let documentCount: Int
    var id: String { "\(taxCode)-\(rateCode)" }
}

struct AdminTaxSummaryReport: Codable, Equatable, Sendable {
    let from: String
    let to: String
    let documentCount: Int
    let authorizedDocumentCount: Int
    let documentGrandTotal: AdminOperationsMoney
    let taxTotal: AdminOperationsMoney
    let byTaxRate: [AdminTaxSummaryLine]
}

struct AdminOperationalTodayReport: Codable, Equatable, Sendable {
    let businessDate: String
    let from: String
    let to: String
    let sales: AdminSalesSummaryReport
    let cash: AdminCashSummaryReport
    let tax: AdminTaxSummaryReport
    let currentCashSession: AdminCashSession?
    let pendingReceivables: AdminOperationsMoney
    let topItems: [AdminTopItemReportLine]
    let alerts: [AdminOperationalAlert]
}

struct AdminAuditLogRecord: Identifiable, Codable, Equatable, Sendable {
    let id: String
    let source: String
    let surface: String
    let action: String
    let actorUserId: String?
    let targetType: String?
    let targetId: String?
    let reason: String?
    let message: String?
    let severity: String
    let correlationId: String?
    let before: [String: String?]
    let after: [String: String?]
    let metadata: [String: String?]
    let createdAt: String

    var title: String { action.replacingOccurrences(of: "_", with: " ").capitalized }
    var subtitle: String { [surface, actorUserId, targetType, targetId].compactMap { $0 }.joined(separator: " • ") }
}

struct AdminAuditTimelineItem: Identifiable, Codable, Equatable, Sendable {
    let id: String
    let occurredAt: String
    let source: String
    let surface: String
    let title: String
    let description: String
    let actorUserId: String?
    let targetType: String?
    let targetId: String?
    let severity: String
    let reason: String?
    let metadata: [String: String?]
}

struct AdminSupportDiagnosticCheck: Identifiable, Codable, Equatable, Sendable {
    let code: String
    let status: String
    let message: String
    let actionHint: String?
    var id: String { code }
}

struct AdminSupportCounter: Identifiable, Codable, Equatable, Sendable {
    let code: String
    let label: String
    let value: Int
    var id: String { code }
}

struct AdminSupportDiagnosticsReport: Codable, Equatable, Sendable {
    let generatedAt: String
    let status: String
    let checks: [AdminSupportDiagnosticCheck]
    let counters: [AdminSupportCounter]
    let warnings: [String]
}

struct AdminAuditFilter: Equatable, Sendable {
    var query: String = ""
    var actorUserId: String = ""
    var action: String = ""
    var surface: String = ""
    var targetType: String = ""
    var targetId: String = ""
    var severity: String = ""
    var range: AdminOperationsDateRange = .lastSevenDays()
    var limit: Int = 100
}
