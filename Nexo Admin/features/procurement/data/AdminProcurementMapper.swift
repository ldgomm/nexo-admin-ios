//
//  AdminProcurementMapper.swift
//  Nexo Admin
//
//  Created by José Ruiz on 29/7/26.
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

extension AdminProcurementFinanceSourceFactReplayReadinessDTO {
    func toDomain() -> AdminProcurementFinanceSourceFactReplayReadiness {
        AdminProcurementFinanceSourceFactReplayReadiness(
            contractVersion: contractVersion,
            schemaVersion: schemaVersion,
            organizationId: organizationId,
            branchId: branchId,
            supplierId: supplierId,
            currency: currency,
            effectiveFrom: effectiveFrom,
            effectiveTo: effectiveTo,
            snapshotAt: snapshotAt,
            returnedFactCount: returnedFactCount,
            hasMore: hasMore,
            nextCursorAvailable: nextCursorAvailable,
            maxPageSize: maxPageSize,
            supportedFactTypes: supportedFactTypes,
            reservedFactTypes: reservedFactTypes,
            replayMode: replayMode,
            readOnly: readOnly,
            accountingEntriesGenerated: accountingEntriesGenerated,
            postable: postable,
            limitations: limitations
        )
    }
}

extension AdminProcurementAccountingCompletenessItemDTO {
    func toDomain() throws -> AdminProcurementAccountingCompletenessItem {
        guard let classification = AdminProcurementAccountingCompletenessClassification(rawValue: classification) else {
            throw AppError.decoding("Clasificación desconocida en la matriz de completitud contable.")
        }
        guard !id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw AppError.decoding("La matriz de completitud contiene una fila sin identidad.")
        }
        return AdminProcurementAccountingCompletenessItem(
            id: id,
            title: title,
            displayTitle: displayTitle,
            authoritativeEvidence: authoritativeEvidence,
            v1ReplayStatus: v1ReplayStatus,
            classification: classification,
            classificationNote: classificationNote,
            futureOwnerAction: futureOwnerAction
        )
    }
}

extension AdminProcurementAccountingCompletenessMatrixDTO {
    func toDomain() throws -> AdminProcurementAccountingCompletenessMatrix {
        let mappedItems = try items.map { try $0.toDomain() }
        guard Set(mappedItems.map(\.id)).count == mappedItems.count else {
            throw AppError.decoding("La matriz de completitud contiene identidades duplicadas.")
        }
        let actualPass = mappedItems.filter { $0.classification == .passExisting }.count
        let actualFutureGap = mappedItems.filter { $0.classification == .documentFutureGap }.count
        let actualNotApplicable = mappedItems.filter { $0.classification == .notApplicable }.count
        guard totalItemCount == mappedItems.count,
              passExistingCount == actualPass,
              futureGapCount == actualFutureGap,
              notApplicableCount == actualNotApplicable else {
            throw AppError.decoding("Los conteos de la matriz de completitud no coinciden con sus filas.")
        }
        return AdminProcurementAccountingCompletenessMatrix(
            contractVersion: contractVersion,
            matrixVersion: matrixVersion,
            acceptedStage: acceptedStage,
            organizationId: organizationId,
            currency: currency,
            scope: scope,
            sourceDocument: sourceDocument,
            totalItemCount: totalItemCount,
            passExistingCount: passExistingCount,
            futureGapCount: futureGapCount,
            notApplicableCount: notApplicableCount,
            items: mappedItems,
            readOnly: readOnly,
            accountingEntriesGenerated: accountingEntriesGenerated,
            postable: postable,
            limitations: limitations
        )
    }
}
