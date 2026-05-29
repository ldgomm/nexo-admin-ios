//
//  AdminTaxSriMapper.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import Foundation

extension AdminTaxSettingsResponseDTO {
    func toDomain() -> AdminTaxSettings {
        AdminTaxSettings(
            organizationId: organizationId,
            regimeCode: regimeCode ?? "unknown",
            regimeName: regimeName ?? "Sin régimen configurado",
            defaultTaxProfileId: defaultTaxProfileId,
            defaultCurrency: defaultCurrency ?? "USD",
            obligatedToKeepAccounting: obligatedToKeepAccounting ?? false,
            specialTaxpayerNumber: specialTaxpayerNumber,
            rimpeLegend: rimpeLegend,
            withholdingAgentResolution: withholdingAgentResolution,
            updatedAt: updatedAt,
            version: version ?? 0
        )
    }
}

extension AdminTaxProfileResponseDTO {
    func toDomain() -> AdminTaxProfile {
        AdminTaxProfile(
            id: id,
            code: code,
            name: name,
            description: description ?? "",
            status: status ?? "active",
            taxName: taxName ?? "IVA",
            rate: Decimal(string: rate ?? "0") ?? 0,
            sriTaxCode: sriTaxCode ?? "",
            sriRateCode: sriRateCode ?? "",
            legalBasis: legalBasis,
            effectiveFrom: effectiveFrom,
            effectiveTo: effectiveTo,
            editable: editable ?? false
        )
    }
}

extension AdminElectronicSignatureResponseDTO {
    func toDomain() -> AdminElectronicSignature {
        let resolvedStatus = status ?? "unknown"
        let resolvedEffectiveStatus = effectiveStatus ?? resolvedStatus

        let normalizedStatus = resolvedStatus.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        let normalizedEffectiveStatus = resolvedEffectiveStatus.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        let statusLooksUsable = normalizedStatus == "VALID"
            || normalizedStatus == "ACTIVE"
            || normalizedEffectiveStatus == "VALID"
            || normalizedEffectiveStatus == "ACTIVE"

        let resolvedUsable = usable ?? isActive ?? statusLooksUsable

        return AdminElectronicSignature(
            id: id,
            organizationId: organizationId ?? "",
            alias: alias ?? subject ?? "Firma electrónica",
            subject: subject ?? "Sin sujeto",
            issuer: issuer ?? "Sin emisor",
            serialNumber: serialNumber ?? "",
            validFrom: validFrom,
            validTo: validTo,
            status: resolvedStatus,
            effectiveStatus: resolvedEffectiveStatus,
            usable: resolvedUsable,
            expiresInDays: daysUntilExpiration ?? expiresInDays,
            expiresSoon: expiresSoon ?? false,
            uploadedBy: uploadedBy,
            uploadedAt: uploadedAt,
            lastUsedAt: lastUsedAt,
            lastValidatedAt: lastValidatedAt,
            createdAt: createdAt ?? uploadedAt
        )
    }
}

extension AdminSriSettingsResponseDTO {
    func toDomain() -> AdminSriSettings {
        AdminSriSettings(
            organizationId: organizationId,
            environment: environment ?? "test",
            emissionType: emissionType ?? "normal",
            authorizationMode: authorizationMode ?? "offline",
            establishmentCode: establishmentCode,
            emissionPointCode: emissionPointCode,
            productionEnabled: productionEnabled ?? false,
            productionRequestedAt: productionRequestedAt,
            productionEnabledAt: productionEnabledAt,
            lastReadinessStatus: lastReadinessStatus,
            updatedAt: updatedAt
        )
    }
}

extension AdminSriReadinessResponseDTO {
    func toDomain() -> AdminSriReadiness {
        AdminSriReadiness(
            status: status ?? "unknown",
            score: score ?? 0,
            checkedAt: checkedAt ?? "",
            items: (items ?? []).enumerated().map { $0.element.toDomain(fallbackIndex: $0.offset) },
            blockers: blockers ?? [],
            warnings: warnings ?? []
        )
    }
}

extension AdminSriReadinessItemResponseDTO {
    func toDomain(fallbackIndex: Int = 0) -> AdminSriReadinessItem {
        AdminSriReadinessItem(
            id: id ?? code ?? "readiness_\(fallbackIndex)",
            code: code ?? "unknown",
            title: title ?? "Validación",
            description: description ?? "",
            status: status ?? "unknown",
            required: required ?? true,
            actionLabel: actionLabel
        )
    }
}

extension AdminSriHomologationRunResponseDTO {
    func toDomain() -> AdminSriHomologationRun {
        AdminSriHomologationRun(
            id: id,
            status: status ?? "unknown",
            environment: environment ?? "test",
            startedAt: startedAt,
            finishedAt: finishedAt,
            invoiceAccessKey: invoiceAccessKey,
            authorizationNumber: authorizationNumber,
            errorMessage: errorMessage,
            checklist: (checklist ?? []).enumerated().map { $0.element.toDomain(fallbackIndex: $0.offset) }
        )
    }
}

extension UpdateAdminTaxSettingsInput {
    func toDTO() -> UpdateAdminTaxSettingsRequestDTO {
        UpdateAdminTaxSettingsRequestDTO(
            regimeCode: regimeCode,
            defaultTaxProfileId: defaultTaxProfileId,
            obligatedToKeepAccounting: obligatedToKeepAccounting,
            specialTaxpayerNumber: specialTaxpayerNumber,
            clearSpecialTaxpayerNumber: clearSpecialTaxpayerNumber,
            rimpeLegend: rimpeLegend,
            withholdingAgentResolution: withholdingAgentResolution,
            clearWithholdingAgentResolution: clearWithholdingAgentResolution,
            reason: reason
        )
    }
}

extension UploadAdminElectronicSignatureInput {
    func toDTO() -> UploadAdminElectronicSignatureRequestDTO {
        UploadAdminElectronicSignatureRequestDTO(alias: alias, fileName: fileName, fileBase64: fileBase64, password: password, reason: reason)
    }
}

extension UpdateAdminSriSettingsInput {
    func toDTO() -> UpdateAdminSriSettingsRequestDTO {
        UpdateAdminSriSettingsRequestDTO(environment: environment, emissionType: emissionType, authorizationMode: authorizationMode, establishmentCode: establishmentCode, emissionPointCode: emissionPointCode, reason: reason)
    }
}
