//
//  AdminElectronicDocumentDTOs.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import Foundation

struct AdminElectronicDocumentListResponseDTO: Decodable, Sendable {
    let documents: [AdminElectronicDocumentSummaryDTO]?
    let items: [AdminElectronicDocumentSummaryDTO]?
    let total: Int?
    let hasMore: Bool?
}

struct AdminElectronicDocumentSummaryDTO: Decodable, Sendable {
    let id: String?
    let documentId: String?
    let organizationId: String?
    let saleId: String?
    let documentType: String?
    let type: String?
    let displayNumber: String?
    let number: String?
    let accessKey: String?
    let claveAcceso: String?
    let authorizationNumber: String?
    let numeroAutorizacion: String?
    let customerName: String?
    let customer: String?
    let customerIdentification: String?
    let customerEmail: String?
    let total: FlexibleDecimal?
    let grandTotal: FlexibleDecimal?
    let currency: String?
    let status: String?
    let sriStatus: String?
    let environment: String?
    let issueDate: String?
    let issuedAt: String?
    let authorizedAt: String?
    let updatedAt: String?
    let hasRide: Bool?
    let hasXml: Bool?
    let emailSentAt: String?
    let lastErrorMessage: String?
}

struct AdminElectronicDocumentDetailResponseDTO: Decodable, Sendable {
    let document: AdminElectronicDocumentDetailDTO?
}

struct AdminElectronicDocumentDetailDTO: Decodable, Sendable {
    let id: String?
    let documentId: String?
    let summary: AdminElectronicDocumentSummaryDTO?
    let organizationId: String?
    let saleId: String?
    let documentType: String?
    let displayNumber: String?
    let accessKey: String?
    let authorizationNumber: String?
    let customerName: String?
    let customerIdentification: String?
    let customerEmail: String?
    let total: FlexibleDecimal?
    let currency: String?
    let status: String?
    let sriStatus: String?
    let environment: String?
    let issueDate: String?
    let authorizedAt: String?
    let updatedAt: String?
    let branchName: String?
    let emissionPointName: String?
    let legalName: String?
    let commercialName: String?
    let taxId: String?
    let totals: AdminElectronicDocumentTotalsDTO?
    let lines: [AdminElectronicDocumentLineDTO]?
    let sri: AdminElectronicDocumentSriStateDTO?
    let artifacts: AdminElectronicDocumentArtifactsDTO?
    let email: AdminElectronicDocumentEmailStateDTO?
    let timeline: [AdminElectronicDocumentTimelineEventDTO]?
    let errors: [AdminSriDocumentErrorDTO]?
    let warnings: [String]?
}

struct AdminElectronicDocumentTotalsDTO: Decodable, Sendable {
    let subtotalWithoutTaxes: FlexibleDecimal?
    let subtotalTaxed: FlexibleDecimal?
    let subtotalZeroRate: FlexibleDecimal?
    let subtotalExempt: FlexibleDecimal?
    let subtotalNotSubject: FlexibleDecimal?
    let discountTotal: FlexibleDecimal?
    let taxTotal: FlexibleDecimal?
    let tipTotal: FlexibleDecimal?
    let grandTotal: FlexibleDecimal?
    let currency: String?
}

struct AdminElectronicDocumentLineDTO: Decodable, Sendable {
    let id: String?
    let code: String?
    let description: String?
    let quantity: FlexibleDecimal?
    let unitPrice: FlexibleDecimal?
    let discount: FlexibleDecimal?
    let subtotal: FlexibleDecimal?
    let taxProfileCode: String?
    let taxRate: FlexibleDecimal?
    let taxValue: FlexibleDecimal?
}

struct AdminElectronicDocumentSriStateDTO: Decodable, Sendable {
    let environment: String?
    let receptionStatus: String?
    let authorizationStatus: String?
    let authorizationNumber: String?
    let accessKey: String?
    let receivedAt: String?
    let authorizedAt: String?
    let lastCheckedAt: String?
    let retryCount: Int?
    let nextRetryAt: String?
}

struct AdminElectronicDocumentArtifactsDTO: Decodable, Sendable {
    let ride: AdminDocumentArtifactDTO?
    let signedXml: AdminDocumentArtifactDTO?
    let authorizedXml: AdminDocumentArtifactDTO?
    let xml: AdminDocumentArtifactDTO?
}

struct AdminDocumentArtifactDTO: Decodable, Sendable {
    let id: String?
    let artifactId: String?
    let kind: String?
    let fileName: String?
    let contentType: String?
    let sizeBytes: Int?
    let downloadUrl: String?
    let downloadURL: String?
    let url: String?
    let expiresAt: String?
}

struct AdminElectronicDocumentEmailStateDTO: Decodable, Sendable {
    let recipient: String?
    let status: String?
    let sentAt: String?
    let lastError: String?
    let attempts: Int?
}

struct AdminSriDocumentErrorDTO: Decodable, Sendable {
    let id: String?
    let code: String?
    let type: String?
    let rawMessage: String?
    let message: String?
    let userMessage: String?
    let technicalMessage: String?
    let field: String?
    let occurredAt: String?
    let retryable: Bool?
    let severity: String?
}

struct AdminElectronicDocumentTimelineEventDTO: Decodable, Sendable {
    let id: String?
    let type: String?
    let title: String?
    let message: String?
    let actor: String?
    let createdAt: String?
    let severity: String?
}

struct AdminDocumentActionRequestDTO: Encodable, Sendable {
    let reason: String
}

struct AdminDocumentEmailResendRequestDTO: Encodable, Sendable {
    let recipientOverride: String?
    let reason: String
}

struct AdminDocumentRetryResponseDTO: Decodable, Sendable {
    let documentId: String?
    let accepted: Bool?
    let status: String?
    let message: String?
    let requestedAt: String?
}

struct AdminDocumentEmailResendResponseDTO: Decodable, Sendable {
    let documentId: String?
    let accepted: Bool?
    let recipient: String?
    let message: String?
    let requestedAt: String?
}

struct AdminDocumentArtifactResponseDTO: Decodable, Sendable {
    let artifact: AdminDocumentArtifactDTO?
    let ride: AdminDocumentArtifactDTO?
    let xml: AdminDocumentArtifactDTO?
}

struct FlexibleDecimal: Decodable, Equatable, Sendable {
    let value: Decimal

    init(_ value: Decimal) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let decimal = try? container.decode(Decimal.self) {
            value = decimal
            return
        }
        if let double = try? container.decode(Double.self) {
            value = Decimal(double)
            return
        }
        if let int = try? container.decode(Int.self) {
            value = Decimal(int)
            return
        }
        if let string = try? container.decode(String.self) {
            value = Decimal(string: string.replacingOccurrences(of: ",", with: ".")) ?? .zero
            return
        }
        value = .zero
    }
}
