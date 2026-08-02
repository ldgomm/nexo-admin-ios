//
//  AdminSupplierPaymentMapper.swift
//  Nexo Admin
//
//  Created by José Ruiz on 29/7/26.
//
//  27R.N — Canonical supplier-payment mapping and reconciliation guards.
//

import Foundation

extension AdminSupplierPaymentListResponseDTO {
    func toDomain() throws -> AdminSupplierPaymentPage {
        AdminSupplierPaymentPage(
            supplierPayments: try supplierPayments.map { try $0.toDomain() },
            nextCursor: nextCursor?.trimmedOrNil,
            hasMore: hasMore
        )
    }
}

extension AdminSupplierPaymentEnvelopeDTO {
    func toDomain() throws -> AdminSupplierPaymentEnvelope {
        AdminSupplierPaymentEnvelope(
            supplierPayment: try data.toDomain(),
            requestId: meta.requestId,
            idempotencyReplayed: meta.idempotencyReplayed
        )
    }

    func toMutationDomain() throws -> AdminSupplierPaymentMutationResult {
        AdminSupplierPaymentMutationResult(
            supplierPayment: try data.toDomain(),
            requestId: meta.requestId,
            idempotencyReplayed: meta.idempotencyReplayed
        )
    }
}

extension AdminSupplierPaymentDTO {
    func toDomain() throws -> AdminSupplierPayment {
        let normalizedCurrency = try AdminSupplierPaymentMapperSupport.currency(currency)
        guard let mappedStatus = AdminSupplierPaymentStatus(rawValue: status) else {
            throw AppError.decoding("Estado de pago a proveedor no soportado: \(status).")
        }
        guard AdminSupplierPaymentMapperSupport.isValidDate(paymentDate) else {
            throw AppError.decoding("La fecha del pago a proveedor no es válida.")
        }
        guard paymentNumber.range(
            of: "^SP-[0-9]{6}-[0-9]{6}$",
            options: .regularExpression
        ) != nil else {
            throw AppError.decoding("El número del pago a proveedor no cumple el contrato SP-YYYYMM-######.")
        }
        guard version > 0 else {
            throw AppError.decoding("La versión del pago a proveedor debe ser positiva.")
        }
        guard AdminSupplierPaymentMapperSupport.nonBlank(id),
              AdminSupplierPaymentMapperSupport.nonBlank(branchId),
              AdminSupplierPaymentMapperSupport.nonBlank(supplierId),
              AdminSupplierPaymentMapperSupport.nonBlank(createdBy),
              AdminSupplierPaymentMapperSupport.nonBlank(updatedBy) else {
            throw AppError.decoding("La identidad o auditoría del pago a proveedor está incompleta.")
        }

        let createdDate = try AdminSupplierPaymentMapperSupport.timestamp(createdAt, field: "createdAt")
        let updatedDate = try AdminSupplierPaymentMapperSupport.timestamp(updatedAt, field: "updatedAt")
        guard updatedDate >= createdDate else {
            throw AppError.decoding("La fecha de actualización del pago precede su creación.")
        }

        let mappedMethod: AdminSupplierPaymentMethod?
        if let method = method?.trimmedOrNil {
            guard let value = AdminSupplierPaymentMethod(rawValue: method.uppercased()) else {
                throw AppError.decoding("Método de pago a proveedor no soportado: \(method).")
            }
            mappedMethod = value
        } else {
            mappedMethod = nil
            guard reference?.trimmedOrNil == nil else {
                throw AppError.decoding("La referencia sensible llegó sin método de pago visible.")
            }
        }

        let mappedAmount = try amount.toSupplierPaymentMoney(validatingCurrency: normalizedCurrency)
        guard mappedAmount.amount > 0 else {
            throw AppError.decoding("El importe del pago a proveedor debe ser mayor que cero.")
        }
        guard !allocations.isEmpty else {
            throw AppError.decoding("El pago a proveedor debe incluir aplicaciones.")
        }

        let mappedAllocations = try allocations.map {
            try $0.toDomain(validatingCurrency: normalizedCurrency)
        }
        guard Set(mappedAllocations.map(\.id)).count == mappedAllocations.count,
              Set(mappedAllocations.map(\.payableId)).count == mappedAllocations.count else {
            throw AppError.decoding("Las aplicaciones del pago deben ser únicas por identidad y cuenta por pagar.")
        }
        let allocatedAmount = mappedAllocations.reduce(Decimal.zero) { $0 + $1.amount.amount }
        guard allocatedAmount == mappedAmount.amount else {
            throw AppError.decoding("El importe del pago no reconcilia con sus aplicaciones.")
        }

        let normalizedAttachments = try AdminSupplierPaymentMapperSupport.identifiers(
            attachmentIds,
            field: "adjuntos"
        )
        let normalizedCashMovementId = cashMovementId?.trimmedOrNil
        let normalizedNotes = notes?.trimmedOrNil
        let normalizedReference = reference?.trimmedOrNil
        let normalizedVoidReason = voidReason?.trimmedOrNil
        let recordedDate = try AdminSupplierPaymentMapperSupport.optionalTimestamp(recordedAt, field: "recordedAt")
        let voidedDate = try AdminSupplierPaymentMapperSupport.optionalTimestamp(voidedAt, field: "voidedAt")
        let normalizedRecordedBy = recordedBy?.trimmedOrNil
        let normalizedVoidedBy = voidedBy?.trimmedOrNil

        try AdminSupplierPaymentMapperSupport.validateLifecycle(
            status: mappedStatus,
            createdAt: createdDate,
            recordedAt: recordedDate,
            recordedBy: normalizedRecordedBy,
            voidedAt: voidedDate,
            voidedBy: normalizedVoidedBy,
            voidReason: normalizedVoidReason,
            allocations: mappedAllocations
        )

        return AdminSupplierPayment(
            id: id,
            branchId: branchId,
            supplierId: supplierId,
            paymentNumber: paymentNumber,
            paymentDate: paymentDate,
            currency: normalizedCurrency,
            amount: mappedAmount,
            method: mappedMethod,
            reference: normalizedReference,
            status: mappedStatus,
            allocations: mappedAllocations,
            attachmentIds: normalizedAttachments,
            cashMovementId: normalizedCashMovementId,
            notes: normalizedNotes,
            createdAt: createdAt,
            createdBy: createdBy,
            updatedAt: updatedAt,
            updatedBy: updatedBy,
            recordedAt: recordedAt,
            recordedBy: normalizedRecordedBy,
            voidedAt: voidedAt,
            voidedBy: normalizedVoidedBy,
            voidReason: normalizedVoidReason,
            version: version
        )
    }
}

