//
//  Archivo: MockDashboardData.swift
//  Proyecto: Nexo Admin
//  Autor: José Ruiz
//  Fecha: 21/5/26
//
//  Sprint 13iOS-B — Dashboard administrativo
//

import Foundation

enum MockDashboardData {
    static let summary = DashboardSummary(
        generatedAt: "2026-05-21T00:00:00Z",
        sales: DashboardSalesSummary(
            grossTotal: DashboardMoney(amount: 188.40, currency: "USD"),
            netTotal: DashboardMoney(amount: 176.00, currency: "USD"),
            collectedTotal: DashboardMoney(amount: 154.00, currency: "USD"),
            receivableTotal: DashboardMoney(amount: 22.00, currency: "USD"),
            salesCount: 14,
            canceledCount: 1,
            pendingCount: 3,
            averageTicket: DashboardMoney(amount: 12.57, currency: "USD")
        ),
        cash: DashboardCashSummary(
            status: "open",
            openedBy: "José Ruiz",
            openedAt: "2026-05-21T09:00:00Z",
            expectedCash: DashboardMoney(amount: 96.00, currency: "USD"),
            cashSales: DashboardMoney(amount: 80.00, currency: "USD"),
            cashInflow: DashboardMoney(amount: 20.00, currency: "USD"),
            cashOutflow: DashboardMoney(amount: 4.00, currency: "USD"),
            difference: nil
        ),
        documents: DashboardDocumentSummary(
            authorizedCount: 9,
            rejectedCount: 1,
            pendingCount: 2,
            returnedCount: 0,
            lastAuthorizedAt: "2026-05-21T11:30:00Z"
        ),
        signature: DashboardSignatureSummary(
            status: "valid",
            ownerName: "ALTOS DEL MURCO",
            expiresAt: "2026-06-12T00:00:00Z",
            daysUntilExpiration: 22,
            lastTestStatus: "success"
        ),
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
