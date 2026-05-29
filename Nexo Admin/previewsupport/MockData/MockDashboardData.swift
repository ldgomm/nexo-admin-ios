//
//  MockDashboardData.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import Foundation

enum MockDashboardData {
    static let summary = DashboardSummary(
        generatedAt: "2026-05-21T23:59:59Z",
        businessDate: "2026-05-21",
        period: .today,
        sales: DashboardSalesSummary(
            grossTotal: DashboardMoney(amount: 188.40, currency: "USD"),
            netTotal: DashboardMoney(amount: 176.00, currency: "USD"),
            collectedTotal: DashboardMoney(amount: 154.00, currency: "USD"),
            receivableTotal: DashboardMoney(amount: 22.00, currency: "USD"),
            salesCount: 14,
            closedCount: 10,
            canceledCount: 1,
            pendingCount: 3,
            itemCount: 38,
            averageTicket: DashboardMoney(amount: 12.57, currency: "USD"),
            byOperationalStatus: [
                DashboardStatusCount(status: "closed", count: 10),
                DashboardStatusCount(status: "open", count: 3),
                DashboardStatusCount(status: "canceled", count: 1)
            ],
            byPaymentStatus: [
                DashboardStatusCount(status: "paid", count: 11),
                DashboardStatusCount(status: "partial", count: 2),
                DashboardStatusCount(status: "pending", count: 1)
            ],
            byDocumentStatus: [
                DashboardStatusCount(status: "authorized", count: 9),
                DashboardStatusCount(status: "pending", count: 2),
                DashboardStatusCount(status: "rejected", count: 1)
            ]
        ),
        cash: DashboardCashSummary(
            status: "open",
            openedBy: "José Ruiz",
            openedAt: "2026-05-21T09:00:00Z",
            openSessionCount: 1,
            closedSessionCount: 0,
            movementCount: 8,
            expectedCash: DashboardMoney(amount: 96.00, currency: "USD"),
            cashSales: DashboardMoney(amount: 80.00, currency: "USD"),
            cashInflow: DashboardMoney(amount: 100.00, currency: "USD"),
            cashOutflow: DashboardMoney(amount: 4.00, currency: "USD"),
            netCashMovement: DashboardMoney(amount: 96.00, currency: "USD"),
            difference: nil,
            byMovementType: [
                DashboardStatusCount(status: "sale", count: 6),
                DashboardStatusCount(status: "inflow", count: 1),
                DashboardStatusCount(status: "outflow", count: 1)
            ]
        ),
        documents: DashboardDocumentSummary(
            totalCount: 12,
            authorizedCount: 9,
            rejectedCount: 1,
            pendingCount: 2,
            returnedCount: 0,
            documentGrandTotal: DashboardMoney(amount: 176.00, currency: "USD"),
            taxTotal: DashboardMoney(amount: 22.96, currency: "USD"),
            lastAuthorizedAt: "2026-05-21T11:30:00Z"
        ),
        tax: DashboardTaxSummary(
            documentCount: 12,
            authorizedDocumentCount: 9,
            taxTotal: DashboardMoney(amount: 22.96, currency: "USD"),
            byTaxRate: [
                DashboardTaxRateLine(
                    taxCode: "2",
                    rateCode: "4",
                    rate: 15,
                    taxableBase: DashboardMoney(amount: 153.04, currency: "USD"),
                    taxAmount: DashboardMoney(amount: 22.96, currency: "USD"),
                    documentCount: 9
                )
            ]
        ),
        signature: DashboardSignatureSummary(
            status: "valid",
            ownerName: "ALTOS DEL MURCO",
            expiresAt: "2026-06-12T00:00:00Z",
            daysUntilExpiration: 22,
            lastTestStatus: "success",
            sourceAvailable: true
        ),
        pendingReceivables: DashboardMoney(amount: 22.00, currency: "USD"),
        topItems: [
            DashboardTopItem(
                id: "cuy",
                catalogItemId: "item_cuy",
                name: "Cuy entero",
                quantity: 4,
                netTotal: DashboardMoney(amount: 96.00, currency: "USD"),
                lineTotal: DashboardMoney(amount: 96.00, currency: "USD")
            ),
            DashboardTopItem(
                id: "borrego",
                catalogItemId: "item_borrego",
                name: "Borrego asado",
                quantity: 5,
                netTotal: DashboardMoney(amount: 50.00, currency: "USD"),
                lineTotal: DashboardMoney(amount: 50.00, currency: "USD")
            )
        ],
        alerts: [
            DashboardAlert(
                id: "alert_signature",
                title: "Firma por vencer",
                message: "La firma electrónica vence en menos de 30 días. Conviene renovarla antes de activar producción.",
                severity: .warning,
                category: .signature,
                createdAt: "2026-05-21T00:00:00Z",
                actionTitle: "Revisar firma",
                destination: .signature
            ),
            DashboardAlert(
                id: "alert_sri",
                title: "Comprobante rechazado",
                message: "Hay 1 comprobante con rechazo SRI pendiente de soporte.",
                severity: .critical,
                category: .sri,
                createdAt: "2026-05-21T00:00:00Z",
                actionTitle: "Ver comprobantes",
                destination: .documents
            )
        ],
        quickActions: DashboardQuickActionsFactory.actions
    )
}