extension AdminSupplierPaymentAllocationDTO {
    func toDomain(validatingCurrency currency: String) throws -> AdminSupplierPaymentAllocation {
        guard let mappedStatus = AdminSupplierPaymentAllocationStatus(rawValue: status) else {
            throw AppError.decoding("Estado de aplicación de pago no soportado: \(status).")
        }
        guard AdminSupplierPaymentMapperSupport.nonBlank(id),
              AdminSupplierPaymentMapperSupport.nonBlank(payableId),
              AdminSupplierPaymentMapperSupport.nonBlank(createdBy) else {
            throw AppError.decoding("La identidad o auditoría de una aplicación de pago está incompleta.")
        }

        let mappedAmount = try amount.toSupplierPaymentMoney(validatingCurrency: currency)
        let before = try payableBalanceBefore.toSupplierPaymentMoney(validatingCurrency: currency)
        let after = try payableBalanceAfter.toSupplierPaymentMoney(validatingCurrency: currency)
        guard mappedAmount.amount > 0, before.amount >= 0, after.amount >= 0 else {
            throw AppError.decoding("Los importes de una aplicación de pago no son válidos.")
        }
        guard before.amount - mappedAmount.amount == after.amount else {
            throw AppError.decoding("La aplicación no reconcilia saldo anterior, importe y saldo posterior.")
        }

        let createdDate = try AdminSupplierPaymentMapperSupport.timestamp(createdAt, field: "allocation.createdAt")
        let reversedDate = try AdminSupplierPaymentMapperSupport.optionalTimestamp(
            reversedAt,
            field: "allocation.reversedAt"
        )
        let normalizedReversedBy = reversedBy?.trimmedOrNil
        let normalizedReason = reversalReason?.trimmedOrNil

        switch mappedStatus {
        case .applied:
            guard reversedDate == nil, normalizedReversedBy == nil, normalizedReason == nil else {
                throw AppError.decoding("Una aplicación activa no puede contener evidencia de reverso.")
            }
        case .reversed:
            guard let reversedDate, reversedDate >= createdDate,
                  normalizedReversedBy != nil,
                  normalizedReason != nil else {
                throw AppError.decoding("Una aplicación revertida requiere fecha, actor y motivo válidos.")
            }
        }

        return AdminSupplierPaymentAllocation(
            id: id,
            payableId: payableId,
            amount: mappedAmount,
            payableBalanceBefore: before,
            payableBalanceAfter: after,
            status: mappedStatus,
            createdAt: createdAt,
            createdBy: createdBy,
            reversedAt: reversedAt,
            reversedBy: normalizedReversedBy,
            reversalReason: normalizedReason
        )
    }
}

extension AdminSupplierPaymentListQuery {
    func toDTO() -> AdminSupplierPaymentListRequestDTO {
        AdminSupplierPaymentListRequestDTO(
            branchId: branchId?.trimmedOrNil,
            supplierId: supplierId?.trimmedOrNil,
            status: status.apiValue,
            paymentFrom: paymentFrom?.trimmedOrNil,
            paymentTo: paymentTo?.trimmedOrNil,
            method: method.apiValue,
            query: query?.trimmedOrNil,
            limit: min(max(limit, 1), 100),
            cursor: cursor?.trimmedOrNil
        )
    }
}

