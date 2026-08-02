//
//  AdminSupplierStatementMapper.swift
//  Nexo Admin
//
//  Created by José Ruiz on 29/7/26.
//
//  27R.N — Strict mapping of canonical supplier-statement balances and evidence.
//

import Foundation


extension AdminSupplierStatementQuery {
    func toDTO() -> AdminSupplierStatementRequestDTO {
        AdminSupplierStatementRequestDTO(
            supplierId: supplierId.trimmingCharacters(in: .whitespacesAndNewlines),
            branchId: branchId?.trimmedOrNil,
            currency: currency.trimmingCharacters(in: .whitespacesAndNewlines).uppercased(),
            from: from?.trimmedOrNil,
            to: to?.trimmedOrNil,
            asOf: asOf?.trimmedOrNil,
            limit: min(max(limit, 1), 100),
            cursor: cursor?.trimmedOrNil
        )
    }
}

extension AdminProcurementOperationalExportQuery {
    func toDTO() -> AdminProcurementOperationalExportRequestDTO {
        AdminProcurementOperationalExportRequestDTO(
            reportType: reportType.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
            branchId: branchId?.trimmedOrNil,
            supplierId: supplierId?.trimmedOrNil,
            category: category?.trimmedOrNil,
            catalogItemId: catalogItemId?.trimmedOrNil,
            paymentMethod: paymentMethod?.trimmedOrNil?.uppercased(),
            attachmentSourceType: attachmentSourceType?.trimmedOrNil?.uppercased(),
            currency: currency.trimmingCharacters(in: .whitespacesAndNewlines).uppercased(),
            from: from?.trimmedOrNil,
            to: to?.trimmedOrNil,
            asOf: asOf?.trimmedOrNil
        )
    }
}

extension AdminSupplierStatementResponseDTO {
    func toDomain() throws -> AdminSupplierStatement {
        let normalizedSupplierId = try AdminSupplierStatementMapperSupport.requiredIdentifier(
            supplierId,
            field: "proveedor"
        )
        let normalizedCurrency = try AdminSupplierStatementMapperSupport.currency(currency)
        let normalizedBranchId = try AdminSupplierStatementMapperSupport.optionalIdentifier(
            branchId,
            field: "sucursal"
        )
        let normalizedFrom = try AdminSupplierStatementMapperSupport.optionalDate(from, field: "desde")
        let normalizedTo = try AdminSupplierStatementMapperSupport.optionalDate(to, field: "hasta")
        let normalizedAsOf = try AdminSupplierStatementMapperSupport.date(asOf, field: "fecha de corte")

        if let normalizedFrom, let normalizedTo, normalizedFrom > normalizedTo {
            throw AppError.decoding("La fecha inicial del estado de cuenta es posterior a la final.")
        }
        if let normalizedTo, normalizedTo > normalizedAsOf {
            throw AppError.decoding("La fecha final del estado de cuenta es posterior a la fecha de corte.")
        }

        let mappedOpening = try AdminSupplierStatementMapperSupport.money(
            openingBalance,
            currency: normalizedCurrency,
            field: "saldo inicial"
        )
        let mappedClosing = try AdminSupplierStatementMapperSupport.money(
            closingBalance,
            currency: normalizedCurrency,
            field: "saldo final"
        )
        let mappedLines = try lines.map { try $0.toDomain(currency: normalizedCurrency) }

        guard Set(mappedLines.map(\.id)).count == mappedLines.count else {
            throw AppError.decoding("El estado de cuenta contiene movimientos repetidos.")
        }
        guard mappedOpening.amount >= .zero,
              mappedClosing.amount >= .zero,
              mappedLines.allSatisfy({ $0.runningBalance.amount >= .zero }) else {
            throw AppError.decoding("El estado de cuenta contiene un saldo negativo no permitido por el contrato operativo.")
        }
        let expectedClosing = mappedLines.last?.runningBalance ?? mappedOpening
        guard expectedClosing == mappedClosing else {
            throw AppError.decoding("El saldo final no coincide con el último saldo corriente del backend.")
        }

        let normalizedCursor = nextCursor?.trimmedOrNil
        guard hasMore == (normalizedCursor != nil) else {
            throw AppError.decoding("La paginación del estado de cuenta no es consistente.")
        }

        return AdminSupplierStatement(
            supplierId: normalizedSupplierId,
            branchId: normalizedBranchId,
            currency: normalizedCurrency,
            from: normalizedFrom,
            to: normalizedTo,
            asOf: normalizedAsOf,
            openingBalance: mappedOpening,
            lines: mappedLines,
            closingBalance: mappedClosing,
            nextCursor: normalizedCursor,
            hasMore: hasMore
        )
    }
}

