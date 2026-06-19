//
//  AdminElectronicDocumentModels.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import Foundation

struct AdminElectronicDocumentListFilter: Equatable, Sendable {
    var query: String = ""
    var status: AdminElectronicDocumentStatusFilter = .all
    var sriStatus: AdminSriStatusFilter = .all
    var documentType: String = ""
    var customer: String = ""
    var number: String = ""
    var fromDate: Date?
    var toDate: Date?
    var limit: Int = 50

    var hasActiveFilters: Bool {
        !query.trimmed.isEmpty ||
        status != .all ||
        sriStatus != .all ||
        !documentType.trimmed.isEmpty ||
        !customer.trimmed.isEmpty ||
        !number.trimmed.isEmpty ||
        fromDate != nil ||
        toDate != nil
    }
}

enum AdminElectronicDocumentStatusFilter: String, CaseIterable, Identifiable, Sendable {
    case all
    case draft
    case issued
    case signed
    case sent
    case authorized
    case returned
    case rejected
    case cancelled

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: "Todos"
        case .draft: "Borrador"
        case .issued: "Emitidos"
        case .signed: "Firmados"
        case .sent: "Enviados"
        case .authorized: "Autorizados"
        case .returned: "Devueltos"
        case .rejected: "Rechazados"
        case .cancelled: "Anulados"
        }
    }

    var apiValue: String? { self == .all ? nil : rawValue }
}

enum AdminSriStatusFilter: String, CaseIterable, Identifiable, Sendable {
    case all
    case pending
    case received
    case processing
    case authorized
    case returned
    case rejected
    case unavailable

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: "Todos SRI"
        case .pending: "Pendiente"
        case .received: "Recibido"
        case .processing: "Procesando"
        case .authorized: "Autorizado"
        case .returned: "Devuelto"
        case .rejected: "Rechazado"
        case .unavailable: "Sin conexión"
        }
    }

    var apiValue: String? { self == .all ? nil : rawValue }
}

struct AdminElectronicDocumentList: Equatable, Sendable {
    let documents: [AdminElectronicDocumentSummary]
    let total: Int
    let hasMore: Bool
}

enum AdminElectronicDocumentAction: Equatable, Hashable, Sendable {
    case viewDetail
    case viewTimeline
    case downloadRide
    case downloadXml
    case retryReception
    case retryAuthorization
    case resendEmail
    case regenerateRide
    case unknown(String)

    init(rawValue: String) {
        switch rawValue.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "view_detail", "viewdetail": self = .viewDetail
        case "view_timeline", "viewtimeline": self = .viewTimeline
        case "download_ride", "downloadride": self = .downloadRide
        case "download_xml", "downloadxml": self = .downloadXml
        case "retry_reception", "retryreception": self = .retryReception
        case "retry_authorization", "retryauthorization": self = .retryAuthorization
        case "resend_email", "resendemail": self = .resendEmail
        case "regenerate_ride", "regenerateride": self = .regenerateRide
        case let value where value.isEmpty: self = .unknown("unknown")
        case let value: self = .unknown(value)
        }
    }

    var publicRawValue: String {
        switch self {
        case .viewDetail: "view_detail"
        case .viewTimeline: "view_timeline"
        case .downloadRide: "download_ride"
        case .downloadXml: "download_xml"
        case .retryReception: "retry_reception"
        case .retryAuthorization: "retry_authorization"
        case .resendEmail: "resend_email"
        case .regenerateRide: "regenerate_ride"
        case .unknown(let value): value
        }
    }

    var title: String {
        switch self {
        case .viewDetail: "Ver detalle"
        case .viewTimeline: "Ver timeline"
        case .downloadRide: "Ver RIDE"
        case .downloadXml: "Ver XML"
        case .retryReception: "Reintentar recepción"
        case .retryAuthorization: "Reintentar autorización"
        case .resendEmail: "Reenviar email"
        case .regenerateRide: "Regenerar RIDE"
        case .unknown: "Acción no disponible"
        }
    }
}