extension AdminSupplierPaymentVoidInput {
    func toDTO() -> AdminSupplierPaymentVoidRequestDTO {
        AdminSupplierPaymentVoidRequestDTO(
            reason: reason.trimmingCharacters(in: .whitespacesAndNewlines),
            expectedVersion: expectedVersion
        )
    }
}

private extension AdminProcurementMoneyDTO {
    func toSupplierPaymentMoney(validatingCurrency expectedCurrency: String) throws -> AdminProcurementMoney {
        let normalizedCurrency = try AdminSupplierPaymentMapperSupport.currency(currency)
        guard normalizedCurrency == expectedCurrency else {
            throw AppError.decoding("La moneda de una aplicación no coincide con el pago a proveedor.")
        }
        guard let decimal = Decimal(
            string: amount,
            locale: Locale(identifier: "en_US_POSIX")
        ) else {
            throw AppError.decoding("Un importe de pago a proveedor no es decimal válido.")
        }
        return AdminProcurementMoney(amount: decimal, currency: normalizedCurrency)
    }
}

private enum AdminSupplierPaymentMapperSupport {
    static func nonBlank(_ raw: String) -> Bool {
        raw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
    }

    static func currency(_ raw: String) throws -> String {
        let value = raw.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard value.range(of: "^[A-Z]{3}$", options: .regularExpression) != nil else {
            throw AppError.decoding("La moneda del pago a proveedor debe usar tres letras.")
        }
        return value
    }

    static func identifiers(_ raw: [String]?, field: String) throws -> [String]? {
        guard let raw else { return nil }
        let values = raw.compactMap { $0.trimmedOrNil }
        guard values.count == raw.count, Set(values).count == values.count else {
            throw AppError.decoding("Los \(field) del pago deben ser únicos y no vacíos.")
        }
        return values
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

    static func timestamp(_ raw: String, field: String) throws -> Date {
        guard let value = parseTimestamp(raw) else {
            throw AppError.decoding("La marca de tiempo \(field) del pago no es válida.")
        }
        return value
    }

    static func optionalTimestamp(_ raw: String?, field: String) throws -> Date? {
        guard let raw = raw?.trimmedOrNil else { return nil }
        return try timestamp(raw, field: field)
    }

    static func parseTimestamp(_ raw: String) -> Date? {
        let fractional = ISO8601DateFormatter()
        fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let value = fractional.date(from: raw) { return value }
        let standard = ISO8601DateFormatter()
        standard.formatOptions = [.withInternetDateTime]
        return standard.date(from: raw)
    }

    static func validateLifecycle(
        status: AdminSupplierPaymentStatus,
        createdAt: Date,
        recordedAt: Date?,
        recordedBy: String?,
        voidedAt: Date?,
        voidedBy: String?,
        voidReason: String?,
        allocations: [AdminSupplierPaymentAllocation]
    ) throws {
        let hasRecordedEvidence = recordedAt != nil && recordedBy != nil
        let hasAnyRecordedEvidence = recordedAt != nil || recordedBy != nil
        let hasFinalVoidEvidence = voidedAt != nil || voidedBy != nil

        if let recordedAt, recordedAt < createdAt {
            throw AppError.decoding("La fecha de registro del pago precede su creación.")
        }
        if let voidedAt, let recordedAt, voidedAt < recordedAt {
            throw AppError.decoding("La fecha de anulación del pago precede su registro.")
        }

        switch status {
        case .processing:
            guard !hasAnyRecordedEvidence, !hasFinalVoidEvidence, voidReason == nil else {
                throw AppError.decoding("Un pago en proceso contiene evidencia de registro o anulación incompatible.")
            }
            guard allocations.allSatisfy({ $0.status == .applied }) else {
                throw AppError.decoding("Un pago en proceso no puede exponer aplicaciones revertidas.")
            }
        case .recorded:
            guard hasRecordedEvidence, !hasFinalVoidEvidence, voidReason == nil else {
                throw AppError.decoding("Un pago registrado requiere evidencia de registro y no de anulación.")
            }
            guard allocations.allSatisfy({ $0.status == .applied }) else {
                throw AppError.decoding("Un pago registrado requiere todas sus aplicaciones activas.")
            }
        case .voiding:
            guard hasRecordedEvidence, !hasFinalVoidEvidence, voidReason != nil else {
                throw AppError.decoding("Un pago en anulación requiere registro y motivo, sin cierre final todavía.")
            }
        case .voided:
            guard hasRecordedEvidence, voidedAt != nil, voidedBy != nil, voidReason != nil else {
                throw AppError.decoding("Un pago anulado requiere actor, fecha y motivo de anulación.")
            }
            guard allocations.allSatisfy({ $0.status == .reversed }) else {
                throw AppError.decoding("Un pago anulado requiere todas sus aplicaciones revertidas.")
            }
        }
    }
}
