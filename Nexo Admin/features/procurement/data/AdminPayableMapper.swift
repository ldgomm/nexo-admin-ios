//
//  AdminPayableMapper.swift
//  Nexo Admin
//
//  Created by José Ruiz on 29/7/26.
//
//  27R.N — Lossless payable mapping without client-owned balance calculation.
//

import Foundation

extension AdminPayableListResponseDTO {
    func toDomain() throws -> AdminPayablePage {
        guard AdminPayableMapperSupport.isValidDate(asOf) else {
            throw AppError.decoding("La fecha de corte de cuentas por pagar no es válida.")
        }
        return AdminPayablePage(
            payables: try payables.map { try $0.toDomain() },
            nextCursor: nextCursor,
            hasMore: hasMore,
            asOf: asOf
        )
    }
}

extension AdminPayableEnvelopeDTO {
    func toDomain() throws -> AdminPayableEnvelope {
        AdminPayableEnvelope(
            payable: try data.toDomain(),
            requestId: meta.requestId,
            idempotencyReplayed: meta.idempotencyReplayed
        )
    }
}

extension AdminPayableAgingResponseDTO {
    func toDomain() throws -> AdminPayableAging {
        let normalizedCurrency = try AdminPayableMapperSupport.currency(currency)
        guard AdminPayableMapperSupport.isValidDate(asOf) else {
            throw AppError.decoding("La fecha de corte del envejecimiento no es válida.")
        }

        var seen = Set<AdminPayableAgingBucketCode>()
        let mapped = try buckets.map { bucket -> AdminPayableAgingBucket in
            guard let code = AdminPayableAgingBucketCode(rawValue: bucket.code) else {
                throw AppError.decoding("Bucket de vencimiento no soportado: \(bucket.code).")
            }
            guard seen.insert(code).inserted else {
                throw AppError.decoding("El backend repitió el bucket de vencimiento \(bucket.code).")
            }
            guard bucket.count >= 0 else {
                throw AppError.decoding("El conteo del bucket de vencimiento no puede ser negativo.")
            }
            return AdminPayableAgingBucket(
                code: code,
                count: bucket.count,
                balance: try bucket.balance.toPayableDomain(validatingCurrency: normalizedCurrency)
            )
        }

        return AdminPayableAging(currency: normalizedCurrency, asOf: asOf, buckets: mapped)
    }
}

extension AdminPayableDTO {
    func toDomain() throws -> AdminPayable {
        let normalizedCurrency = try AdminPayableMapperSupport.currency(currency)
        guard let settlementStatus = AdminPayableSettlementStatus(rawValue: self.settlementStatus) else {
            throw AppError.decoding("Estado de liquidación no soportado: \(self.settlementStatus).")
        }
        guard let effectiveStatus = AdminPayableEffectiveStatus(rawValue: self.effectiveStatus) else {
            throw AppError.decoding("Estado efectivo de cuenta por pagar no soportado: \(self.effectiveStatus).")
        }
        guard AdminPayableMapperSupport.isValidDate(dueDate) else {
            throw AppError.decoding("La fecha de vencimiento de la cuenta por pagar no es válida.")
        }
        guard version > 0 else {
            throw AppError.decoding("La versión de la cuenta por pagar debe ser positiva.")
        }
        guard !id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !branchId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !supplierId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !sourceType.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !sourceId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw AppError.decoding("La identidad de la cuenta por pagar está incompleta.")
        }
        guard Set(allocationIds).count == allocationIds.count else {
            throw AppError.decoding("La cuenta por pagar contiene aplicaciones de pago duplicadas.")
        }

        let original = try originalAmount.toPayableDomain(validatingCurrency: normalizedCurrency)
        let paid = try paidAmount.toPayableDomain(validatingCurrency: normalizedCurrency)
        let outstanding = try balance.toPayableDomain(validatingCurrency: normalizedCurrency)
        guard original.amount > 0, paid.amount >= 0, outstanding.amount >= 0 else {
            throw AppError.decoding("Los importes de la cuenta por pagar no son válidos.")
        }
        guard paid.amount + outstanding.amount == original.amount else {
            throw AppError.decoding("La cuenta por pagar no reconcilia importe original, pagado y saldo.")
        }

        return AdminPayable(
            id: id,
            branchId: branchId,
            supplierId: supplierId,
            sourceType: sourceType,
            sourceId: sourceId,
            currency: normalizedCurrency,
            originalAmount: original,
            paidAmount: paid,
            balance: outstanding,
            dueDate: dueDate,
            settlementStatus: settlementStatus,
            effectiveStatus: effectiveStatus,
            allocationIds: allocationIds,
            createdAt: createdAt,
            createdBy: createdBy,
            updatedAt: updatedAt,
            updatedBy: updatedBy,
            version: version
        )
    }
}

extension AdminPayableListQuery {
    func toDTO() -> AdminPayableListRequestDTO {
        AdminPayableListRequestDTO(
            branchId: branchId?.trimmedOrNil,
            supplierId: supplierId?.trimmedOrNil,
            effectiveStatus: status.apiValue,
            dueFrom: dueFrom?.trimmedOrNil,
            dueTo: dueTo?.trimmedOrNil,
            currency: currency?.trimmedOrNil?.uppercased(),
            asOf: asOf?.trimmedOrNil,
            limit: min(max(limit, 1), 100),
            cursor: cursor?.trimmedOrNil
        )
    }
}

extension AdminPayableAgingQuery {
    func toDTO() -> AdminPayableAgingRequestDTO {
        AdminPayableAgingRequestDTO(
            branchId: branchId?.trimmedOrNil,
            supplierId: supplierId?.trimmedOrNil,
            currency: currency?.trimmedOrNil?.uppercased(),
            asOf: asOf?.trimmedOrNil
        )
    }
}

private extension AdminProcurementMoneyDTO {
    func toPayableDomain(validatingCurrency expectedCurrency: String) throws -> AdminProcurementMoney {
        let normalizedCurrency = try AdminPayableMapperSupport.currency(currency)
        guard normalizedCurrency == expectedCurrency else {
            throw AppError.decoding("La moneda de un importe de cuenta por pagar no coincide con su contrato.")
        }
        guard let decimal = Decimal(
            string: amount,
            locale: Locale(identifier: "en_US_POSIX")
        ) else {
            throw AppError.decoding("Un importe de cuenta por pagar no es decimal válido.")
        }
        return AdminProcurementMoney(amount: decimal, currency: normalizedCurrency)
    }
}

private enum AdminPayableMapperSupport {
    static func currency(_ raw: String) throws -> String {
        let value = raw.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard value.range(of: "^[A-Z]{3}$", options: .regularExpression) != nil else {
            throw AppError.decoding("La moneda de la cuenta por pagar debe usar tres letras.")
        }
        return value
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
}