struct AdminElectronicDocumentRetrySummary: Equatable, Sendable {
    let canRetryReception: Bool
    let canRetryAuthorization: Bool
    let canResendEmail: Bool
    let canRegenerateRide: Bool
    let receptionRetryCount: Int
    let authorizationRetryCount: Int
    let emailAttempts: Int
    let rideRegenerationCount: Int
    let nextRetryAt: String?
    let lastRetryAt: String?
    let message: String?

    var safeMessage: String? {
        AdminElectronicDocumentTextSanitizer.sanitizedMessage(message)
    }

    static let empty = AdminElectronicDocumentRetrySummary(
        canRetryReception: false,
        canRetryAuthorization: false,
        canResendEmail: false,
        canRegenerateRide: false,
        receptionRetryCount: 0,
        authorizationRetryCount: 0,
        emailAttempts: 0,
        rideRegenerationCount: 0,
        nextRetryAt: nil,
        lastRetryAt: nil,
        message: nil
    )
}

struct AdminElectronicDocumentSummary: Identifiable, Equatable, Sendable {
    let id: String
    let organizationId: String
    let saleId: String?
    let documentType: String
    let displayNumber: String
    let accessKey: String?
    let authorizationNumber: String?
    let customerName: String
    let customerIdentification: String?
    let customerEmail: String?
    let total: Decimal
    let currency: String
    let status: String
    let sriStatus: String
    let environment: String
    let issueDate: String
    let authorizedAt: String?
    let updatedAt: String
    let hasRide: Bool
    let hasXml: Bool
    let emailSentAt: String?
    let lastErrorMessage: String?
    let availableActions: [AdminElectronicDocumentAction]
    let retrySummary: AdminElectronicDocumentRetrySummary

    func allows(_ action: AdminElectronicDocumentAction) -> Bool {
        availableActions.contains(action)
    }

    var statusTitle: String { AdminElectronicDocumentText.statusTitle(status) }
    var sriStatusTitle: String { AdminElectronicDocumentText.sriStatusTitle(sriStatus) }
    var environmentTitle: String { AdminElectronicDocumentText.environmentTitle(environment) }
    var moneyText: String { MoneyFormatter.format(total, currency: currency) }
    var isAuthorized: Bool { sriStatus.lowercased() == "authorized" || status.lowercased() == "authorized" }
    var canRetry: Bool { ["returned", "rejected", "failed", "error"].contains(sriStatus.lowercased()) || ["returned", "rejected", "failed", "error"].contains(status.lowercased()) }
}

struct AdminElectronicDocumentDetail: Identifiable, Equatable, Sendable {
    let id: String
    let summary: AdminElectronicDocumentSummary
    let branchName: String?
    let emissionPointName: String?
    let legalName: String?
    let commercialName: String?
    let taxId: String?
    let totals: AdminElectronicDocumentTotals
    let lines: [AdminElectronicDocumentLine]
    let sri: AdminElectronicDocumentSriState
    let artifacts: AdminElectronicDocumentArtifacts
    let email: AdminElectronicDocumentEmailState
    let timeline: [AdminElectronicDocumentTimelineEvent]
    let errors: [AdminSriDocumentError]
    let warnings: [String]
    let availableActions: [AdminElectronicDocumentAction]
    let retrySummary: AdminElectronicDocumentRetrySummary

    func allows(_ action: AdminElectronicDocumentAction) -> Bool {
        availableActions.contains(action)
    }
}

struct AdminElectronicDocumentTotals: Equatable, Sendable {
    let subtotalWithoutTaxes: Decimal
    let subtotalTaxed: Decimal
    let subtotalZeroRate: Decimal
    let subtotalExempt: Decimal
    let subtotalNotSubject: Decimal
    let discountTotal: Decimal
    let taxTotal: Decimal
    let tipTotal: Decimal
    let grandTotal: Decimal
    let currency: String
}

