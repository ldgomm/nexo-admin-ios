//
//  AdminTaxSriModels.swift
//  Nexo Admin
//
//  Created by José Ruiz on 2/6/26.
//

import Foundation

struct AdminTaxSettings: Equatable, Sendable {
    let organizationId: String
    let regimeCode: String
    let regimeName: String
    let defaultTaxProfileId: String?
    let defaultCurrency: String
    let obligatedToKeepAccounting: Bool
    let specialTaxpayerNumber: String?
    let rimpeLegend: String?
    let withholdingAgentResolution: String?
    let updatedAt: String?
    let version: Int
}

struct AdminTaxProfile: Identifiable, Equatable, Sendable {
    let id: String
    let code: String
    let name: String
    let description: String
    let status: String
    let taxName: String
    let taxKind: String
    let treatment: String
    let rate: Decimal
    let sriTaxCode: String
    let sriRateCode: String
    let legalBasis: String?
    let effectiveFrom: String?
    let effectiveTo: String?
    let editable: Bool
    let source: String?
    let requiresTourismEligibility: Bool
    let requiresConstructionMaterialAuxiliaryCode: Bool
    let requiresActiveWindow: Bool
    let eligibilityWindowCode: String?

    var displayRate: String {
        "\(NSDecimalNumber(decimal: rate).stringValue)%"
    }

    var displaySriCodes: String {
        let taxCode = sriTaxCode.trimmingCharacters(in: .whitespacesAndNewlines)
        let rateCode = sriRateCode.trimmingCharacters(in: .whitespacesAndNewlines)

        if taxCode.isEmpty && rateCode.isEmpty {
            return "Sin códigos SRI"
        }
        if taxCode.isEmpty {
            return "SRI —/\(rateCode)"
        }
        if rateCode.isEmpty {
            return "SRI \(taxCode)/—"
        }
        return "SRI \(taxCode)/\(rateCode)"
    }

    var normalizedTreatment: String {
        treatment.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    }

