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
    let documentId: String?
    let saleId: String?
    let finalDocumentStatus: String?
    let artifactTypes: [String]
    let checklist: [AdminSriReadinessItem]

    init(
        id: String,
        status: String,
        environment: String,
        startedAt: String?,
        finishedAt: String?,
        invoiceAccessKey: String?,
        authorizationNumber: String?,
        errorMessage: String?,
        documentId: String? = nil,
        saleId: String? = nil,
        finalDocumentStatus: String? = nil,
        artifactTypes: [String] = [],
        checklist: [AdminSriReadinessItem]
    ) {
        self.id = id
        self.status = status
        self.environment = environment
        self.startedAt = startedAt
        self.finishedAt = finishedAt
        self.invoiceAccessKey = invoiceAccessKey
        self.authorizationNumber = authorizationNumber
        self.errorMessage = errorMessage
        self.documentId = documentId
        self.saleId = saleId
        self.finalDocumentStatus = finalDocumentStatus
        self.artifactTypes = artifactTypes
        self.checklist = checklist
    }
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

extension AdminSriReadinessItem {
    var normalizedStatus: String {
        status.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    }

    var humanStatus: String {
        switch normalizedStatus {
        case "PASSED", "AUTHORIZED", "OK", "READY", "SUCCESS":
            return "Correcto"
        case "FAILED", "ERROR", "INVALID", "BLOCKED":
            return "Falló"
        case "REJECTED", "RETURNED", "RETURNED_BY_SRI", "NOT_AUTHORIZED":
            return "Rechazado"
        case "RUNNING", "PROCESSING", "PENDING", "IN_PROGRESS":
            return "En proceso"
        case "SKIPPED", "OMITTED":
            return "No ejecutado"
        case "WARNING", "WARN":
            return "Advertencia"
        default:
            return status.isEmpty ? "Sin estado" : status
        }
    }

    var isPassedForHomologation: Bool {
        ["PASSED", "AUTHORIZED", "OK", "READY", "SUCCESS"].contains(normalizedStatus)
    }

    var isFailedForHomologation: Bool {
        ["FAILED", "ERROR", "INVALID", "BLOCKED", "REJECTED", "RETURNED", "RETURNED_BY_SRI", "NOT_AUTHORIZED"].contains(normalizedStatus)
    }

    var isPendingForHomologation: Bool {
        ["RUNNING", "PROCESSING", "PENDING", "IN_PROGRESS"].contains(normalizedStatus)
    }

    var isSkippedForHomologation: Bool {
        ["SKIPPED", "OMITTED"].contains(normalizedStatus)
    }

    var homologationDisplayTitle: String {
        let value = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if value == "FINAL_CONSUMER" || code == "FINAL_CONSUMER" {
            return "Factura consumidor final"
        }
        return value.isEmpty ? code : value
    }

    var homologationDisplayDescription: String {
        let value = description.trimmingCharacters(in: .whitespacesAndNewlines)
        if value.uppercased() == "AUTHORIZED" {
            return "Comprobante técnico autorizado en ambiente TEST."
        }
        if isPendingForHomologation {
            return value.isEmpty ? "La validación todavía está en proceso." : value
        }
        if isSkippedForHomologation {
            return value.isEmpty ? "Este escenario no se ejecutó en esta corrida." : value
        }
        if isFailedForHomologation {
            return value.isEmpty ? "La validación no terminó correctamente." : value
        }
        return value.isEmpty ? "Sin descripción técnica." : value
    }
}

extension AdminSriHomologationRun {
    var normalizedStatus: String {
        status.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    }

    var displayTitle: String {
        "Prueba de emisión SRI TEST"
    }

    var displayStatus: String {
        switch normalizedStatus {
        case "PASSED", "SUCCESS", "AUTHORIZED", "APPROVED":
            return "Correcta"
        case "RUNNING", "PROCESSING", "PENDING", "IN_PROGRESS":
            return "En proceso"
        case "REJECTED", "RETURNED", "RETURNED_BY_SRI", "NOT_AUTHORIZED":
            return "Rechazada"
        case "FAILED", "ERROR", "INVALID", "BLOCKED":
            return "Falló"
        case "SKIPPED", "OMITTED":
            return "Omitida"
        default:
            return status.isEmpty ? "Sin estado" : status
        }
    }

    var isPassed: Bool {
        ["PASSED", "SUCCESS", "AUTHORIZED", "APPROVED"].contains(normalizedStatus)
    }

    var isRunning: Bool {
        ["RUNNING", "PROCESSING", "PENDING", "IN_PROGRESS"].contains(normalizedStatus)
    }

    var isRejected: Bool {
        ["REJECTED", "RETURNED", "RETURNED_BY_SRI", "NOT_AUTHORIZED"].contains(normalizedStatus)
    }