struct AdminElectronicDocumentLine: Identifiable, Equatable, Sendable {
    let id: String
    let code: String?
    let description: String
    let quantity: Decimal
    let unitPrice: Decimal
    let discount: Decimal
    let subtotal: Decimal
    let taxProfileCode: String?
    let taxRate: Decimal?
    let taxValue: Decimal

    var quantityText: String { DecimalFormatter.format(quantity, fractionDigits: 2) }
}

struct AdminElectronicDocumentSriState: Equatable, Sendable {
    let environment: String
    let receptionStatus: String?
    let authorizationStatus: String?
    let authorizationNumber: String?
    let accessKey: String?
    let receivedAt: String?
    let authorizedAt: String?
    let lastCheckedAt: String?
    let retryCount: Int
    let nextRetryAt: String?

    var environmentTitle: String { AdminElectronicDocumentText.environmentTitle(environment) }
}

struct AdminElectronicDocumentArtifacts: Equatable, Sendable {
    let ride: AdminDocumentArtifact?
    let signedXml: AdminDocumentArtifact?
    let authorizedXml: AdminDocumentArtifact?
}

struct AdminDocumentArtifact: Identifiable, Equatable, Sendable {
    let id: String
    let kind: String
    let fileName: String
    let contentType: String
    let sizeBytes: Int?
    let downloadURL: URL?
    let expiresAt: String?

    var sizeText: String {
        guard let sizeBytes else { return "Tamaño no disponible" }
        return ByteCountFormatter.string(fromByteCount: Int64(sizeBytes), countStyle: .file)
    }

    var safeFileName: String {
        AdminElectronicDocumentTextSanitizer.sanitizedFileName(fileName, fallback: displayName)
    }

    var displayName: String {
        switch kind.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "ride", "ridepdf", "ride_pdf":
            return "RIDE PDF"
        case "authorizedxml", "authorized_xml", "xml":
            return "XML autorizado"
        case "signedxml", "signed_xml":
            return "XML firmado"
        case "generatedxml", "generated_xml", "unsignedxml", "unsigned_xml":
            return "XML generado"
        default:
            return "Archivo"
        }
    }
}

struct AdminElectronicDocumentEmailState: Equatable, Sendable {
    let recipient: String?
    let status: String
    let sentAt: String?
    let lastError: String?
    let attempts: Int

    var statusTitle: String {
        switch status.lowercased() {
        case "sent": "Enviado"
        case "failed", "error": "Fallido"
        case "pending": "Pendiente"
        case "disabled": "No configurado"
        default: status.isEmpty ? "Sin estado" : status.capitalized
        }
    }
}

struct AdminSriDocumentError: Identifiable, Equatable, Sendable {
    let id: String
    let code: String
    let type: String
    let rawMessage: String
    let userMessage: String
    let technicalMessage: String?
    let field: String?
    let occurredAt: String?
    let retryable: Bool
    let severity: AdminSriErrorSeverity

    var safeCode: String {
        AdminElectronicDocumentTextSanitizer.sanitizedMessage(code) ?? "SIN_CODIGO"
    }

    var safeUserMessage: String {
        AdminElectronicDocumentTextSanitizer.sanitizedMessage(userMessage)
            ?? AdminElectronicDocumentTextSanitizer.sanitizedMessage(rawMessage)
            ?? "Error SRI"
    }

    var safeRawMessage: String? {
        AdminElectronicDocumentTextSanitizer.sanitizedMessage(rawMessage)
    }

    var safeTechnicalMessage: String? {
        AdminElectronicDocumentTextSanitizer.sanitizedMessage(technicalMessage)
    }

    var safeField: String? {
        AdminElectronicDocumentTextSanitizer.sanitizedMessage(field)
    }
}

enum AdminSriErrorSeverity: String, CaseIterable, Sendable {
    case info
    case warning
    case error
    case critical

    var title: String {
        switch self {
        case .info: "Info"
        case .warning: "Advertencia"
        case .error: "Error"
        case .critical: "Crítico"
        }
    }
}

