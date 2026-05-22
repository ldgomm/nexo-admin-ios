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

enum AdminElectronicDocumentText {
    static func statusTitle(_ status: String) -> String {
        switch status.lowercased() {
        case "draft": "Borrador"
        case "issued": "Emitido"
        case "signed": "Firmado"
        case "sent": "Enviado"
        case "authorized": "Autorizado"
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
