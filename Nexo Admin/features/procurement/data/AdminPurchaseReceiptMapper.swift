//
//  AdminPurchaseReceiptMapper.swift
//  Nexo Admin
//
//  27R.N.4 — Lossless receipt mapping and fail-closed inventory-effect validation.
//

import Foundation

extension AdminPurchaseReceiptListResponseDTO {
    func toDomain() throws -> AdminPurchaseReceiptPage {
        AdminPurchaseReceiptPage(
            receipts: try purchaseReceipts.map { try $0.toDomain() },
            nextCursor: nextCursor,
            hasMore: hasMore
        )
    }
}

extension AdminPurchaseReceiptEnvelopeDTO {
    func toDomain() throws -> AdminPurchaseReceiptEnvelope {
        AdminPurchaseReceiptEnvelope(
            receipt: try data.toDomain(),
            requestId: meta.requestId,
            idempotencyReplayed: meta.idempotencyReplayed
        )
    }
}

extension AdminPurchaseReceiptDTO {
    func toDomain() throws -> AdminPurchaseReceipt {
        guard let status = AdminPurchaseReceiptStatus(rawValue: status) else {
            throw AppError.decoding("Estado de recepción no soportado: \(status).")
        }
        guard version > 0 else {
            throw AppError.decoding("La versión de la recepción debe ser positiva.")
        }
        guard !lines.isEmpty else {
            throw AppError.decoding("La recepción no contiene líneas.")
        }

        let mappedLines = try lines.map { try $0.toDomain() }
        guard Set(mappedLines.map(\.id)).count == mappedLines.count else {
            throw AppError.decoding("La recepción contiene líneas duplicadas.")
        }
        guard Set(inventoryMovementIds).count == inventoryMovementIds.count else {
            throw AppError.decoding("La recepción contiene movimientos de inventario duplicados.")
        }
        let lineMovementIds = mappedLines.compactMap(\.inventoryMovementId)
        guard Set(lineMovementIds) == Set(inventoryMovementIds),
              lineMovementIds.count == inventoryMovementIds.count else {
            throw AppError.decoding("La evidencia agregada de inventario no coincide con las líneas de recepción.")
        }
        if status != .confirmed, !inventoryMovementIds.isEmpty {
            throw AppError.decoding("El estado de la recepción no permite evidencia de inventario persistida.")
        }

        return AdminPurchaseReceipt(
            id: id,
            branchId: branchId,
            supplierId: supplierId,
            purchaseOrderId: purchaseOrderId,
            receiptNumber: receiptNumber,
            status: status,
            warehouseId: warehouseId,
            receivedAt: receivedAt,
            lines: mappedLines,
            inventoryMovementIds: inventoryMovementIds,
            attachmentIds: attachmentIds,
            notes: notes,
            createdAt: createdAt,
            createdBy: createdBy,
            updatedAt: updatedAt,
            updatedBy: updatedBy,
            confirmedAt: confirmedAt,
            confirmedBy: confirmedBy,
            cancelledAt: cancelledAt,
            cancelledBy: cancelledBy,
            cancellationReason: cancellationReason,
            version: version
        )
    }
}

extension AdminPurchaseReceiptLineDTO {
    func toDomain() throws -> AdminPurchaseReceiptLine {
        guard let kind = AdminPurchaseLineKind(rawValue: kind) else {
            throw AppError.decoding("Tipo de línea de recepción no soportado: \(kind).")
        }
        let received = try receiptQuantity(receivedQuantity, field: "cantidad recibida")
        let accepted = try receiptDecimal(acceptedQuantity, field: "cantidad aceptada")
        let rejected = try receiptDecimal(rejectedQuantity, field: "cantidad rechazada")
        guard received.value > 0, accepted >= 0, rejected >= 0, accepted + rejected == received.value else {
            throw AppError.decoding("Las cantidades recibida, aceptada y rechazada no son coherentes.")
        }
        guard received.unitCode == unitCode else {
            throw AppError.decoding("La unidad de la recepción no coincide con la cantidad recibida.")
        }
        if kind == .stockItem {
            guard catalogItemId != nil, itemSnapshot != nil else {
                throw AppError.decoding("La línea de producto no conserva su snapshot de catálogo.")
            }
        }
        if let snapshot = itemSnapshot, snapshot.catalogItemId != catalogItemId {
            throw AppError.decoding("El snapshot de catálogo no corresponde a la línea de recepción.")
        }

        return AdminPurchaseReceiptLine(
            id: id,
            purchaseOrderLineId: purchaseOrderLineId,
            kind: kind,
            catalogItemId: catalogItemId,
            itemSnapshot: itemSnapshot?.toDomain(),
            receivedQuantity: received,
            acceptedQuantity: accepted,
            rejectedQuantity: rejected,
            unitCode: unitCode,
            unitCost: try unitCost?.toDomain(),
            warehouseId: warehouseId,
            trackedUnits: try trackedUnits.map { try $0.toDomain() },
            inventoryMovementId: inventoryMovementId,
            notes: notes
        )
    }
}