struct AdminElectronicDocumentTimelineEvent: Identifiable, Equatable, Sendable {
    let id: String
    let type: String
    let title: String
    let message: String
    let actor: String?
    let createdAt: String
    let severity: AdminSriErrorSeverity

    var safeTitle: String {
        AdminElectronicDocumentTextSanitizer.sanitizedMessage(title) ?? "Evento documental"
    }

    var safeMessage: String {
        AdminElectronicDocumentTextSanitizer.sanitizedMessage(message) ?? "Evento documental registrado."
    }

    var safeActor: String? {
        AdminElectronicDocumentTextSanitizer.sanitizedMessage(actor)
    }
}

struct AdminDocumentRetryResult: Equatable, Sendable {
    let documentId: String
    let accepted: Bool
    let status: String
    let message: String
    let requestedAt: String
}

struct AdminDocumentEmailResendResult: Equatable, Sendable {
    let documentId: String
    let accepted: Bool
    let recipient: String?
    let message: String
    let requestedAt: String
}

struct AdminDocumentRideRegenerationResult: Equatable, Sendable {
    let documentId: String
    let accepted: Bool
    let status: String
    let message: String
    let requestedAt: String
    let artifact: AdminDocumentArtifact?
}

enum AdminElectronicDocumentTextSanitizer {
    static func sanitizedMessage(_ value: String?) -> String? {
        guard let value else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let lowercased = trimmed.lowercased()
        let forbiddenFragments = [
            "electronic-invoicing/",
            "ride_pdf/",
            "signed_xml",
            "authorized_xml",
            "generated_xml",
            "sri_request",
            "sri_response",
            "bucket",
            "objectkey",
            "storagekey",
            "/var/",
            "/tmp/",
            ".p12",
            ".pfx",
            "secret",
            "password",
            "privatekey",
            "token"
        ]

        guard forbiddenFragments.allSatisfy({ !lowercased.contains($0) }) else {
            return nil
        }

        return trimmed
    }

    static func sanitizedFileName(_ fileName: String?, fallback: String = "Archivo") -> String {
        guard let fileName else { return fallback }
        let lastPathComponent = fileName
            .replacingOccurrences(of: "\\", with: "/")
            .split(separator: "/")
            .last
            .map(String.init) ?? fileName

        return sanitizedMessage(lastPathComponent) ?? fallback
    }
}

enum AdminElectronicDocumentText {
    static func statusTitle(_ status: String) -> String {
        switch status.lowercased() {
        case "draft": "Borrador"
        case "issued": "Emitido"
        case "signed": "Firmado"
        case "sent": "Enviado"
        case "authorized": "Autorizado"
        case "not_authorized", "notauthorized", "no_autorizada": "No autorizada"
        case "returned": "Devuelto"
        case "rejected": "Rechazado"
        case "cancelled", "canceled": "Anulado"
        default: status.isEmpty ? "Sin estado" : status.capitalized
        }
    }

    static func sriStatusTitle(_ status: String) -> String {
        switch status.lowercased() {
        case "pending": "Pendiente SRI"
        case "received": "Recibido por SRI"
        case "processing", "ppr": "Procesando"
        case "authorized": "Autorizado"
        case "not_authorized", "notauthorized", "no_autorizada": "No autorizada"
        case "returned": "Devuelto"
        case "rejected": "Rechazado"
        case "unavailable": "SRI no disponible"
        default: status.isEmpty ? "Sin estado SRI" : status.capitalized
        }
    }

    static func environmentTitle(_ environment: String) -> String {
        switch environment.lowercased() {
        case "1", "test", "testing", "pruebas", "certification": "Pruebas"
        case "2", "production", "prod", "produccion", "producción": "Producción"
        default: environment.isEmpty ? "Ambiente no definido" : environment.capitalized
        }
    }

