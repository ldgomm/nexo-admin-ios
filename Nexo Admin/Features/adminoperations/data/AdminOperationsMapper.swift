//
//  AdminOperationsMapper.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import Foundation

extension AdminOperationsMoneyDTO {
    func toDomain() -> AdminOperationsMoney {
        AdminOperationsMoney(amount: amount, currency: currency)
    }
}

extension AdminStatusCountDTO {
    func toDomain() -> AdminStatusCount {
        AdminStatusCount(status: status, count: count)
    }
}

extension AdminTopItemReportLineDTO {
    func toDomain() -> AdminTopItemReportLine {
        AdminTopItemReportLine(
            catalogItemId: catalogItemId,
            name: name,
            quantity: quantity,
            netTotal: netTotal.toDomain(),
            lineTotal: lineTotal.toDomain()
        )
    }
}

extension AdminOperationalAlertDTO {
    func toDomain() -> AdminOperationalAlert {
        AdminOperationalAlert(code: code, severity: severity, message: message, actionHint: actionHint)
    }
}

extension AdminCashMovementDTO {
    func toDomain() -> AdminCashMovement {
        AdminCashMovement(
            id: id,
            cashSessionId: cashSessionId,
            branchId: branchId,
            type: type,
            direction: direction,
            amount: amount.toDomain(),
            occurredAt: occurredAt,
            referenceType: referenceType,
            referenceId: referenceId,
            notes: notes
        )
    }
}

extension AdminCashSessionDTO {
    func toDomain() -> AdminCashSession {
        AdminCashSession(
            id: id,
            branchId: branchId,
            openedBy: openedBy,
            openedAt: openedAt,
            status: status,
            openingBalance: openingBalance.toDomain(),
            expectedCashAmount: expectedCashAmount.toDomain(),
            countedCashAmount: countedCashAmount?.toDomain(),
            differenceAmount: differenceAmount?.toDomain(),
            movementCount: movementCount,
            closingStartedAt: closingStartedAt,
            closedAt: closedAt,
            canceledAt: canceledAt,
            movements: movements.map { $0.toDomain() }
        )
    }
}

extension AdminSalesSummaryReportDTO {
    func toDomain() -> AdminSalesSummaryReport {
        AdminSalesSummaryReport(
            from: from,
            to: to,
            saleCount: saleCount,
            closedSaleCount: closedSaleCount,
            canceledSaleCount: canceledSaleCount,
            openSaleCount: openSaleCount,
            itemCount: itemCount,
            subtotal: subtotal.toDomain(),
            discountTotal: discountTotal.toDomain(),
            taxTotal: taxTotal.toDomain(),
            grandTotal: grandTotal.toDomain(),
            paidTotal: paidTotal.toDomain(),
            receivableTotal: receivableTotal.toDomain(),
            byOperationalStatus: byOperationalStatus.map { $0.toDomain() },
            byPaymentStatus: byPaymentStatus.map { $0.toDomain() },
            byDocumentStatus: byDocumentStatus.map { $0.toDomain() },
            topItems: topItems.map { $0.toDomain() }
        )
    }
}

extension AdminCashSummaryReportDTO {
    func toDomain() -> AdminCashSummaryReport {
        AdminCashSummaryReport(
            from: from,
            to: to,
            openSessionCount: openSessionCount,
            closedSessionCount: closedSessionCount,
            movementCount: movementCount,
            cashInTotal: cashInTotal.toDomain(),
            cashOutTotal: cashOutTotal.toDomain(),
            netCashMovement: netCashMovement.toDomain(),
            expectedOpenCashTotal: expectedOpenCashTotal.toDomain(),
            countedClosedCashTotal: countedClosedCashTotal.toDomain(),
            differenceClosedCashTotal: differenceClosedCashTotal.toDomain(),
            byMovementType: byMovementType.map { $0.toDomain() }
        )
    }
}

extension AdminTaxSummaryLineDTO {
    func toDomain() -> AdminTaxSummaryLine {
        AdminTaxSummaryLine(
            taxCode: taxCode,
            rateCode: rateCode,
            rate: rate,
            taxableBase: taxableBase.toDomain(),
            taxAmount: taxAmount.toDomain(),
            documentCount: documentCount
        )
    }
}

extension AdminTaxSummaryReportDTO {
    func toDomain() -> AdminTaxSummaryReport {
        AdminTaxSummaryReport(
            from: from,
            to: to,
            documentCount: documentCount,
            authorizedDocumentCount: authorizedDocumentCount,
            documentGrandTotal: documentGrandTotal.toDomain(),
            taxTotal: taxTotal.toDomain(),
            byTaxRate: byTaxRate.map { $0.toDomain() }
        )
    }
}

extension AdminOperationalTodayReportDTO {
    func toDomain() -> AdminOperationalTodayReport {
        AdminOperationalTodayReport(
            businessDate: businessDate,
            from: from,
            to: to,
            sales: sales.toDomain(),
            cash: cash.toDomain(),
            tax: tax.toDomain(),
            currentCashSession: currentCashSession?.toDomain(),
            pendingReceivables: pendingReceivables.toDomain(),
            topItems: topItems.map { $0.toDomain() },
            alerts: alerts.map { $0.toDomain() }
        )
    }
}

extension AdminAuditLogRecordDTO {
    func toDomain() -> AdminAuditLogRecord {
        AdminAuditLogRecord(
            id: id,
            source: source,
            surface: surface,
            action: action,
            actorUserId: actorUserId,
            targetType: targetType,
            targetId: targetId,
            reason: reason,
            message: message,
            severity: severity,
            correlationId: correlationId,
            before: before,
            after: after,
            metadata: metadata,
            createdAt: createdAt
        )
    }
}

extension AdminAuditTimelineItemDTO {
    func toDomain() -> AdminAuditTimelineItem {
        AdminAuditTimelineItem(
            id: id,
            occurredAt: occurredAt,
            source: source,
            surface: surface,
            title: title,
            description: description,
            actorUserId: actorUserId,
            targetType: targetType,
            targetId: targetId,
            severity: severity,
            reason: reason,
            metadata: metadata
        )
    }
}

extension AdminSupportDiagnosticCheckDTO {
    func toDomain() -> AdminSupportDiagnosticCheck {
        AdminSupportDiagnosticCheck(code: code, status: status, message: message, actionHint: actionHint)
    }
}

extension AdminSupportCounterDTO {
    func toDomain() -> AdminSupportCounter {
        AdminSupportCounter(code: code, label: label, value: value)
    }
}

extension AdminSupportDiagnosticsReportDTO {
    func toDomain() -> AdminSupportDiagnosticsReport {
        AdminSupportDiagnosticsReport(
            generatedAt: generatedAt,
            status: status,
            checks: checks.map { $0.toDomain() },
            counters: counters.map { $0.toDomain() },
            warnings: warnings
        )
    }
}
