//
//  AdminPurchaseOrderMapper.swift
//  Nexo Admin
//
//  Created by José Ruiz on 29/7/26.
//
//  27R.N.3 — Lossless order mapping with explicit cost-redaction boundaries.
//

import Foundation

extension AdminPurchaseOrderListResponseDTO {
    func toDomain() throws -> AdminPurchaseOrderPage {
        AdminPurchaseOrderPage(
            purchaseOrders: try purchaseOrders.map { try $0.toDomain() },
            nextCursor: nextCursor,
            hasMore: hasMore
        )
    }
}

extension AdminPurchaseOrderEnvelopeDTO {
    func toDomain() throws -> AdminPurchaseOrderEnvelope {
        AdminPurchaseOrderEnvelope(
            purchaseOrder: try data.toDomain(),
            requestId: meta.requestId,
            idempotencyReplayed: meta.idempotencyReplayed
        )
    }
}

extension AdminPurchaseOrderDTO {
    func toDomain() throws -> AdminPurchaseOrder {
        guard let status = AdminPurchaseOrderStatus(rawValue: self.status) else {
            throw AppError.decoding("Estado de orden de compra no soportado: \(self.status).")
        }
        guard !currency.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw AppError.decoding("La moneda de la orden de compra está vacía.")
        }
        guard version > 0 else {
            throw AppError.decoding("La versión de la orden de compra debe ser positiva.")
        }
        guard supplierSnapshot.supplierId == supplierId else {
            throw AppError.decoding("El snapshot del proveedor no corresponde a la orden de compra.")
        }

        let orderCostFields: [AdminProcurementMoneyDTO?] = [subtotal, discountTotal, taxTotal, total]
        let visibleOrderCostCount = orderCostFields.compactMap { $0 }.count
        guard visibleOrderCostCount == 0 || visibleOrderCostCount == orderCostFields.count else {
            throw AppError.decoding("La redacción de costos de la orden de compra es inconsistente.")
        }
        let costsVisible = visibleOrderCostCount == orderCostFields.count
        let mappedLines = try lines.map { try $0.toDomain(currency: currency, costsVisible: costsVisible) }
        guard !mappedLines.isEmpty else {
            throw AppError.decoding("La orden de compra no contiene líneas.")
        }

        let mappedSubtotal = try subtotal?.toDomain(validatingCurrency: currency)
        let mappedDiscount = try discountTotal?.toDomain(validatingCurrency: currency)
        let mappedTax = try taxTotal?.toDomain(validatingCurrency: currency)
        let mappedTotal = try total?.toDomain(validatingCurrency: currency)

        return AdminPurchaseOrder(
            id: id,
            branchId: branchId,
            supplierId: supplierId,
            orderNumber: orderNumber,
            status: status,
            currency: currency,
            lines: mappedLines,
            subtotal: mappedSubtotal,
            discountTotal: mappedDiscount,
            taxTotal: mappedTax,
            total: mappedTotal,
            expectedDate: expectedDate,
            supplierSnapshot: try supplierSnapshot.toDomain(),
            paymentTermsSnapshot: try paymentTermsSnapshot.toPurchaseOrderDomain(),
            notes: notes,
            attachmentIds: attachmentIds,
            createdAt: createdAt,
            createdBy: createdBy,
            updatedAt: updatedAt,
            updatedBy: updatedBy,
            sentAt: sentAt,
            sentBy: sentBy,
            closedAt: closedAt,
            closedBy: closedBy,
            closeReason: closeReason,
            cancelledAt: cancelledAt,
            cancelledBy: cancelledBy,
            cancellationReason: cancellationReason,
            version: version,
            costsVisible: costsVisible
        )
    }
}

extension AdminPurchaseOrderLineDTO {
    func toDomain(currency: String, costsVisible: Bool) throws -> AdminPurchaseOrderLine {
        guard let kind = AdminPurchaseLineKind(rawValue: self.kind) else {
            throw AppError.decoding("Tipo de línea de compra no soportado: \(self.kind).")
        }
        guard let taxMode = AdminPurchasePriceTaxMode(rawValue: priceTaxMode) else {
            throw AppError.decoding("Modo tributario de compra no soportado: \(priceTaxMode).")
        }

        let costFields: [Any?] = [
            unitCost, discountAmount, taxes, grossAmount, netAmount, taxAmount, lineTotal
        ]
        let visibleCostCount = costFields.compactMap { $0 }.count
        let lineCostsVisible = visibleCostCount == costFields.count
        guard visibleCostCount == 0 || lineCostsVisible, lineCostsVisible == costsVisible else {
            throw AppError.decoding("La redacción de costos de una línea de compra es inconsistente.")
        }

        let ordered = try orderedQuantity.toDomain()
        let received = try decimalPurchaseValue(receivedQuantity, field: "cantidad recibida")
        guard received >= 0, received <= ordered.value else {
            throw AppError.decoding("La cantidad recibida está fuera del rango ordenado.")
        }
        if kind == .stockItem {
            guard catalogItemId != nil, catalogItemSnapshot != nil else {
                throw AppError.decoding("La línea de producto no conserva su snapshot de catálogo.")
            }
        }
        if let snapshot = catalogItemSnapshot, snapshot.catalogItemId != catalogItemId {
            throw AppError.decoding("El snapshot de catálogo no corresponde a la línea de compra.")
        }

        return AdminPurchaseOrderLine(
            id: id,
            kind: kind,
            catalogItemId: catalogItemId,
            catalogItemSnapshot: catalogItemSnapshot?.toDomain(),
            descriptionSnapshot: descriptionSnapshot,
            orderedQuantity: ordered,
            receivedQuantity: received,
            unitCost: try unitCost?.toDomain(validatingCurrency: currency),
            discountAmount: try discountAmount?.toDomain(validatingCurrency: currency),
            priceTaxMode: taxMode,
            taxProfileId: taxProfileId,
            taxProfileVersion: taxProfileVersion,
            taxes: try taxes?.map { try $0.toDomain(currency: currency) },
            grossAmount: try grossAmount?.toDomain(validatingCurrency: currency),
            netAmount: try netAmount?.toDomain(validatingCurrency: currency),
            taxAmount: try taxAmount?.toDomain(validatingCurrency: currency),
            lineTotal: try lineTotal?.toDomain(validatingCurrency: currency),
            targetWarehouseId: targetWarehouseId,
            notes: notes
        )
    }
}