    var normalizedCode: String {
        code.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    var isTourismReducedIva: Bool {
        normalizedTreatment == "IVA_REDUCED_TOURISM" || normalizedCode.contains("tourism")
    }

    var isConstructionReducedIva: Bool {
        normalizedTreatment == "IVA_REDUCED_CONSTRUCTION_MATERIALS" || normalizedCode.contains("construction")
    }

    var isInternalOnly: Bool {
        normalizedTreatment == "NO_TAX_INTERNAL" || normalizedCode.contains("no_tax_internal")
    }

    var isElectronicallyBillable: Bool {
        !isInternalOnly && !sriTaxCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var requiresEligibilityNotice: Bool {
        requiresTourismEligibility || requiresConstructionMaterialAuxiliaryCode || requiresActiveWindow
    }

    var eligibilitySummary: String? {
        var items: [String] = []
        if requiresTourismEligibility {
            items.append("requiere elegibilidad turística")
        }
        if requiresConstructionMaterialAuxiliaryCode {
            items.append("requiere código auxiliar de material")
        }
        if requiresActiveWindow {
            items.append("requiere ventana/decreto vigente")
        }
        if let eligibilityWindowCode, !eligibilityWindowCode.isEmpty {
            items.append("ventana: \(eligibilityWindowCode)")
        }
        return items.isEmpty ? nil : items.joined(separator: " • ")
    }
}

struct AdminElectronicSignature: Identifiable, Equatable, Sendable {
    let id: String
    let organizationId: String
    let alias: String
    let subject: String
    let issuer: String
    let serialNumber: String
    let validFrom: String?
    let validTo: String?
    let status: String
    let effectiveStatus: String
    let usable: Bool
    let expiresInDays: Int?
    let expiresSoon: Bool
    let uploadedBy: String?
    let uploadedAt: String?
    let lastUsedAt: String?
    let lastValidatedAt: String?
    let createdAt: String?

    var normalizedStatus: String {
        status.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    }

    var normalizedEffectiveStatus: String {
        effectiveStatus.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    }

    var lifecycleStatus: String {
        let values = [normalizedEffectiveStatus, normalizedStatus]

        if values.contains("ACTIVE") || values.contains("ACTIVA") { return "ACTIVE" }
        if values.contains("REVOKED") || values.contains("REVOCADA") { return "REVOKED" }
        if values.contains("EXPIRED") || values.contains("VENCIDA") { return "EXPIRED" }
        if values.contains("INVALID") || values.contains("INVALIDA") || values.contains("INVÁLIDA") { return "INVALID" }
        if values.contains("FAILED") || values.contains("ERROR") || values.contains("FALLIDA") { return "FAILED" }
        if values.contains("VALID") || values.contains("VALIDA") || values.contains("VÁLIDA") { return "VALID" }
        if values.contains("UPLOADED") || values.contains("LOADED") || values.contains("CARGADA") { return "UPLOADED" }
        if values.contains("PENDING") || values.contains("PENDIENTE") { return "PENDING" }
        if values.contains("INACTIVE") || values.contains("INACTIVA") { return "INACTIVE" }

        if usable { return "ACTIVE" }
        return normalizedEffectiveStatus.isEmpty ? "UNKNOWN" : normalizedEffectiveStatus
    }

    var isActive: Bool {
        lifecycleStatus == "ACTIVE" || usable
    }

    var isValid: Bool {
        lifecycleStatus == "VALID" || isActive
    }

    var isUploaded: Bool {
        lifecycleStatus == "UPLOADED" || lifecycleStatus == "PENDING" || lifecycleStatus == "INACTIVE"
    }

    var isRevoked: Bool { lifecycleStatus == "REVOKED" }
    var isExpired: Bool { lifecycleStatus == "EXPIRED" }
    var isInvalid: Bool { lifecycleStatus == "INVALID" }
    var isFailed: Bool { lifecycleStatus == "FAILED" }

    var requiresNewUpload: Bool {
        isRevoked || isExpired || isInvalid || isFailed
    }

    var canValidate: Bool {
        !requiresNewUpload && !isActive && (isUploaded || lifecycleStatus == "UNKNOWN")
    }

    var canActivate: Bool {
        isValid && !isActive && !requiresNewUpload
    }

    var canRevoke: Bool {
        !isRevoked && !isExpired && (isActive || isValid || isUploaded)
    }

    var displayStatusTitle: String {
        switch lifecycleStatus {
        case "ACTIVE": return "Activa"
        case "VALID": return "Válida"
        case "UPLOADED": return "Cargada"
        case "PENDING": return "Pendiente"
        case "INACTIVE": return "Inactiva"
        case "REVOKED": return "Revocada"
        case "EXPIRED": return "Vencida"
        case "INVALID": return "Inválida"
        case "FAILED": return "Fallida"
        default: return "Sin validar"
        }
    }

    var displaySubject: String {
        let cleanSubject = subject.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleanSubject.isEmpty || cleanSubject == "Sin sujeto" {
            return "Sin detalle del certificado"
        }
        return cleanSubject
    }

    var displayExpiration: String {
        guard let validTo, !validTo.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return "Sin vencimiento informado"
        }
        return validTo
    }

    var humanStatusMessage: String {
        switch lifecycleStatus {
        case "ACTIVE":
            return "Esta firma puede usarse para emitir comprobantes electrónicos, si el resto de la configuración está lista."
        case "VALID":
            return "Esta firma fue validada. Puedes activarla para usarla como firma principal del negocio."
        case "UPLOADED", "PENDING", "INACTIVE":
            return "La firma está cargada. Valídala antes de activarla para emisión electrónica."
        case "REVOKED":
            return "Esta firma fue revocada y ya no puede usarse. Carga una nueva firma electrónica."
        case "EXPIRED":
            return "Esta firma está vencida y ya no puede usarse. Carga una firma vigente."
        case "INVALID":
            return "Esta firma no pasó la validación. Revisa el archivo, la contraseña o carga una nueva."
        case "FAILED":
            return "No se pudo procesar esta firma. Carga nuevamente el archivo correcto."
        default:
            return "No hay suficiente información para usar esta firma. Valídala o carga una nueva."
        }
    }

    var blockedActionHint: String? {
        if requiresNewUpload {
            return "Acción recomendada: cargar nueva firma."
        }
        if isActive {
            return "Acciones disponibles: ver detalle, cargar nueva firma o revocar si corresponde."
        }
        if isValid {
            return "Acción recomendada: activar esta firma."
        }
        if canValidate {
            return "Acción recomendada: validar la firma."
        }
        return nil
    }
}

struct AdminSriSettings: Equatable, Sendable {
    let organizationId: String
    let environment: String
    let emissionType: String
    let authorizationMode: String
    let establishmentCode: String?
    let emissionPointCode: String?
    let productionEnabled: Bool
    let productionRequestedAt: String?
    let productionEnabledAt: String?
    let lastReadinessStatus: String?
    let updatedAt: String?
}

struct AdminSriReadiness: Equatable, Sendable {
    let status: String
    let score: Int
    let checkedAt: String
    let items: [AdminSriReadinessItem]
    let blockers: [String]
    let warnings: [String]

