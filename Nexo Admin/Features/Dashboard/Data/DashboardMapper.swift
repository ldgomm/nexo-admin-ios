//
//  DashboardMapper.swift
//  Nexo Admin
//
//  Created by José Ruiz on 20/5/26.
//

import Foundation

enum DashboardMapper {
    static func map(_ dto: DashboardSummaryResponseDTO) -> DashboardSummary {
        DashboardSummary(
            generatedAt: dto.generatedAt ?? "",
            sales: map(dto.sales),
            cash: map(dto.cash),
            documents: map(dto.documents),
            signature: map(dto.signature),
            alerts: (dto.alerts ?? []).map(map(_:)).sorted { lhs, rhs in
                lhs.severity.priority < rhs.severity.priority
            },
            quickActions: DashboardQuickActionsFactory.actions
        )
    }

    private static func map(_ dto: DashboardSalesSummaryDTO?) -> DashboardSalesSummary {
        guard let dto else { return .empty }
        return DashboardSalesSummary(
            grossTotal: map(dto.grossTotal),
            netTotal: map(dto.netTotal),
            collectedTotal: map(dto.collectedTotal),
            receivableTotal: map(dto.receivableTotal),
            salesCount: dto.salesCount ?? 0,
            canceledCount: dto.canceledCount ?? 0,
            pendingCount: dto.pendingCount ?? 0,
            averageTicket: map(dto.averageTicket)
        )
    }

    private static func map(_ dto: DashboardCashSummaryDTO?) -> DashboardCashSummary {
        guard let dto else { return .empty }
        return DashboardCashSummary(
            status: dto.status ?? "unknown",
            openedBy: dto.openedBy,
            openedAt: dto.openedAt,
            expectedCash: map(dto.expectedCash),
            cashSales: map(dto.cashSales),
            cashInflow: map(dto.cashInflow),
            cashOutflow: map(dto.cashOutflow),
            difference: dto.difference.map(map(_:))
        )
    }

    private static func map(_ dto: DashboardDocumentSummaryDTO?) -> DashboardDocumentSummary {
        guard let dto else { return .empty }
        return DashboardDocumentSummary(
            authorizedCount: dto.authorizedCount ?? 0,
            rejectedCount: dto.rejectedCount ?? 0,
            pendingCount: dto.pendingCount ?? 0,
            returnedCount: dto.returnedCount ?? 0,
            lastAuthorizedAt: dto.lastAuthorizedAt
        )
    }

    private static func map(_ dto: DashboardSignatureSummaryDTO?) -> DashboardSignatureSummary {
        guard let dto else { return .empty }
        return DashboardSignatureSummary(
            status: dto.status ?? "not_configured",
            ownerName: dto.ownerName,
            expiresAt: dto.expiresAt,
            daysUntilExpiration: dto.daysUntilExpiration,
            lastTestStatus: dto.lastTestStatus
        )
    }

    private static func map(_ dto: DashboardAlertDTO) -> DashboardAlert {
        DashboardAlert(
            id: dto.id ?? UUID().uuidString,
            title: dto.title ?? "Alerta",
            message: dto.message ?? "Revisa este punto antes de continuar.",
            severity: DashboardAlertSeverity(rawValue: dto.severity ?? "") ?? .info,
            category: DashboardAlertCategory(rawValue: dto.category ?? "") ?? .unknown,
            createdAt: dto.createdAt,
            actionTitle: dto.actionTitle,
            destination: dto.destination.flatMap(DashboardQuickActionDestination.init(rawValue:))
        )
    }

    private static func map(_ dto: DashboardMoneyDTO?) -> DashboardMoney {
        guard let dto else { return .zeroUSD }
        return map(dto)
    }

    private static func map(_ dto: DashboardMoneyDTO) -> DashboardMoney {
        DashboardMoney(
            amount: Decimal(string: dto.amount ?? "0") ?? 0,
            currency: dto.currency ?? "USD"
        )
    }
}
