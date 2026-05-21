//
//  DashboardDTOs.swift
//  Nexo Admin
//
//  Created by José Ruiz on 20/5/26.
//

import Foundation

struct DashboardSummaryResponseDTO: Decodable, Sendable {
    let generatedAt: String?
    let sales: DashboardSalesSummaryDTO?
    let cash: DashboardCashSummaryDTO?
    let documents: DashboardDocumentSummaryDTO?
    let signature: DashboardSignatureSummaryDTO?
    let alerts: [DashboardAlertDTO]?
}

struct DashboardMoneyDTO: Decodable, Sendable {
    let amount: String?
    let currency: String?
}

struct DashboardSalesSummaryDTO: Decodable, Sendable {
    let grossTotal: DashboardMoneyDTO?
    let netTotal: DashboardMoneyDTO?
    let collectedTotal: DashboardMoneyDTO?
    let receivableTotal: DashboardMoneyDTO?
    let salesCount: Int?
    let canceledCount: Int?
    let pendingCount: Int?
    let averageTicket: DashboardMoneyDTO?
}

struct DashboardCashSummaryDTO: Decodable, Sendable {
    let status: String?
    let openedBy: String?
    let openedAt: String?
    let expectedCash: DashboardMoneyDTO?
    let cashSales: DashboardMoneyDTO?
    let cashInflow: DashboardMoneyDTO?
    let cashOutflow: DashboardMoneyDTO?
    let difference: DashboardMoneyDTO?
}

struct DashboardDocumentSummaryDTO: Decodable, Sendable {
    let authorizedCount: Int?
    let rejectedCount: Int?
    let pendingCount: Int?
    let returnedCount: Int?
    let lastAuthorizedAt: String?
}

struct DashboardSignatureSummaryDTO: Decodable, Sendable {
    let status: String?
    let ownerName: String?
    let expiresAt: String?
    let daysUntilExpiration: Int?
    let lastTestStatus: String?
}

struct DashboardAlertDTO: Decodable, Sendable {
    let id: String?
    let title: String?
    let message: String?
    let severity: String?
    let category: String?
    let createdAt: String?
    let actionTitle: String?
    let destination: String?
}
