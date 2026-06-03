//
//  DashboardMapper.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import Foundation

enum DashboardMapper {
    static func map(_ dto: DashboardOperationalReportResponseDTO, period: DashboardPeriod) -> DashboardSummary {
        let sales = mapSales(dto.sales)
        let cash = mapCash(dto.cash, currentSession: dto.currentCashSession)
        let tax = mapTax(dto.tax)
        let documents = mapDocuments(tax: dto.tax, sales: dto.sales)
        let topItems = mapTopItems(dto.topItems?.isEmpty == false ? dto.topItems : dto.sales?.topItems)
        let alerts = mapAlerts(dto.alerts, documents: documents, cash: cash, pendingReceivables: mapMoney(dto.pendingReceivables))

        return DashboardSummary(
            generatedAt: dto.to ?? dto.from ?? "",
            businessDate: dto.businessDate ?? "",
            period: period,
            sales: sales,
            cash: cash,
            documents: documents,
            tax: tax,
            signature: mapSignature(dto.signature),
            pendingReceivables: mapMoney(dto.pendingReceivables),
            topItems: topItems,
            alerts: alerts,
            quickActions: DashboardQuickActionsFactory.actions
        )
    }

    private static func mapSales(_ dto: DashboardSalesSummaryReportDTO?) -> DashboardSalesSummary {
        guard let dto else { return .empty }
        let grandTotal = mapMoney(dto.grandTotal)
        let saleCount = dto.saleCount ?? 0
        return DashboardSalesSummary(
            grossTotal: grandTotal,
            netTotal: grandTotal,
            collectedTotal: mapMoney(dto.paidTotal),
            receivableTotal: mapMoney(dto.receivableTotal),
            salesCount: saleCount,
            closedCount: dto.closedSaleCount ?? 0,
            canceledCount: dto.canceledSaleCount ?? 0,
            pendingCount: dto.openSaleCount ?? 0,
            itemCount: dto.itemCount ?? 0,
            averageTicket: grandTotal.divided(by: max(saleCount, 1)),
            byOperationalStatus: mapStatusCounts(dto.byOperationalStatus),
            byPaymentStatus: mapStatusCounts(dto.byPaymentStatus),
            byDocumentStatus: mapStatusCounts(dto.byDocumentStatus)
        )
    }

    private static func mapCash(_ dto: DashboardCashSummaryReportDTO?, currentSession: DashboardCashSessionDTO?) -> DashboardCashSummary {
        guard let dto else { return .empty }
        let openCount = dto.openSessionCount ?? (currentSession == nil ? 0 : 1)
        let currentStatus = currentSession?.status ?? (openCount > 0 ? "open" : "closed")
        return DashboardCashSummary(
            status: currentStatus,
            openedBy: currentSession?.openedBy,
            openedAt: currentSession?.openedAt,
            openSessionCount: openCount,
            closedSessionCount: dto.closedSessionCount ?? 0,
            movementCount: dto.movementCount ?? currentSession?.movementCount ?? 0,
            expectedCash: mapMoney(currentSession?.expectedCashAmount ?? dto.expectedOpenCashTotal),
            cashSales: mapMoney(dto.cashInTotal),
            cashInflow: mapMoney(dto.cashInTotal),
            cashOutflow: mapMoney(dto.cashOutTotal),
            netCashMovement: mapMoney(dto.netCashMovement),
            difference: currentSession?.differenceAmount.map { mapMoney($0) } ?? dto.differenceClosedCashTotal.map { mapMoney($0) },
            byMovementType: mapStatusCounts(dto.byMovementType)
        )
    }