    static func timelineTitle(_ type: String, backendTitle: String? = nil) -> String {
        switch normalizedTimelineToken(type) {
        case "SRI_ACCESS_KEY_GENERATED", "ACCESS_KEY_GENERATED":
            return "Clave de acceso generada"
        case "ELECTRONIC_XML_GENERATED", "XML_GENERATED":
            return "XML generado"
        case "ELECTRONIC_XML_XSD_VALIDATED", "XSD_VALIDATED":
            return "XML validado contra XSD"
        case "ELECTRONIC_XML_XSD_INVALID", "XSD_INVALID":
            return "XML inválido"
        case "ELECTRONIC_XML_SIGNED", "SIGNED":
            return "XML firmado"
        case "ELECTRONIC_XML_SIGNATURE_FAILED", "SIGNATURE_FAILED":
            return "No se pudo firmar el XML"
        case "SRI_RECEPTION_SUBMITTED", "SUBMITTED_TO_RECEPTION":
            return "Enviado a recepción SRI"
        case "SRI_RECEPTION_RECEIVED", "RECEIVED_BY_SRI":
            return "Recibido por el SRI"
        case "SRI_RECEPTION_RETURNED", "RETURNED_BY_SRI", "RETURNED":
            return "Devuelto por el SRI"
        case "SRI_RECEPTION_TRANSPORT_FAILED", "RECEPTION_TRANSPORT_FAILED":
            return "No se pudo conectar con recepción SRI"
        case "SRI_AUTHORIZATION_QUERIED":
            return "Autorización consultada"
        case "SRI_AUTHORIZATION_PROCESSING", "AUTHORIZATION_PENDING":
            return "Autorización en proceso"
        case "SRI_AUTHORIZED", "AUTHORIZED", "AUTORIZADO":
            return "Autorizado por el SRI"
        case "SRI_NOT_AUTHORIZED", "NOT_AUTHORIZED", "NO_AUTORIZADA":
            return "No autorizado por el SRI"
        case "SRI_AUTHORIZATION_TRANSPORT_FAILED", "AUTHORIZATION_TRANSPORT_FAILED":
            return "No se pudo consultar autorización SRI"
        case "ELECTRONIC_RIDE_GENERATED":
            return "RIDE generado correctamente"
        case "ELECTRONIC_RIDE_REUSED":
            return "RIDE reutilizado correctamente"
        case "ELECTRONIC_INVOICE_EMAIL_SENT", "DELIVERED":
            return "Correo enviado correctamente"
        case "ELECTRONIC_INVOICE_EMAIL_FAILED", "DELIVERY_FAILED":
            return "No se pudo enviar el correo"
        case "DELIVERY_PENDING":
            return "Correo pendiente de envío"
        case "CANCELLATION_REQUESTED":
            return "Anulación solicitada"
        case "CANCELED", "CANCELLED":
            return "Comprobante anulado"
        case "ERROR":
            return "Error documental"
        default:
            return sanitizedBackendTimelineTitle(backendTitle) ?? "Evento documental registrado"
        }
    }

