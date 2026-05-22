//
//  MockAdminOperationsData.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import Foundation

enum MockAdminOperationsData {
    static let money0 = AdminOperationsMoney(amount: "0.00", currency: "USD")
    static let moneySales = AdminOperationsMoney(amount: "482.50", currency: "USD")
    static let moneyPaid = AdminOperationsMoney(amount: "430.00", currency: "USD")
    static let moneyReceivable = AdminOperationsMoney(amount: "52.50", currency: "USD")
    static let moneyCash = AdminOperationsMoney(amount: "315.00", currency: "USD")

    static let movements = [
        AdminCashMovement(
            id: "mov_1",
            cashSessionId: "cash_1",
            branchId: "br_main",
            type: "sale_cash",
            direction: "in",
            amount: AdminOperationsMoney(amount: "220.00", currency: "USD"),
            occurredAt: "2026-05-21T15:10:00Z",
            referenceType: "sale",
            referenceId: "sale_1",
            notes: "Ventas efectivo"
        ),
        AdminCashMovement(
            id: "mov_2",
            cashSessionId: "cash_1",
            branchId: "br_main",
            type: "expense",
            direction: "out",
            amount: AdminOperationsMoney(amount: "15.00", currency: "USD"),
            occurredAt: "2026-05-21T16:30:00Z",
            referenceType: "expense",
            referenceId: "exp_1",
            notes: "Compra menor"
        ),
    ]

    static let currentCashSession = AdminCashSession(
        id: "cash_1",
        branchId: "br_main",
        openedBy: "usr_owner",
        openedAt: "2026-05-21T13:00:00Z",
        status: "open",
        openingBalance: AdminOperationsMoney(amount: "110.00", currency: "USD"),
        expectedCashAmount: moneyCash,
        countedCashAmount: nil,
        differenceAmount: nil,
        movementCount: movements.count,
        closingStartedAt: nil,
        closedAt: nil,
        canceledAt: nil,
        movements: movements
    )

    static let closedCashSession = AdminCashSession(
        id: "cash_0",
        branchId: "br_main",
        openedBy: "usr_owner",
        openedAt: "2026-05-20T13:00:00Z",
        status: "closed",
        openingBalance: AdminOperationsMoney(amount: "100.00", currency: "USD"),
        expectedCashAmount: AdminOperationsMoney(amount: "390.00", currency: "USD"),
        countedCashAmount: AdminOperationsMoney(amount: "388.00", currency: "USD"),
        differenceAmount: AdminOperationsMoney(amount: "-2.00", currency: "USD"),
        movementCount: 12,
        closingStartedAt: "2026-05-20T22:00:00Z",
        closedAt: "2026-05-20T22:10:00Z",
        canceledAt: nil,
        movements: []
    )

    static let topItems = [
        AdminTopItemReportLine(catalogItemId: "item_cuy", name: "Cuy entero", quantity: "8", netTotal: AdminOperationsMoney(amount: "192.00", currency: "USD"), lineTotal: AdminOperationsMoney(amount: "192.00", currency: "USD")),
        AdminTopItemReportLine(catalogItemId: "item_borrego", name: "Borrego asado", quantity: "12", netTotal: AdminOperationsMoney(amount: "120.00", currency: "USD"), lineTotal: AdminOperationsMoney(amount: "120.00", currency: "USD")),
    ]

    static let salesSummary = AdminSalesSummaryReport(
        from: "2026-05-21T00:00:00Z",
        to: "2026-05-22T00:00:00Z",
        saleCount: 24,
        closedSaleCount: 21,
        canceledSaleCount: 1,
        openSaleCount: 2,
        itemCount: 58,
        subtotal: AdminOperationsMoney(amount: "420.00", currency: "USD"),
        discountTotal: AdminOperationsMoney(amount: "10.00", currency: "USD"),
        taxTotal: AdminOperationsMoney(amount: "62.50", currency: "USD"),
        grandTotal: moneySales,
        paidTotal: moneyPaid,
        receivableTotal: moneyReceivable,
        byOperationalStatus: [AdminStatusCount(status: "closed", count: 21), AdminStatusCount(status: "open", count: 2), AdminStatusCount(status: "canceled", count: 1)],
        byPaymentStatus: [AdminStatusCount(status: "paid", count: 20), AdminStatusCount(status: "partial", count: 3), AdminStatusCount(status: "unpaid", count: 1)],
        byDocumentStatus: [AdminStatusCount(status: "authorized", count: 18), AdminStatusCount(status: "pending", count: 3)],
        topItems: topItems
    )