    private static func mapDocuments(tax: DashboardTaxSummaryReportDTO?, sales: DashboardSalesSummaryReportDTO?) -> DashboardDocumentSummary {
        let total = tax?.documentCount ?? sales?.byDocumentStatus?.reduce(0) { $0 + ($1.count ?? 0) } ?? 0
        let authorized = tax?.authorizedDocumentCount ?? countStatuses(sales?.byDocumentStatus, matching: ["authorized", "autorizado"])
        let rejected = countStatuses(sales?.byDocumentStatus, matching: ["rejected", "rechazado", "failed", "signature_failed", "sri_rejected"])
        let returned = countStatuses(sales?.byDocumentStatus, matching: ["returned", "devuelto"])
        let pending = max(total - authorized - rejected - returned, 0)
        return DashboardDocumentSummary(
            totalCount: total,
            authorizedCount: authorized,
            rejectedCount: rejected,
            pendingCount: pending,
            returnedCount: returned,
            documentGrandTotal: mapMoney(tax?.documentGrandTotal),
            taxTotal: mapMoney(tax?.taxTotal),
            lastAuthorizedAt: nil
        )
    }

    private static func mapTax(_ dto: DashboardTaxSummaryReportDTO?) -> DashboardTaxSummary {
        guard let dto else { return .empty }
        return DashboardTaxSummary(
            documentCount: dto.documentCount ?? 0,
            authorizedDocumentCount: dto.authorizedDocumentCount ?? 0,
            taxTotal: mapMoney(dto.taxTotal),
            byTaxRate: (dto.byTaxRate ?? []).map { line in
                DashboardTaxRateLine(
                    taxCode: line.taxCode ?? "",
                    rateCode: line.rateCode ?? "",
                    rate: Decimal(string: line.rate ?? "0") ?? 0,
                    taxableBase: mapMoney(line.taxableBase),
                    taxAmount: mapMoney(line.taxAmount),
                    documentCount: line.documentCount ?? 0
                )
            }
        )
    }

    private static func mapSignature(_ dto: DashboardSignatureSummaryDTO?) -> DashboardSignatureSummary {
        guard let dto else { return .unavailable }
        return DashboardSignatureSummary(
            status: dto.status ?? "not_configured",
            ownerName: dto.ownerName,
            expiresAt: dto.expiresAt,
            daysUntilExpiration: dto.daysUntilExpiration,
            lastTestStatus: dto.lastTestStatus,
            sourceAvailable: true
        )
    }

    private static func mapTopItems(_ items: [DashboardTopItemDTO]?) -> [DashboardTopItem] {
        (items ?? []).enumerated().map { index, item in
            DashboardTopItem(
                id: item.catalogItemId ?? "top_item_\(index)",
                catalogItemId: item.catalogItemId,
                name: item.name ?? "Ítem",
                quantity: Decimal(string: item.quantity ?? "0") ?? 0,
                netTotal: mapMoney(item.netTotal),
                lineTotal: mapMoney(item.lineTotal)
            )
        }
    }

    private static func mapAlerts(
        _ alerts: [DashboardOperationalAlertDTO]?,
        documents: DashboardDocumentSummary,
        cash: DashboardCashSummary,
        pendingReceivables: DashboardMoney
    ) -> [DashboardAlert] {
        var mapped = (alerts ?? []).map(mapAlert(_:))

        if documents.rejectedCount > 0 && !mapped.contains(where: { $0.id == "documents_rejected" }) {
            mapped.append(
                DashboardAlert(
                    id: "documents_rejected",
                    title: "Comprobantes con error",
                    message: "Hay \(documents.rejectedCount) comprobante(s) rechazado(s) o fallidos que requieren soporte.",
                    severity: .critical,
                    category: .sri,
                    createdAt: nil,
                    actionTitle: "Ver comprobantes",
                    destination: .documents
                )
            )
        }

        if !cash.isOpen && !mapped.contains(where: { $0.id == "cash_session_not_open" }) {
            mapped.append(
                DashboardAlert(
                    id: "cash_session_not_open",
                    title: "Caja cerrada",
                    message: "No hay una caja abierta para el contexto seleccionado.",
                    severity: .warning,
                    category: .cash,
                    createdAt: nil,
                    actionTitle: "Revisar caja",
                    destination: .cash
                )
            )
        }

        if pendingReceivables.amount > 0 && !mapped.contains(where: { $0.id == "pending_receivables" }) {
            mapped.append(
                DashboardAlert(
                    id: "pending_receivables",
                    title: "Cuentas por cobrar",
                    message: "Existen valores pendientes por cobrar: \(pendingReceivables.formatted).",
                    severity: .info,
                    category: .receivable,
                    createdAt: nil,
                    actionTitle: "Revisar pendientes",
                    destination: .cash
                )
            )
        }

        return mapped.sorted { lhs, rhs in
            if lhs.severity.priority == rhs.severity.priority {
                return lhs.title < rhs.title
            }
            return lhs.severity.priority < rhs.severity.priority
        }
    }

