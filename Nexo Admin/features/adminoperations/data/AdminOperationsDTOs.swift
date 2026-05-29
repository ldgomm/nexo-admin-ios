//
//  AdminOperationsDTOs.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import Foundation

struct AdminOperationsMoneyDTO: Codable, Sendable {
    let amount: String
    let currency: String
}

struct AdminStatusCountDTO: Codable, Sendable {
    let status: String
    let count: Int
}

struct AdminTopItemReportLineDTO: Codable, Sendable {
    let catalogItemId: String?
    let name: String
    let quantity: String
    let netTotal: AdminOperationsMoneyDTO
    let lineTotal: AdminOperationsMoneyDTO
}

struct AdminOperationalAlertDTO: Codable, Sendable {
    let code: String
    let severity: String
    let message: String
    let actionHint: String?
}

struct AdminCashMovementDTO: Codable, Sendable {
    let id: String
    let organizationId: String?
    let cashSessionId: String
    let branchId: String?
    let type: String
    let direction: String
    let amount: AdminOperationsMoneyDTO
    let occurredAt: String
    let referenceType: String?
    let referenceId: String?
    let notes: String?
}

struct AdminCashSessionDTO: Codable, Sendable {
    let id: String
    let organizationId: String?
    let branchId: String?
    let openedBy: String?
    let openedAt: String
    let status: String
    let openingBalance: AdminOperationsMoneyDTO
    let expectedCashAmount: AdminOperationsMoneyDTO
    let countedCashAmount: AdminOperationsMoneyDTO?
    let differenceAmount: AdminOperationsMoneyDTO?
    let movementCount: Int
    let closingStartedAt: String?
    let closedAt: String?
    let canceledAt: String?
    let movements: [AdminCashMovementDTO]
}

struct AdminCashSessionsResponseDTO: Codable, Sendable {
    let cashSessions: [AdminCashSessionDTO]
}

struct AdminCashSessionEnvelopeResponseDTO: Codable, Sendable {
    let cashSession: AdminCashSessionDTO?
}

struct AdminSalesSummaryReportDTO: Codable, Sendable {
    let organizationId: String?
    let branchId: String?
    let activityId: String?
    let from: String
    let to: String
    let saleCount: Int
    let closedSaleCount: Int
    let canceledSaleCount: Int
    let openSaleCount: Int
    let itemCount: Int
    let subtotal: AdminOperationsMoneyDTO
    let discountTotal: AdminOperationsMoneyDTO
    let taxTotal: AdminOperationsMoneyDTO
    let grandTotal: AdminOperationsMoneyDTO
    let paidTotal: AdminOperationsMoneyDTO
    let receivableTotal: AdminOperationsMoneyDTO
    let byOperationalStatus: [AdminStatusCountDTO]
    let byPaymentStatus: [AdminStatusCountDTO]
    let byDocumentStatus: [AdminStatusCountDTO]
    let topItems: [AdminTopItemReportLineDTO]
}

struct AdminCashSummaryReportDTO: Codable, Sendable {
    let organizationId: String?
    let branchId: String?
    let from: String
    let to: String
    let openSessionCount: Int
    let closedSessionCount: Int
    let movementCount: Int
    let cashInTotal: AdminOperationsMoneyDTO
    let cashOutTotal: AdminOperationsMoneyDTO
    let netCashMovement: AdminOperationsMoneyDTO
    let expectedOpenCashTotal: AdminOperationsMoneyDTO
    let countedClosedCashTotal: AdminOperationsMoneyDTO
    let differenceClosedCashTotal: AdminOperationsMoneyDTO
    let byMovementType: [AdminStatusCountDTO]
}

struct AdminTaxSummaryLineDTO: Codable, Sendable {
    let taxCode: String
    let rateCode: String
    let rate: String
    let taxableBase: AdminOperationsMoneyDTO
    let taxAmount: AdminOperationsMoneyDTO
    let documentCount: Int
}

struct AdminTaxSummaryReportDTO: Codable, Sendable {
    let organizationId: String?
    let branchId: String?
    let activityId: String?
    let from: String
    let to: String
    let documentCount: Int
    let authorizedDocumentCount: Int
    let documentGrandTotal: AdminOperationsMoneyDTO
    let taxTotal: AdminOperationsMoneyDTO
    let byTaxRate: [AdminTaxSummaryLineDTO]
}

struct AdminOperationalTodayReportDTO: Codable, Sendable {
    let organizationId: String?
    let branchId: String?
    let activityId: String?
    let businessDate: String
    let from: String
    let to: String
    let sales: AdminSalesSummaryReportDTO
    let cash: AdminCashSummaryReportDTO
    let tax: AdminTaxSummaryReportDTO
    let currentCashSession: AdminCashSessionDTO?
    let pendingReceivables: AdminOperationsMoneyDTO
    let topItems: [AdminTopItemReportLineDTO]
    let alerts: [AdminOperationalAlertDTO]
}

struct AdminAuditLogsResponseDTO: Codable, Sendable {
    let logs: [AdminAuditLogRecordDTO]
}

struct AdminAuditTimelineResponseDTO: Codable, Sendable {
    let items: [AdminAuditTimelineItemDTO]
}

struct AdminAuditLogRecordDTO: Codable, Sendable {
    let id: String
    let organizationId: String?
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
}

struct AdminAuditTimelineItemDTO: Codable, Sendable {
    let id: String
    let organizationId: String?
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

struct AdminSupportDiagnosticsResponseDTO: Codable, Sendable {
    let report: AdminSupportDiagnosticsReportDTO
}

struct AdminSupportDiagnosticsReportDTO: Codable, Sendable {
    let organizationId: String?
    let generatedAt: String
    let status: String
    let checks: [AdminSupportDiagnosticCheckDTO]
    let counters: [AdminSupportCounterDTO]
    let warnings: [String]
}

struct AdminSupportDiagnosticCheckDTO: Codable, Sendable {
    let code: String
    let status: String
    let message: String
    let actionHint: String?
}

struct AdminSupportCounterDTO: Codable, Sendable {
    let code: String
    let label: String
    let value: Int
}