    var ready: Bool { status.lowercased() == "ready" || status.lowercased() == "ok" }
}

struct AdminSriReadinessItem: Identifiable, Equatable, Sendable {
    let id: String
    let code: String
    let title: String
    let description: String
    let status: String
    let required: Bool
    let actionLabel: String?
}

struct AdminSriHomologationRun: Identifiable, Equatable, Sendable {
    let id: String
    let status: String
    let environment: String
    let startedAt: String?
    let finishedAt: String?
    let invoiceAccessKey: String?
    let authorizationNumber: String?
    let errorMessage: String?
    let checklist: [AdminSriReadinessItem]
}

struct AdminTaxSriSummary: Equatable, Sendable {
    let taxSettings: AdminTaxSettings
    let taxProfiles: [AdminTaxProfile]
    let signatures: [AdminElectronicSignature]
    let sriSettings: AdminSriSettings
    let readiness: AdminSriReadiness
    let homologationRuns: [AdminSriHomologationRun]
}

struct UpdateAdminTaxSettingsInput: Equatable, Sendable {
    var regimeCode: String?
    var defaultTaxProfileId: String?
    var obligatedToKeepAccounting: Bool?
    var specialTaxpayerNumber: String?
    var clearSpecialTaxpayerNumber: Bool = false
    var rimpeLegend: String?
    var withholdingAgentResolution: String?
    var clearWithholdingAgentResolution: Bool = false
    var reason: String
}

struct UploadAdminElectronicSignatureInput: Equatable, Sendable {
    var alias: String
    var fileName: String
    var fileBase64: String
    var password: String
    var reason: String
}

struct AdminSignatureActionInput: Equatable, Sendable {
    var signatureId: String
    var reason: String
}

struct UpdateAdminSriSettingsInput: Equatable, Sendable {
    var environment: String?
    var emissionType: String?
    var authorizationMode: String?
    var establishmentCode: String?
    var emissionPointCode: String?
    var reason: String
}

struct RequestProductionEnableInput: Equatable, Sendable {
    var confirmationText: String
    var reason: String
}

extension AdminSriHomologationRun {
    var displayTitle: String {
        "Prueba de emisión"
    }

    var displayStatus: String {
        switch status.trimmingCharacters(in: .whitespacesAndNewlines).uppercased() {
        case "PASSED", "SUCCESS", "AUTHORIZED", "APPROVED":
            return "Correcta"
        case "RUNNING", "PROCESSING", "PENDING":
            return "En proceso"
        case "FAILED", "ERROR":
            return "Falló"
        case "SKIPPED":
            return "Omitida"
        default:
            return status.isEmpty ? "Sin estado" : status
        }
    }

    var humanErrorMessage: String? {
        guard let errorMessage, !errorMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        let normalized = errorMessage.lowercased()

        if normalized.contains("at least one homologation scenario")
            || normalized.contains("homologation scenario")
            || normalized.contains("no hay pruebas de emisión configuradas") {
            return "No hay pruebas de emisión configuradas en backend. Esto es una configuración técnica pendiente, no un problema de tu firma ni del SRI."
        }

        if normalized.contains("payment does not belong to this sale") {
            return "La prueba automática está usando un pago que no pertenece a la venta de prueba. Hay que corregir el escenario interno."
        }

        if normalized.contains("expected final status authorized")
            || normalized.contains("got not_authorized")
            || normalized.contains("got returned_by_sri") {
            return "La prueba llegó al flujo de autorización, pero el comprobante no terminó autorizado. Revisa el detalle técnico para ver la respuesta exacta del SRI o del escenario."
        }

        if normalized.contains("processing authorization status") {
            return "El escenario de reintento esperaba un estado PROCESSING, pero recibió otra respuesta. Hay que ajustar esa prueba automática."
        }

        return errorMessage
    }
}