    static func timelineMessage(_ type: String, backendMessage: String? = nil) -> String {
        if let safeBackendMessage = AdminElectronicDocumentTextSanitizer.sanitizedMessage(backendMessage) {
            return safeBackendMessage
        }

        switch normalizedTimelineToken(type) {
        case "SRI_ACCESS_KEY_GENERATED", "ACCESS_KEY_GENERATED":
            return "Se generó la clave de acceso del comprobante."
        case "ELECTRONIC_XML_GENERATED", "XML_GENERATED":
            return "Se generó el XML del comprobante."
        case "ELECTRONIC_XML_XSD_VALIDATED", "XSD_VALIDATED":
            return "El XML cumple la estructura esperada para su envío."
        case "ELECTRONIC_XML_XSD_INVALID", "XSD_INVALID":
            return "El XML no pasó la validación de estructura."
        case "ELECTRONIC_XML_SIGNED", "SIGNED":
            return "El XML fue firmado con la firma electrónica activa."
        case "ELECTRONIC_XML_SIGNATURE_FAILED", "SIGNATURE_FAILED":
            return "La firma del XML falló. Revisa la firma electrónica configurada."
        case "SRI_RECEPTION_SUBMITTED", "SUBMITTED_TO_RECEPTION":
            return "El comprobante fue enviado al servicio de recepción del SRI."
        case "SRI_RECEPTION_RECEIVED", "RECEIVED_BY_SRI":
            return "El SRI recibió el comprobante para su procesamiento."
        case "SRI_RECEPTION_RETURNED", "RETURNED_BY_SRI", "RETURNED":
            return "El SRI devolvió el comprobante. Revisa los errores registrados."
        case "SRI_RECEPTION_TRANSPORT_FAILED", "RECEPTION_TRANSPORT_FAILED":
            return "No se pudo completar la conexión con recepción SRI. Puedes reintentar si el estado lo permite."
        case "SRI_AUTHORIZATION_QUERIED":
            return "Se consultó el estado de autorización del comprobante."
        case "SRI_AUTHORIZATION_PROCESSING", "AUTHORIZATION_PENDING":
            return "El SRI todavía está procesando la autorización."
        case "SRI_AUTHORIZED", "AUTHORIZED", "AUTORIZADO":
            return "El SRI autorizó el comprobante."
        case "SRI_NOT_AUTHORIZED", "NOT_AUTHORIZED", "NO_AUTORIZADA":
            return "El SRI no autorizó el comprobante. Revisa el detalle de errores."
        case "SRI_AUTHORIZATION_TRANSPORT_FAILED", "AUTHORIZATION_TRANSPORT_FAILED":
            return "No se pudo consultar la autorización en el SRI. Puedes reintentar si el estado lo permite."
        case "ELECTRONIC_RIDE_GENERATED":
            return "RIDE generado correctamente."
        case "ELECTRONIC_RIDE_REUSED":
            return "Se reutilizó el RIDE existente."
        case "ELECTRONIC_INVOICE_EMAIL_SENT", "DELIVERED":
            return "Correo enviado correctamente."
        case "ELECTRONIC_INVOICE_EMAIL_FAILED", "DELIVERY_FAILED":
            return "No se pudo enviar el correo al cliente."
        case "DELIVERY_PENDING":
            return "El correo está pendiente de envío."
        default:
            return "Evento documental registrado."
        }
    }

    static func timelineSeverity(_ value: String?) -> AdminSriErrorSeverity {
        switch normalizedTimelineToken(value ?? "") {
        case "CRITICAL":
            return .critical
        case "ERROR", "XSD_INVALID", "SIGNATURE_FAILED", "RETURNED", "RETURNED_BY_SRI", "NOT_AUTHORIZED", "NO_AUTORIZADA", "DELIVERY_FAILED":
            return .error
        case "WARNING", "RECEPTION_TRANSPORT_FAILED", "AUTHORIZATION_TRANSPORT_FAILED", "AUTHORIZATION_PENDING", "DELIVERY_PENDING":
            return .warning
        default:
            return .info
        }
    }

    private static func normalizedTimelineToken(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "-", with: "_")
            .replacingOccurrences(of: " ", with: "_")
            .uppercased()
    }

    private static func sanitizedBackendTimelineTitle(_ title: String?) -> String? {
        guard let safeTitle = AdminElectronicDocumentTextSanitizer.sanitizedMessage(title) else { return nil }
        let normalized = normalizedTimelineToken(safeTitle)
        guard normalized != "EVENT" else { return nil }
        return safeTitle
    }
}

enum MoneyFormatter {
    static func format(_ value: Decimal, currency: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter.string(from: value as NSDecimalNumber) ?? "\(currency) \(value)"
    }
}

enum DecimalFormatter {
    static func format(_ value: Decimal, fractionDigits: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = fractionDigits
        formatter.minimumFractionDigits = 0
        return formatter.string(from: value as NSDecimalNumber) ?? "\(value)"
    }
}

private extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
}
