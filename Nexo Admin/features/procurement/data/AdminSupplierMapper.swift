//
//  AdminSupplierMapper.swift
//  Nexo Admin
//
//  27R.N.2 — Lossless supplier mapping and deterministic writes.
//

import Foundation

extension AdminSupplierListResponseDTO {
    func toDomain() throws -> AdminSupplierPage {
        AdminSupplierPage(
            suppliers: try suppliers.map { try $0.toDomain() },
            nextCursor: nextCursor,
            hasMore: hasMore
        )
    }
}

extension AdminSupplierEnvelopeDTO {
    func toDomain() throws -> AdminSupplierMutationResult {
        AdminSupplierMutationResult(
            supplier: try data.toDomain(),
            requestId: meta.requestId,
            idempotencyReplayed: meta.idempotencyReplayed
        )
    }
}

extension AdminSupplierDTO {
    func toDomain() throws -> AdminSupplier {
        guard let status = AdminSupplierStatus(rawValue: self.status) else {
            throw AppError.decoding("Estado de proveedor no soportado: \(self.status).")
        }
        let identificationType: AdminSupplierIdentificationType?
        if let raw = self.identificationType {
            guard let value = AdminSupplierIdentificationType(rawValue: raw) else {
                throw AppError.decoding("Tipo de identificación de proveedor no soportado: \(raw).")
            }
            identificationType = value
        } else {
            identificationType = nil
        }
        guard let paymentMode = AdminSupplierPaymentTermsMode(rawValue: paymentTerms.mode) else {
            throw AppError.decoding("Condición de pago no soportada: \(paymentTerms.mode).")
        }

        return AdminSupplier(
            id: id,
            legalName: legalName,
            tradeName: tradeName,
            identificationType: identificationType,
            identificationNumber: identificationNumber,
            email: email,
            phone: phone,
            address: address,
            categories: categories.sorted(),
            contacts: contacts?.map {
                AdminSupplierContact(
                    id: $0.id,
                    name: $0.name,
                    role: $0.role,
                    email: $0.email,
                    phone: $0.phone,
                    isPrimary: $0.isPrimary,
                    notes: $0.notes
                )
            },
            paymentTerms: AdminSupplierPaymentTerms(
                mode: paymentMode,
                netDays: paymentTerms.netDays,
                label: paymentTerms.label,
                notes: paymentTerms.notes
            ),
            defaultCurrency: defaultCurrency,
            status: status,
            notes: notes,
            createdAt: createdAt,
            createdBy: createdBy,
            updatedAt: updatedAt,
            updatedBy: updatedBy,
            version: version
        )
    }
}

extension AdminSupplierListQuery {
    func toDTO() -> AdminSupplierListRequestDTO {
        AdminSupplierListRequestDTO(
            query: query?.trimmedOrNil,
            status: status.apiValue,
            category: category?.trimmedOrNil,
            limit: min(max(limit, 1), 100),
            cursor: cursor?.trimmedOrNil
        )
    }
}

extension AdminSupplierWriteInput {
    func toDTO() -> AdminSupplierWriteRequestDTO {
        let normalizedCategories = Array(
            Set(categories.compactMap { $0.trimmedOrNil?.lowercased() })
        ).sorted()

        return AdminSupplierWriteRequestDTO(
            legalName: legalName.trimmingCharacters(in: .whitespacesAndNewlines),
            tradeName: tradeName.trimmedOrNil,
            identificationType: identificationType?.rawValue,
            identificationNumber: identificationNumber.trimmedOrNil,
            email: email.trimmedOrNil,
            phone: phone.trimmedOrNil,
            address: address.trimmedOrNil,
            categories: normalizedCategories,
            contacts: contacts.map {
                AdminSupplierContactWriteRequestDTO(
                    id: $0.serverId?.trimmedOrNil,
                    name: $0.name.trimmingCharacters(in: .whitespacesAndNewlines),
                    role: $0.role.trimmedOrNil,
                    email: $0.email.trimmedOrNil,
                    phone: $0.phone.trimmedOrNil,
                    isPrimary: $0.isPrimary,
                    notes: $0.notes.trimmedOrNil
                )
            },
            paymentTerms: AdminSupplierPaymentTermsWriteRequestDTO(
                mode: paymentTermsMode.rawValue,
                netDays: paymentTermsMode == .immediate ? 0 : netDays,
                label: paymentTermsMode == .custom ? paymentTermsLabel.trimmedOrNil : nil,
                notes: paymentTermsNotes.trimmedOrNil
            ),
            defaultCurrency: "USD",
            notes: notes.trimmedOrNil,
            expectedVersion: expectedVersion
        )
    }
}

extension AdminSupplierStatusInput {
    func toDTO() -> AdminSupplierStatusRequestDTO {
        AdminSupplierStatusRequestDTO(
            status: status.rawValue,
            reason: reason.trimmingCharacters(in: .whitespacesAndNewlines),
            expectedVersion: expectedVersion
        )
    }
}