extension AdminPurchaseTrackedUnitDTO {
    func toDomain() throws -> AdminPurchaseTrackedUnit {
        guard trackingType.trimmedOrNil != nil, trackingValue.trimmedOrNil != nil else {
            throw AppError.decoding("La evidencia de serie o lote está incompleta.")
        }
        return AdminPurchaseTrackedUnit(
            trackingType: trackingType,
            trackingValue: trackingValue,
            notes: notes
        )
    }
}

extension AdminPurchaseReceiptInventoryEffectsEnvelopeDTO {
    func toDomain() throws -> AdminPurchaseReceiptInventoryEffects {
        try data.toDomain(requestId: meta.requestId)
    }
}

extension AdminPurchaseReceiptInventoryEffectsDTO {
    func toDomain(requestId: String?) throws -> AdminPurchaseReceiptInventoryEffects {
        guard let receiptStatus = AdminPurchaseReceiptStatus(rawValue: receiptStatus) else {
            throw AppError.decoding("Estado de recepción de inventario no soportado: \(receiptStatus).")
        }
        guard let quantityStatus = AdminPurchaseReceiptQuantityReconciliationStatus(
            rawValue: quantityReconciliationStatus
        ) else {
            throw AppError.decoding("Estado de conciliación de cantidades no soportado.")
        }
        guard let valueStatus = AdminPurchaseReceiptValueStatus(rawValue: valueReconciliationStatus) else {
            throw AppError.decoding("Estado de conciliación de valores no soportado.")
        }

        let mappedLines = try lines.map {
            try $0.toDomain(
                receiptId: receiptId,
                receiptStatus: receiptStatus,
                costsVisible: costsVisible
            )
        }
        guard Set(mappedLines.map(\.receiptLineId)).count == mappedLines.count else {
            throw AppError.decoding("La conciliación contiene líneas duplicadas.")
        }
        switch quantityStatus {
        case .noEffectExpected:
            guard mappedLines.allSatisfy({ $0.effectStatus == .notApplicable }) else {
                throw AppError.decoding("El estado sin efecto contradice la evidencia por línea.")
            }
        case .pending:
            guard mappedLines.allSatisfy({ $0.effectStatus == .pending }) else {
                throw AppError.decoding("El estado pendiente contradice la evidencia por línea.")
            }
        case .reviewRequired:
            guard mappedLines.contains(where: { $0.effectStatus == .unverifiable }) else {
                throw AppError.decoding("La revisión requerida no identifica una línea no verificable.")
            }
        case .quantityReconciled:
            guard mappedLines.allSatisfy({
                $0.effectStatus == .quantityReconciled || $0.effectStatus == .notApplicable
            }) else {
                throw AppError.decoding("La conciliación de cantidades contiene una línea incompatible.")
            }
        }
        if !costsVisible, mappedLines.contains(where: { $0.unitCost != nil || $0.totalCost != nil }) {
            throw AppError.decoding("El backend declaró costos restringidos pero incluyó valores.")
        }
        if valueStatus == .sourceCurrencyLinked {
            guard costsVisible, mappedLines.contains(where: { $0.valueStatus == .sourceCurrencyLinked }) else {
                throw AppError.decoding("La moneda enlazada no tiene evidencia de costo visible.")
            }
        }

        return AdminPurchaseReceiptInventoryEffects(
            receiptId: receiptId,
            receiptNumber: receiptNumber,
            receiptStatus: receiptStatus,
            branchId: branchId,
            supplierId: supplierId,
            purchaseOrderId: purchaseOrderId,
            warehouseId: warehouseId,
            quantityStatus: quantityStatus,
            valueStatus: valueStatus,
            costsVisible: costsVisible,
            limitations: limitations,
            lines: mappedLines,
            requestId: requestId
        )
    }
}