extension AdminPurchaseQuantityDTO {
    func toDomain() throws -> AdminPurchaseQuantity {
        let value = try decimalPurchaseValue(self.value, field: "cantidad ordenada")
        guard value > 0 else {
            throw AppError.decoding("La cantidad ordenada debe ser positiva.")
        }
        return AdminPurchaseQuantity(value: value, unitCode: unitCode, allowsDecimal: allowsDecimal)
    }
}

extension AdminPurchaseTaxDTO {
    func toDomain(currency: String) throws -> AdminPurchaseTax {
        AdminPurchaseTax(
            taxCode: taxCode,
            rateCode: rateCode,
            rate: try decimalPurchaseValue(rate, field: "tasa de impuesto"),
            taxableBase: try taxableBase.toDomain(validatingCurrency: currency),
            amount: try amount.toDomain(validatingCurrency: currency)
        )
    }
}

extension AdminPurchaseItemSnapshotDTO {
    func toDomain() -> AdminPurchaseItemSnapshot {
        AdminPurchaseItemSnapshot(
            catalogItemId: catalogItemId,
            localName: localName,
            sku: sku,
            unitCode: unitCode,
            taxProfileId: taxProfileId,
            taxProfileVersion: taxProfileVersion
        )
    }
}

extension AdminPurchaseSupplierSnapshotDTO {
    func toDomain() throws -> AdminPurchaseSupplierSnapshot {
        let identificationType: AdminSupplierIdentificationType?
        if let raw = self.identificationType {
            guard let value = AdminSupplierIdentificationType(rawValue: raw) else {
                throw AppError.decoding("Tipo de identificación del proveedor no soportado: \(raw).")
            }
            identificationType = value
        } else {
            identificationType = nil
        }
        return AdminPurchaseSupplierSnapshot(
            supplierId: supplierId,
            legalName: legalName,
            tradeName: tradeName,
            identificationType: identificationType,
            identificationNumber: identificationNumber,
            paymentTerms: try paymentTerms.toPurchaseOrderDomain(),
            defaultCurrency: defaultCurrency
        )
    }
}

extension AdminSupplierPaymentTermsDTO {
    func toPurchaseOrderDomain() throws -> AdminSupplierPaymentTerms {
        guard let mode = AdminSupplierPaymentTermsMode(rawValue: self.mode) else {
            throw AppError.decoding("Condición de pago no soportada: \(self.mode).")
        }
        return AdminSupplierPaymentTerms(mode: mode, netDays: netDays, label: label, notes: notes)
    }
}

extension AdminProcurementMoneyDTO {
    func toDomain(validatingCurrency expectedCurrency: String) throws -> AdminProcurementMoney {
        let money = try toDomain()
        guard money.currency == expectedCurrency else {
            throw AppError.decoding("La moneda de un valor de compra no coincide con la orden.")
        }
        return money
    }
}

extension AdminPurchaseOrderListQuery {
    func toDTO() -> AdminPurchaseOrderListRequestDTO {
        AdminPurchaseOrderListRequestDTO(
            branchId: branchId?.trimmedOrNil,
            supplierId: supplierId?.trimmedOrNil,
            status: status.apiValue,
            expectedFrom: expectedFrom?.trimmedOrNil,
            expectedTo: expectedTo?.trimmedOrNil,
            query: query?.trimmedOrNil,
            limit: min(max(limit, 1), 100),
            cursor: cursor?.trimmedOrNil
        )
    }
}

private func decimalPurchaseValue(_ raw: String, field: String) throws -> Decimal {
    guard let value = Decimal(string: raw, locale: Locale(identifier: "en_US_POSIX")) else {
        throw AppError.decoding("Valor inválido para \(field).")
    }
    return value
}