    static let cashSummary = AdminCashSummaryReport(
        from: "2026-05-21T00:00:00Z",
        to: "2026-05-22T00:00:00Z",
        openSessionCount: 1,
        closedSessionCount: 1,
        movementCount: 14,
        cashInTotal: AdminOperationsMoney(amount: "230.00", currency: "USD"),
        cashOutTotal: AdminOperationsMoney(amount: "25.00", currency: "USD"),
        netCashMovement: AdminOperationsMoney(amount: "205.00", currency: "USD"),
        expectedOpenCashTotal: moneyCash,
        countedClosedCashTotal: AdminOperationsMoney(amount: "388.00", currency: "USD"),
        differenceClosedCashTotal: AdminOperationsMoney(amount: "-2.00", currency: "USD"),
        byMovementType: [AdminStatusCount(status: "sale_cash", count: 10), AdminStatusCount(status: "expense", count: 2)]
    )

    static let taxSummary = AdminTaxSummaryReport(
        from: "2026-05-21T00:00:00Z",
        to: "2026-05-22T00:00:00Z",
        documentCount: 21,
        authorizedDocumentCount: 18,
        documentGrandTotal: moneySales,
        taxTotal: AdminOperationsMoney(amount: "62.50", currency: "USD"),
        byTaxRate: [AdminTaxSummaryLine(taxCode: "2", rateCode: "4", rate: "15.00", taxableBase: AdminOperationsMoney(amount: "416.67", currency: "USD"), taxAmount: AdminOperationsMoney(amount: "62.50", currency: "USD"), documentCount: 18)]
    )

    static let todayReport = AdminOperationalTodayReport(
        businessDate: "2026-05-21",
        from: "2026-05-21T00:00:00Z",
        to: "2026-05-22T00:00:00Z",
        sales: salesSummary,
        cash: cashSummary,
        tax: taxSummary,
        currentCashSession: currentCashSession,
        pendingReceivables: moneyReceivable,
        topItems: topItems,
        alerts: [AdminOperationalAlert(code: "documents_pending", severity: "warning", message: "3 comprobantes requieren atención", actionHint: "Revisa Fiscal/SRI")]
    )

    static let auditLogs = [
        AdminAuditLogRecord(id: "audit_1", source: "admin", surface: "catalog", action: "CATALOG_PRICE_UPDATED", actorUserId: "usr_owner", targetType: "catalog_item", targetId: "item_cuy", reason: "Ajuste de temporada", message: "Precio actualizado", severity: "info", correlationId: "corr_1", before: ["price": "22.00"], after: ["price": "24.00"], metadata: ["ip": "127.0.0.1"], createdAt: "2026-05-21T18:00:00Z"),
        AdminAuditLogRecord(id: "audit_2", source: "auth", surface: "credentials", action: "USER_PASSWORD_RESET", actorUserId: "usr_owner", targetType: "user", targetId: "usr_cashier", reason: "Soporte", message: "Contraseña temporal generada", severity: "info", correlationId: nil, before: [:], after: [:], metadata: [:], createdAt: "2026-05-21T17:20:00Z"),
    ]

    static let timeline = auditLogs.map { log in
        AdminAuditTimelineItem(id: log.id, occurredAt: log.createdAt, source: log.source, surface: log.surface, title: log.title, description: log.subtitle, actorUserId: log.actorUserId, targetType: log.targetType, targetId: log.targetId, severity: log.severity, reason: log.reason, metadata: log.metadata)
    }

    static let diagnostics = AdminSupportDiagnosticsReport(
        generatedAt: "2026-05-21T18:30:00Z",
        status: "healthy",
        checks: [AdminSupportDiagnosticCheck(code: "audit", status: "healthy", message: "Auditoría disponible", actionHint: nil)],
        counters: [AdminSupportCounter(code: "audit_logs", label: "Eventos", value: 128)],
        warnings: []
    )
}