private extension AdminSupplierStatementLineDTO {
    func toDomain(currency expectedCurrency: String) throws -> AdminSupplierStatementLine {
        let normalizedId = try AdminSupplierStatementMapperSupport.requiredIdentifier(id, field: "movimiento")
        let normalizedSourceId = try AdminSupplierStatementMapperSupport.requiredIdentifier(
            sourceId,
            field: "origen"
        )
        let normalizedAuditResourceType = try AdminSupplierStatementMapperSupport.requiredIdentifier(
            auditResourceType,
            field: "tipo de evidencia"
        )
        let normalizedAuditResourceId = try AdminSupplierStatementMapperSupport.requiredIdentifier(
            auditResourceId,
            field: "evidencia"
        )
        let normalizedDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedDescription.isEmpty else {
            throw AppError.decoding("Un movimiento del estado de cuenta no tiene descripción.")
        }
        guard AdminSupplierStatementMapperSupport.timestamp(occurredAt) != nil else {
            throw AppError.decoding("La fecha de un movimiento del estado de cuenta no es válida.")
        }
        let normalizedLineCurrency = try AdminSupplierStatementMapperSupport.currency(currency)
        guard normalizedLineCurrency == expectedCurrency else {
            throw AppError.decoding("La moneda de un movimiento no coincide con el estado de cuenta.")
        }

        let mappedSourceType = AdminSupplierStatementSourceType(wireValue: sourceType)
        if case .unsupported = mappedSourceType {
            throw AppError.decoding("El tipo de movimiento del estado de cuenta no está soportado.")
        }

        let mappedCharge = try AdminSupplierStatementMapperSupport.money(
            charge,
            currency: expectedCurrency,
            field: "cargo"
        )
        let mappedCredit = try AdminSupplierStatementMapperSupport.money(
            credit,
            currency: expectedCurrency,
            field: "abono"
        )
        let mappedRunningBalance = try AdminSupplierStatementMapperSupport.money(
            runningBalance,
            currency: expectedCurrency,
            field: "saldo corriente"
        )

        let zero = Decimal.zero
        guard (mappedCharge.amount == zero) != (mappedCredit.amount == zero) else {
            throw AppError.decoding("Cada movimiento debe contener exactamente un cargo o un abono.")
        }
        guard mappedCharge.amount >= zero, mappedCredit.amount >= zero else {
            throw AppError.decoding("Los cargos y abonos del estado de cuenta no pueden ser negativos.")
        }

        return AdminSupplierStatementLine(
            id: normalizedId,
            occurredAt: occurredAt,
            sourceType: mappedSourceType,
            sourceId: normalizedSourceId,
            description: normalizedDescription,
            charge: mappedCharge,
            credit: mappedCredit,
            runningBalance: mappedRunningBalance,
            currency: normalizedLineCurrency,
            auditResourceType: normalizedAuditResourceType,
            auditResourceId: normalizedAuditResourceId
        )
    }
}

private enum AdminSupplierStatementMapperSupport {
    static func requiredIdentifier(_ raw: String, field: String) throws -> String {
        guard let value = raw.trimmedOrNil else {
            throw AppError.decoding("El identificador de \(field) del estado de cuenta está vacío.")
        }
        return value
    }

    static func optionalIdentifier(_ raw: String?, field: String) throws -> String? {
        guard let raw else { return nil }
        guard let value = raw.trimmedOrNil else {
            throw AppError.decoding("El identificador de \(field) del estado de cuenta está vacío.")
        }
        return value
    }

    static func currency(_ raw: String) throws -> String {
        let value = raw.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard value.range(of: "^[A-Z]{3}$", options: .regularExpression) != nil else {
            throw AppError.decoding("La moneda del estado de cuenta debe usar tres letras.")
        }
        return value
    }

    static func money(
        _ dto: AdminProcurementMoneyDTO,
        currency expectedCurrency: String,
        field: String
    ) throws -> AdminProcurementMoney {
        let mapped = try dto.toDomain()
        let normalizedCurrency = try currency(mapped.currency)
        guard normalizedCurrency == expectedCurrency else {
            throw AppError.decoding("La moneda de \(field) no coincide con el estado de cuenta.")
        }
        return AdminProcurementMoney(amount: mapped.amount, currency: normalizedCurrency)
    }

    static func optionalDate(_ raw: String?, field: String) throws -> String? {
        guard let value = raw?.trimmedOrNil else { return nil }
        return try date(value, field: field)
    }

    static func date(_ raw: String, field: String) throws -> String {
        guard isValidDate(raw) else {
            throw AppError.decoding("La fecha \(field) del estado de cuenta no es válida.")
        }
        return raw
    }

    static func isValidDate(_ raw: String) -> Bool {
        guard raw.range(of: "^[0-9]{4}-[0-9]{2}-[0-9]{2}$", options: .regularExpression) != nil else {
            return false
        }
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.isLenient = false
        guard let date = formatter.date(from: raw) else { return false }
        return formatter.string(from: date) == raw
    }

    static func timestamp(_ raw: String) -> Date? {
        let fractional = ISO8601DateFormatter()
        fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let value = fractional.date(from: raw) { return value }
        let standard = ISO8601DateFormatter()
        standard.formatOptions = [.withInternetDateTime]
        return standard.date(from: raw)
    }
}
