//
//  DashboardDTOs.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import Foundation

struct DashboardOperationalReportResponseDTO: Decodable, Sendable {
    let organizationId: String?
    let branchId: String?
    let activityId: String?
    let businessDate: String?
    let from: String?
    let to: String?
    let sales: DashboardSalesSummaryReportDTO?
    let cash: DashboardCashSummaryReportDTO?
    let tax: DashboardTaxSummaryReportDTO?
    let currentCashSession: DashboardCashSessionDTO?
    let pendingReceivables: DashboardMoneyDTO?
    let topItems: [DashboardTopItemDTO]?
    let alerts: [DashboardOperationalAlertDTO]?
    let signature: DashboardSignatureSummaryDTO?
}

struct DashboardMoneyDTO: Decodable, Sendable {
    let amount: String?
    let currency: String?
}

struct DashboardSalesSummaryReportDTO: Decodable, Sendable {
    let organizationId: String?
    let branchId: String?
    let activityId: String?
    let from: String?
    let to: String?
    let saleCount: Int?
    let closedSaleCount: Int?
    let canceledSaleCount: Int?
    let openSaleCount: Int?
    let itemCount: Int?
    let subtotal: DashboardMoneyDTO?
    let discountTotal: DashboardMoneyDTO?
    let taxTotal: DashboardMoneyDTO?
    let grandTotal: DashboardMoneyDTO?
    let paidTotal: DashboardMoneyDTO?
    let receivableTotal: DashboardMoneyDTO?
    let byOperationalStatus: [DashboardStatusCountDTO]?
    let byPaymentStatus: [DashboardStatusCountDTO]?
    let byDocumentStatus: [DashboardStatusCountDTO]?
    let topItems: [DashboardTopItemDTO]?
}

struct DashboardCashSummaryReportDTO: Decodable, Sendable {
    let organizationId: String?
    let branchId: String?
    let from: String?
    let to: String?
    let openSessionCount: Int?
    let closedSessionCount: Int?
    let movementCount: Int?
    let cashInTotal: DashboardMoneyDTO?
    let cashOutTotal: DashboardMoneyDTO?
    let netCashMovement: DashboardMoneyDTO?
    let expectedOpenCashTotal: DashboardMoneyDTO?
    let countedClosedCashTotal: DashboardMoneyDTO?
    let differenceClosedCashTotal: DashboardMoneyDTO?
    let byMovementType: [DashboardStatusCountDTO]?
}

struct DashboardTaxSummaryReportDTO: Decodable, Sendable {
    let organizationId: String?
    let branchId: String?
    let activityId: String?
    let from: String?
    let to: String?
    let documentCount: Int?
    let authorizedDocumentCount: Int?
    let documentGrandTotal: DashboardMoneyDTO?
    let taxTotal: DashboardMoneyDTO?
    let byTaxRate: [DashboardTaxRateLineDTO]?
}

struct DashboardTaxRateLineDTO: Decodable, Sendable {
    let taxCode: String?
    let rateCode: String?
    let rate: String?
    let taxableBase: DashboardMoneyDTO?
    let taxAmount: DashboardMoneyDTO?
    let documentCount: Int?
}

struct DashboardTopItemDTO: Decodable, Sendable {
    let catalogItemId: String?
    let name: String?
    let quantity: String?
    let netTotal: DashboardMoneyDTO?
    let lineTotal: DashboardMoneyDTO?
}

struct DashboardStatusCountDTO: Decodable, Sendable {
    let status: String?
    let count: Int?
}

struct DashboardCashSessionDTO: Decodable, Sendable {
    let id: String?
    let organizationId: String?
    let branchId: String?
    let openedBy: String?
    let openedAt: String?
    let status: String?
    let openingBalance: DashboardMoneyDTO?
    let expectedCashAmount: DashboardMoneyDTO?
    let countedCashAmount: DashboardMoneyDTO?
    let differenceAmount: DashboardMoneyDTO?
    let movementCount: Int?
    let closingStartedAt: String?
    let closedAt: String?
    let canceledAt: String?
}

struct DashboardOperationalAlertDTO: Decodable, Sendable {
    let code: String?
    let severity: String?
    let message: String?
    let actionHint: String?
    let title: String?
    let category: String?
    let destination: String?
}

struct DashboardSignatureSummaryDTO: Decodable, Sendable {
    let status: String?
    let ownerName: String?
    let expiresAt: String?
    let daysUntilExpiration: Int?
    let lastTestStatus: String?
}
