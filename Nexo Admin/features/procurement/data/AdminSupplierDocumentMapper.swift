//
//  AdminSupplierDocumentMapper.swift
//  Nexo Admin
//
//  Created by José Ruiz on 29/7/26.
//
//  27R.N — Lossless supplier document mapping without local total calculation.
//

import Foundation

extension AdminSupplierDocumentListResponseDTO {
    func toDomain() throws -> AdminSupplierDocumentPage {
        AdminSupplierDocumentPage(
            supplierDocuments: try supplierDocuments.map { try $0.toDomain() },
            nextCursor: nextCursor,
            hasMore: hasMore
        )
    }
}

extension AdminSupplierDocumentEnvelopeDTO {
    func toDomain() throws -> AdminSupplierDocumentEnvelope {
        AdminSupplierDocumentEnvelope(
            supplierDocument: try data.toDomain(),
            requestId: meta.requestId,
            idempotencyReplayed: meta.idempotencyReplayed
        )
    }
}

extension AdminSupplierDocumentDTO {
    func toDomain() throws -> AdminSupplierDocument {
        guard let documentType = AdminSupplierDocumentType(rawValue: self.documentType) else {
            throw AppError.decoding("Tipo de documento de proveedor no soportado: \(self.documentType).")
        }
        guard let status = AdminSupplierDocumentStatus(rawValue: self.status) else {
            throw AppError.decoding("Estado de documento de proveedor no soportado: \(self.status).")
        }
        guard let accountingStatus = AdminSupplierDocumentAccountingStatus(rawValue: self.accountingStatus) else {
            throw AppError.decoding("Estado contable operativo no soportado: \(self.accountingStatus).")
        }
        guard !currency.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw AppError.decoding("La moneda del documento de proveedor está vacía.")
        }
        guard !documentNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw AppError.decoding("El número del documento de proveedor está vacío.")
        }
        guard version > 0 else {
            throw AppError.decoding("La versión del documento de proveedor debe ser positiva.")
        }

        let mappedLines = try lines.map { try $0.toDomain(currency: currency) }
        guard !mappedLines.isEmpty else {
            throw AppError.decoding("El documento de proveedor no contiene líneas.")
        }

        return AdminSupplierDocument(
            id: id,
            branchId: branchId,
            supplierId: supplierId,
            documentType: documentType,
            status: status,
            documentNumber: documentNumber,
            documentNumberNormalized: documentNumberNormalized,
            accessKey: accessKey,
            authorizationNumber: authorizationNumber,
            documentDate: documentDate,
            dueDate: dueDate,
            currency: currency,
            purchaseOrderIds: purchaseOrderIds,
            purchaseReceiptIds: purchaseReceiptIds,
            lines: mappedLines,
            subtotal: try subtotal.toDomain(validatingCurrency: currency),
            discountTotal: try discountTotal.toDomain(validatingCurrency: currency),
            taxTotal: try taxTotal.toDomain(validatingCurrency: currency),
            total: try total.toDomain(validatingCurrency: currency),
            sourceTotals: try sourceTotals?.toDomain(currency: currency),
            sourcePayment: try sourcePayment?.toDomain(currency: currency),
            payableAmount: try payableAmount.toDomain(validatingCurrency: currency),
            payableId: payableId,
            attachmentIds: attachmentIds,
            accountingStatus: accountingStatus,
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

extension AdminSupplierDocumentLineDTO {
    func toDomain(currency: String) throws -> AdminSupplierDocumentLine {
        guard let kind = AdminPurchaseLineKind(rawValue: self.kind) else {
            throw AppError.decoding("Tipo de línea de documento no soportado: \(self.kind).")
        }
        guard let priceTaxMode = AdminPurchasePriceTaxMode(rawValue: self.priceTaxMode) else {
            throw AppError.decoding("Modo tributario del documento no soportado: \(self.priceTaxMode).")
        }

        let mappedQuantity = try quantity.toSupplierDocumentDomain()
        if kind == .stockItem {
            guard catalogItemId != nil, catalogItemSnapshot != nil else {
                throw AppError.decoding("La línea de producto no conserva su snapshot de catálogo.")
            }
        }
        if let snapshot = catalogItemSnapshot, snapshot.catalogItemId != catalogItemId {
            throw AppError.decoding("El snapshot de catálogo no corresponde a la línea del documento.")
        }

        return AdminSupplierDocumentLine(
            id: id,
            kind: kind,
            catalogItemId: catalogItemId,
            catalogItemSnapshot: catalogItemSnapshot?.toDomain(),
            purchaseOrderLineId: purchaseOrderLineId,
            purchaseReceiptLineId: purchaseReceiptLineId,
            descriptionSnapshot: descriptionSnapshot,
            quantity: mappedQuantity,
            unitCost: try unitCost.toDomain(validatingCurrency: currency),
            discountAmount: try discountAmount.toDomain(validatingCurrency: currency),
            priceTaxMode: priceTaxMode,
            taxProfileId: taxProfileId,
            taxProfileVersion: taxProfileVersion,
            taxes: try taxes.map { try $0.toDomain(currency: currency) },
            grossAmount: try grossAmount.toDomain(validatingCurrency: currency),
            netAmount: try netAmount.toDomain(validatingCurrency: currency),
            taxAmount: try taxAmount.toDomain(validatingCurrency: currency),
            lineTotal: try lineTotal.toDomain(validatingCurrency: currency),
            expenseCategoryCode: expenseCategoryCode,
            notes: notes
        )
    }
}

extension AdminSupplierDocumentSourceTotalsDTO {
    func toDomain(currency: String) throws -> AdminSupplierDocumentSourceTotals {
        AdminSupplierDocumentSourceTotals(
            total: try total.toDomain(validatingCurrency: currency),
            taxTotal: try taxTotal.toDomain(validatingCurrency: currency)
        )
    }
}

extension AdminSupplierDocumentSourcePaymentDTO {
    func toDomain(currency: String) throws -> AdminSupplierDocumentSourcePayment {
        AdminSupplierDocumentSourcePayment(
            amount: try amount.toDomain(validatingCurrency: currency),
            method: method,
            paymentDate: paymentDate,
            reference: reference
        )
    }
}

extension AdminPurchaseQuantityDTO {
    func toSupplierDocumentDomain() throws -> AdminPurchaseQuantity {
        guard let value = Decimal(string: self.value, locale: Locale(identifier: "en_US_POSIX")), value > 0 else {
            throw AppError.decoding("La cantidad del documento de proveedor debe ser positiva.")
        }
        return AdminPurchaseQuantity(value: value, unitCode: unitCode, allowsDecimal: allowsDecimal)
    }
}

extension AdminSupplierDocumentListQuery {
    func toDTO() -> AdminSupplierDocumentListRequestDTO {
        AdminSupplierDocumentListRequestDTO(
            branchId: branchId?.trimmedOrNil,
            supplierId: supplierId?.trimmedOrNil,
            documentType: documentType.apiValue,
            status: status.apiValue,
            documentDateFrom: documentDateFrom?.trimmedOrNil,
            documentDateTo: documentDateTo?.trimmedOrNil,
            dueDateFrom: dueDateFrom?.trimmedOrNil,
            dueDateTo: dueDateTo?.trimmedOrNil,
            query: query?.trimmedOrNil,
            limit: min(max(limit, 1), 100),
            cursor: cursor?.trimmedOrNil
        )
    }
}