    var isFailed: Bool {
        ["FAILED", "ERROR", "INVALID", "BLOCKED"].contains(normalizedStatus) || isRejected
    }

    var displayEnvironment: String {
        switch environment.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "test", "testing", "pruebas", "1":
            return "TEST"
        case "production", "prod", "produccion", "producción", "2":
            return "PRODUCCIÓN"
        default:
            return environment.isEmpty ? "—" : environment.uppercased()
        }
    }

    var durationText: String {
        guard let startedAtDate = startedAt?.nexoSriISODate, let finishedAtDate = finishedAt?.nexoSriISODate else {
            return isRunning ? "En proceso" : "—"
        }

        let seconds = max(0, finishedAtDate.timeIntervalSince(startedAtDate))
        if seconds < 1 { return "< 1 s" }
        if seconds < 60 { return "\(Int(seconds.rounded())) s" }

        let minutes = Int(seconds) / 60
        let remainder = Int(seconds) % 60
        return "\(minutes) min \(remainder) s"
    }

    var displayStartedAt: String {
        startedAt?.nexoSriReadableDate ?? startedAt ?? "—"
    }

    var displayFinishedAt: String {
        if isRunning && finishedAt == nil { return "En proceso" }
        return finishedAt?.nexoSriReadableDate ?? finishedAt ?? "—"
    }

    var primaryAccessKey: String? {
        let value = invoiceAccessKey?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return value.isEmpty ? nil : value
    }

    var primaryAuthorizationNumber: String? {
        let value = authorizationNumber?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return value.isEmpty ? primaryAccessKey : value
    }

    var hasFiscalEvidence: Bool {
        primaryAccessKey != nil || primaryAuthorizationNumber != nil
    }

    var primaryDocumentId: String? {
        let value = documentId?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return value.isEmpty ? nil : value
    }

    var primarySaleId: String? {
        let value = saleId?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return value.isEmpty ? nil : value
    }

    var primaryFinalDocumentStatus: String? {
        let value = finalDocumentStatus?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return value.isEmpty ? nil : value
    }

    var hasDocumentEvidence: Bool {
        primaryDocumentId != nil || primarySaleId != nil || primaryFinalDocumentStatus != nil || !artifactTypes.isEmpty
    }

    var documentEvidenceStatusText: String {
        guard let status = primaryFinalDocumentStatus else { return "—" }
        switch status.uppercased() {
        case "AUTHORIZED", "DELIVERY_PENDING", "DELIVERED":
            return "Autorizado"
        case "AUTHORIZATION_PENDING", "RECEIVED", "PROCESSING":
            return "En proceso"
        case "RETURNED", "REJECTED", "NOT_AUTHORIZED", "FAILED", "ERROR":
            return "No autorizado"
        default:
            return status
        }
    }

    var artifactSummaryText: String {
        let normalized = artifactTypes
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard !normalized.isEmpty else { return "Sin artefactos reportados" }
        return normalized.sorted().joined(separator: ", ")
    }

    var rawErrorMessage: String? {
        let value = errorMessage?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return value.isEmpty ? nil : value
    }

    var humanErrorMessage: String? {
        guard let errorMessage = rawErrorMessage else { return nil }
        let normalized = errorMessage.lowercased()

        if normalized.contains("at least one homologation scenario")
            || normalized.contains("homologation scenario")
            || normalized.contains("no hay pruebas de emisión configuradas") {
            return "No hay pruebas de emisión configuradas en backend. Esto es una configuración técnica pendiente, no un problema de tu firma ni del SRI."
        }

        if normalized.contains("signature")
            || normalized.contains("firma")
            || normalized.contains("p12")
            || normalized.contains("pfx")
            || normalized.contains("certificate")
            || normalized.contains("certificado") {
            if normalized.contains("expired") || normalized.contains("vencid") {
                return "La firma electrónica parece vencida. Carga o activa una firma vigente antes de repetir la homologación."
            }
            if normalized.contains("password") || normalized.contains("contraseña") || normalized.contains("clave") {
                return "No se pudo usar la firma electrónica. Revisa que la contraseña cargada sea correcta y que el archivo .p12/.pfx corresponda al RUC del emisor."
            }
            return "La corrida falló al validar o usar la firma electrónica. Revisa archivo, contraseña, vigencia y estado activo de la firma."
        }

        if normalized.contains("sequence")
            || normalized.contains("secuencial")
            || normalized.contains("secuencia") {
            return "La corrida falló por configuración de secuencia. Revisa establecimiento, punto de emisión y secuencial disponible para facturas en ambiente TEST."
        }

        if normalized.contains("emission point")
            || normalized.contains("ptoemi")
            || normalized.contains("punto de emisión")
            || normalized.contains("estab")
            || normalized.contains("establecimiento") {
            return "La corrida falló por datos del establecimiento o punto de emisión. Revisa que estén configurados y coincidan con la configuración SRI del negocio."
        }

        if normalized.contains("xml")
            || normalized.contains("xsd")
            || normalized.contains("schema")
            || normalized.contains("estructura") {
            return "La corrida generó un XML que no pasó validación técnica. Revisa el detalle del error y el escenario que lo produjo antes de reintentar."
        }

        if normalized.contains("timeout")
            || normalized.contains("connection refused")
            || normalized.contains("network")
            || normalized.contains("socket")
            || normalized.contains("sri") && normalized.contains("no responde") {
            return "La corrida no pudo comunicarse correctamente con el servicio requerido. Verifica conectividad, endpoint SRI TEST y disponibilidad antes de reintentar."
        }

        if normalized.contains("payment does not belong to this sale") {
            return "La prueba automática está usando un pago que no pertenece a la venta de prueba. Hay que corregir el escenario interno."
        }

        if normalized.contains("expected final status authorized")
            || normalized.contains("got not_authorized")
            || normalized.contains("got returned_by_sri")
            || normalized.contains("not_authorized")
            || normalized.contains("returned_by_sri") {
            return "La prueba llegó al flujo de autorización, pero el comprobante no terminó autorizado. Revisa la respuesta exacta del SRI o del escenario antes de repetir."
        }

        if normalized.contains("processing authorization status") {
            return "El escenario de reintento esperaba un estado PROCESSING, pero recibió otra respuesta. Hay que ajustar esa prueba automática."
        }

        return errorMessage
    }

    var suggestedRecoveryHint: String? {
        guard isFailed || rawErrorMessage != nil else { return nil }
        let normalized = (rawErrorMessage ?? status).lowercased()

        if normalized.contains("signature") || normalized.contains("firma") || normalized.contains("p12") || normalized.contains("pfx") || normalized.contains("certificado") {
            return "Revisa Firma electrónica: archivo, contraseña, vigencia, estado activa y que pertenezca al RUC del emisor."
        }
        if normalized.contains("sequence") || normalized.contains("secuencial") || normalized.contains("secuencia") {
            return "Revisa Secuencias: serie 001-001, siguiente número y tipo de documento factura en TEST."
        }
        if normalized.contains("emission point") || normalized.contains("ptoemi") || normalized.contains("punto de emisión") || normalized.contains("establecimiento") {
            return "Revisa Configuración SRI: establecimiento, punto de emisión, ambiente TEST y modo de autorización."
        }
        if normalized.contains("xml") || normalized.contains("xsd") || normalized.contains("schema") {
            return "Revisa XML/XSD: datos del emisor, cliente consumidor final, impuestos, totales y versión de factura usada por backend."
        }
        if normalized.contains("timeout") || normalized.contains("connection refused") || normalized.contains("network") || normalized.contains("socket") || normalized.contains("sri") {
            return "Revisa conectividad: backend local/staging, endpoint SRI TEST, DNS/TLS y logs del transporte."
        }
        if isRejected {
            return "Revisa respuesta de autorización/recepción y el XML generado. No basta con reintentar si el rechazo es de datos."
        }
        return "Copia el resumen de soporte y revisa readiness SRI, firma, secuencias y respuesta técnica del backend."
    }

    var shouldWarnAgainstBlindRetry: Bool {
        guard isFailed else { return false }
        let normalized = (rawErrorMessage ?? status).lowercased()
        return normalized.contains("signature")
            || normalized.contains("firma")
            || normalized.contains("sequence")
            || normalized.contains("secuencial")
            || normalized.contains("xml")
            || normalized.contains("xsd")
            || normalized.contains("rejected")
            || normalized.contains("not_authorized")
            || normalized.contains("returned_by_sri")
            || normalized.contains("config")
    }
}

private extension String {
    var nexoSriISODate: Date? {
        let value = trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return nil }

        let isoWithFractionalSeconds = ISO8601DateFormatter()
        isoWithFractionalSeconds.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = isoWithFractionalSeconds.date(from: value) {
            return date
        }

        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime]
        if let date = iso.date(from: value) {
            return date
        }

        let backendFormats = [
            "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX",
            "yyyy-MM-dd'T'HH:mm:ssXXXXX",
            "yyyy-MM-dd HH:mm:ss",
            "yyyy-MM-dd"
        ]

        for format in backendFormats {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            formatter.dateFormat = format
            if let date = formatter.date(from: value) {
                return date
            }
        }

        return nil
    }

    var nexoSriReadableDate: String? {
        guard let date = nexoSriISODate else { return nil }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_EC")
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

