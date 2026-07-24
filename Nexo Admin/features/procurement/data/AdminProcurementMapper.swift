//
//  AdminProcurementMapper.swift
//  Nexo Admin
//
//  27R.N.1B — Lossless mapping of backend readiness facts.
//

import Foundation

extension AdminProcurementReportCatalogDTO {
    func toDomain() -> AdminProcurementReportCatalog {
        AdminProcurementReportCatalog(
            contractVersion: contractVersion,
            reports: reports.map { $0.toDomain() },
            financeFactsPath: financeFactsPath,
            financeFactsCsvPath: financeFactsCsvPath,
            accountingEntriesGenerated: accountingEntriesGenerated
        )
    }
}

extension AdminProcurementReportCatalogEntryDTO {
    func toDomain() -> AdminProcurementReportCatalogEntry {
        AdminProcurementReportCatalogEntry(
            reportType: reportType,
            title: title,
            description: description,
            jsonPath: jsonPath,
            csvPath: csvPath,
            implementation: implementation
        )
    }
}

extension AdminProcurementMoneyDTO {
    func toDomain() throws -> AdminProcurementMoney {
        guard let decimal = Decimal(
            string: amount.replacingOccurrences(of: ",", with: "."),
            locale: Locale(identifier: "en_US_POSIX")
        ) else {
            throw AppError.decoding("Monto de compras inválido para \(currency).")
        }
        return AdminProcurementMoney(amount: decimal, currency: currency)
    }
}

extension AdminProcurementReconciliationDTO {
    func toDomain() -> AdminProcurementReconciliationCheck {
        AdminProcurementReconciliationCheck(
            name: name,
            expected: expected,
            actual: actual,
            unit: unit,
            passed: passed
        )
    }
}

extension AdminProcurementOperationalHealthDTO {
    func toDomain() throws -> AdminProcurementOperationalHealth {
        AdminProcurementOperationalHealth(
            reportType: reportType,
            title: title,
            branchId: branchId,
            currency: currency,
            asOf: asOf,
            generatedAt: generatedAt,
            matchingRowCount: matchingRowCount,
            totalAmount: try totalAmount.toDomain(),
            openBalance: try openBalance.toDomain(),
            reconciliationChecks: reconciliationChecks.map { $0.toDomain() },
            hasMore: hasMore
        )
    }
}

extension AdminProcurementFinanceHealthDTO {
    func toDomain() -> AdminProcurementFinanceHealth {
        AdminProcurementFinanceHealth(
            organizationId: organizationId,
            branchId: branchId,
            currency: currency,
            generatedAt: generatedAt,
            matchingFactCount: matchingFactCount,
            accountingEntriesGenerated: accountingEntriesGenerated,
            reconciliationChecks: reconciliationChecks.map { $0.toDomain() },
            hasMore: hasMore
        )
    }
}