extension AdminPurchaseReceiptInventoryEffectLineDTO {
    func toDomain(
        receiptId: String,
        receiptStatus: AdminPurchaseReceiptStatus,
        costsVisible: Bool
    ) throws -> AdminPurchaseReceiptInventoryEffectLine {
        guard let kind = AdminPurchaseLineKind(rawValue: kind) else {
            throw AppError.decoding("Tipo de línea de efecto no soportado: \(kind).")
        }
        guard let effectStatus = AdminPurchaseReceiptEffectStatus(rawValue: effectStatus) else {
            throw AppError.decoding("Estado de efecto de inventario no soportado.")
        }
        guard let valueStatus = AdminPurchaseReceiptValueStatus(rawValue: valueStatus) else {
            throw AppError.decoding("Estado de valor por línea no soportado.")
        }

        let accepted = try receiptQuantity(receiptAcceptedQuantity, field: "cantidad aceptada")
        let movement = try movementQuantity.map {
            try receiptQuantity($0, field: "cantidad del movimiento")
        }
        let before = try quantityBefore.map { try receiptDecimal($0, field: "saldo anterior") }
        let after = try quantityAfter.map { try receiptDecimal($0, field: "saldo posterior") }
        let mappedUnitCost = try unitCost?.toDomain()
        let mappedTotalCost = try totalCost?.toDomain()

        if !costsVisible, mappedUnitCost != nil || mappedTotalCost != nil {
            throw AppError.decoding("Una línea restringida expuso costos de inventario.")
        }
        if let unitCurrency = mappedUnitCost?.currency,
           let totalCurrency = mappedTotalCost?.currency,
           unitCurrency != totalCurrency {
            throw AppError.decoding("Los valores del movimiento usan monedas distintas.")
        }

        if effectStatus == .quantityReconciled {
            guard receiptStatus == .confirmed,
                  inventoryMovementId?.trimmedOrNil != nil,
                  movementType == "purchase_in",
                  direction == "in",
                  movement?.value == accepted.value,
                  movement?.unitCode == accepted.unitCode,
                  sourceType == "purchase_receipt",
                  sourceId == receiptId,
                  sourceLineId == receiptLineId,
                  before != nil,
                  after != nil,
                  after! - before! == accepted.value else {
                throw AppError.decoding("El movimiento no concilia con su línea de recepción.")
            }
        } else {
            let forbiddenEvidence: [Any?] = [
                inventoryMovementId, movementType, direction, movement,
                before, after, sourceType, sourceId, sourceLineId,
                occurredAt, createdBy, mappedUnitCost, mappedTotalCost
            ]
            guard forbiddenEvidence.compactMap({ $0 }).isEmpty else {
                throw AppError.decoding("Una línea sin efecto contiene evidencia de movimiento.")
            }
        }

        return AdminPurchaseReceiptInventoryEffectLine(
            receiptLineId: receiptLineId,
            kind: kind,
            catalogItemId: catalogItemId,
            receiptAcceptedQuantity: accepted,
            warehouseId: warehouseId,
            inventoryMovementId: inventoryMovementId,
            effectStatus: effectStatus,
            movementType: movementType,
            direction: direction,
            movementQuantity: movement,
            quantityBefore: before,
            quantityAfter: after,
            sourceType: sourceType,
            sourceId: sourceId,
            sourceLineId: sourceLineId,
            occurredAt: occurredAt,
            createdBy: createdBy,
            unitCost: mappedUnitCost,
            totalCost: mappedTotalCost,
            valueStatus: valueStatus
        )
    }
}

extension AdminPurchaseReceiptListQuery {
    func toDTO() -> AdminPurchaseReceiptListRequestDTO {
        AdminPurchaseReceiptListRequestDTO(
            branchId: branchId?.trimmedOrNil,
            supplierId: supplierId?.trimmedOrNil,
            purchaseOrderId: purchaseOrderId?.trimmedOrNil,
            status: status.apiValue,
            receivedFrom: receivedFrom?.trimmedOrNil,
            receivedTo: receivedTo?.trimmedOrNil,
            limit: min(max(limit, 1), 100),
            cursor: cursor?.trimmedOrNil
        )
    }
}

private func receiptQuantity(
    _ dto: AdminPurchaseQuantityDTO,
    field: String
) throws -> AdminPurchaseQuantity {
    guard dto.unitCode.trimmedOrNil != nil else {
        throw AppError.decoding("La unidad de \(field) está vacía.")
    }
    return AdminPurchaseQuantity(
        value: try receiptDecimal(dto.value, field: field),
        unitCode: dto.unitCode,
        allowsDecimal: dto.allowsDecimal
    )
}

private func receiptDecimal(_ raw: String, field: String) throws -> Decimal {
    guard let value = Decimal(string: raw, locale: Locale(identifier: "en_US_POSIX")) else {
        throw AppError.decoding("Valor inválido para \(field).")
    }
    return value
}