    private static func mapAlert(_ dto: DashboardOperationalAlertDTO) -> DashboardAlert {
        let code = dto.code ?? UUID().uuidString
        return DashboardAlert(
            id: code,
            title: dto.title ?? title(for: code),
            message: dto.message ?? "Revisa este punto antes de continuar.",
            severity: DashboardAlertSeverity(rawValue: dto.severity ?? "") ?? .info,
            category: dto.category.flatMap(DashboardAlertCategory.init(rawValue:)) ?? category(for: code),
            createdAt: nil,
            actionTitle: dto.actionHint ?? actionTitle(for: code),
            destination: dto.destination.flatMap(DashboardQuickActionDestination.init(rawValue:)) ?? destination(for: code)
        )
    }

    private static func mapStatusCounts(_ dtos: [DashboardStatusCountDTO]?) -> [DashboardStatusCount] {
        (dtos ?? [])
            .filter { ($0.count ?? 0) > 0 }
            .map { DashboardStatusCount(status: $0.status ?? "unknown", count: $0.count ?? 0) }
            .sorted { $0.status < $1.status }
    }

    private static func countStatuses(_ dtos: [DashboardStatusCountDTO]?, matching values: Set<String>) -> Int {
        (dtos ?? []).reduce(0) { partial, item in
            let normalized = (item.status ?? "").lowercased()
            return values.contains(normalized) ? partial + (item.count ?? 0) : partial
        }
    }

    private static func mapMoney(_ dto: DashboardMoneyDTO?) -> DashboardMoney {
        guard let dto else { return .zeroUSD }
        return mapMoney(dto)
    }

    private static func mapMoney(_ dto: DashboardMoneyDTO) -> DashboardMoney {
        DashboardMoney(
            amount: Decimal(string: dto.amount ?? "0") ?? 0,
            currency: dto.currency ?? "USD"
        )
    }

    private static func title(for code: String) -> String {
        switch code {
        case "cash_session_not_open": return "Caja no abierta"
        case "pending_receivables": return "Cuentas por cobrar"
        case "canceled_sales_today": return "Ventas canceladas"
        case "documents_not_authorized": return "Comprobantes pendientes"
        default: return "Alerta operativa"
        }
    }

    private static func category(for code: String) -> DashboardAlertCategory {
        switch code {
        case "cash_session_not_open": return .cash
        case "pending_receivables": return .receivable
        case "documents_not_authorized": return .sri
        default: return .operational
        }
    }

    private static func destination(for code: String) -> DashboardQuickActionDestination? {
        switch code {
        case "cash_session_not_open", "pending_receivables": return .cash
        case "documents_not_authorized": return .documents
        default: return nil
        }
    }

    private static func actionTitle(for code: String) -> String? {
        switch code {
        case "cash_session_not_open": return "Revisar caja"
        case "pending_receivables": return "Ver pendientes"
        case "canceled_sales_today": return "Ver ventas"
        case "documents_not_authorized": return "Ver comprobantes"
        default: return nil
        }
    }
}
