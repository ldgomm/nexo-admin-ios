//
//  MockAdminElectronicDocumentData.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import Foundation

enum MockAdminElectronicDocumentData {
    static let authorized = AdminElectronicDocumentSummary(
        id: "doc_001",
        organizationId: "org_001",
        saleId: "sale_001",
        documentType: "factura",
        displayNumber: "001-001-000000123",
        accessKey: "2105202601179000000000120010010000001231234567811",
        authorizationNumber: "2105202601179000000000120010010000001231234567811",
        customerName: "Consumidor Final",
        customerIdentification: "9999999999999",
        customerEmail: "cliente@nexo.ec",
        total: Decimal(string: "23.50") ?? 23.50,
        currency: "USD",
        status: "authorized",
        sriStatus: "authorized",
        environment: "test",
        issueDate: "2026-05-21T14:00:00Z",
        authorizedAt: "2026-05-21T14:01:00Z",
        updatedAt: "2026-05-21T14:01:00Z",
        hasRide: true,
        hasXml: true,
        emailSentAt: "2026-05-21T14:02:00Z",
        lastErrorMessage: nil,
        availableActions: [.viewDetail, .viewTimeline, .downloadRide, .downloadXml, .resendEmail, .regenerateRide],
        retrySummary: AdminElectronicDocumentRetrySummary(canRetryReception: false, canRetryAuthorization: false, canResendEmail: true, canRegenerateRide: true, receptionRetryCount: 0, authorizationRetryCount: 0, emailAttempts: 1, rideRegenerationCount: 0, nextRetryAt: nil, lastRetryAt: nil, message: nil)
    )

    static let rejected = AdminElectronicDocumentSummary(
        id: "doc_002",
        organizationId: "org_001",
        saleId: "sale_002",
        documentType: "factura",
        displayNumber: "001-001-000000124",
        accessKey: "2105202601179000000000120010010000001241234567819",
        authorizationNumber: nil,
        customerName: "Juan Pérez",
        customerIdentification: "1720000001",
        customerEmail: "juan@example.com",
        total: Decimal(string: "11.20") ?? 11.20,
        currency: "USD",
        status: "returned",
        sriStatus: "returned",
        environment: "test",
        issueDate: "2026-05-21T14:30:00Z",
        authorizedAt: nil,
        updatedAt: "2026-05-21T14:31:00Z",
        hasRide: false,
        hasXml: true,
        emailSentAt: nil,
        lastErrorMessage: "La firma electrónica no corresponde al RUC del emisor.",
        availableActions: [.viewDetail, .viewTimeline, .downloadXml, .retryReception, .retryAuthorization, .resendEmail],
        retrySummary: AdminElectronicDocumentRetrySummary(canRetryReception: true, canRetryAuthorization: true, canResendEmail: true, canRegenerateRide: false, receptionRetryCount: 1, authorizationRetryCount: 0, emailAttempts: 0, rideRegenerationCount: 0, nextRetryAt: nil, lastRetryAt: "2026-05-21T14:31:00Z", message: "Estado recuperable")
    )

    static let list = AdminElectronicDocumentList(documents: [authorized, rejected], total: 2, hasMore: false)

    static let detail = AdminElectronicDocumentDetail(
        id: authorized.id,
        summary: authorized,
        branchName: "Matriz",
        emissionPointName: "Caja principal",
        legalName: "ALTOS DEL MURCO S.A.S.",
        commercialName: "Altos del Murco",
        taxId: "1790000000001",
        totals: AdminElectronicDocumentTotals(
            subtotalWithoutTaxes: Decimal(string: "20.43") ?? 20.43,
            subtotalTaxed: Decimal(string: "20.43") ?? 20.43,
            subtotalZeroRate: .zero,
            subtotalExempt: .zero,
            subtotalNotSubject: .zero,
            discountTotal: .zero,
            taxTotal: Decimal(string: "3.07") ?? 3.07,
            tipTotal: .zero,
            grandTotal: Decimal(string: "23.50") ?? 23.50,
            currency: "USD"
        ),
        lines: [
            AdminElectronicDocumentLine(
                id: "line_001",
                code: "CUY_MEDIO",
                description: "Medio cuy asado",
                quantity: Decimal(1),
                unitPrice: Decimal(string: "12.00") ?? 12,
                discount: .zero,
                subtotal: Decimal(string: "12.00") ?? 12,
                taxProfileCode: "iva_current_full",
                taxRate: Decimal(string: "15.00") ?? 15,
                taxValue: Decimal(string: "1.80") ?? 1.80
            ),
            AdminElectronicDocumentLine(
                id: "line_002",
                code: "JUGO",
                description: "Jugo personal",
                quantity: Decimal(1),
                unitPrice: Decimal(string: "8.43") ?? 8.43,
                discount: .zero,
                subtotal: Decimal(string: "8.43") ?? 8.43,
                taxProfileCode: "iva_current_full",
                taxRate: Decimal(string: "15.00") ?? 15,
                taxValue: Decimal(string: "1.27") ?? 1.27
            )
        ],
        sri: AdminElectronicDocumentSriState(
            environment: "test",
            receptionStatus: "received",
            authorizationStatus: "authorized",
            authorizationNumber: authorized.authorizationNumber,
            accessKey: authorized.accessKey,
            receivedAt: "2026-05-21T14:00:30Z",
            authorizedAt: "2026-05-21T14:01:00Z",
            lastCheckedAt: "2026-05-21T14:01:00Z",
            retryCount: 0,
            nextRetryAt: nil
        ),
        artifacts: AdminElectronicDocumentArtifacts(
            ride: AdminDocumentArtifact(
                id: "art_ride_001",
                kind: "ride",
                fileName: "ride-001-001-000000123.pdf",
                contentType: "application/pdf",
                sizeBytes: 124_000,
                downloadURL: URL(string: "https://example.com/ride.pdf"),
                expiresAt: "2026-05-21T15:00:00Z"
            ),
            signedXml: nil,
            authorizedXml: AdminDocumentArtifact(
                id: "art_xml_001",
                kind: "authorized_xml",
                fileName: "factura-001-001-000000123.xml",
                contentType: "application/xml",
                sizeBytes: 18_400,
                downloadURL: URL(string: "https://example.com/factura.xml"),
                expiresAt: "2026-05-21T15:00:00Z"
            )
        ),
        email: AdminElectronicDocumentEmailState(
            recipient: "cliente@nexo.ec",
            status: "sent",
            sentAt: "2026-05-21T14:02:00Z",
            lastError: nil,
            attempts: 1
        ),
        timeline: [
            AdminElectronicDocumentTimelineEvent(id: "evt_1", type: "created", title: "Comprobante creado", message: "Se generó el documento desde la venta.", actor: "Sistema", createdAt: "2026-05-21T14:00:00Z", severity: .info),
            AdminElectronicDocumentTimelineEvent(id: "evt_2", type: "signed", title: "XML firmado", message: "El backend firmó el XML con la firma activa.", actor: "Backend", createdAt: "2026-05-21T14:00:20Z", severity: .info),
            AdminElectronicDocumentTimelineEvent(id: "evt_3", type: "authorized", title: "Autorizado por SRI", message: "El SRI autorizó el comprobante.", actor: "SRI", createdAt: "2026-05-21T14:01:00Z", severity: .info)
        ],
        errors: [],
        warnings: [],
        availableActions: [.viewDetail, .viewTimeline, .downloadRide, .downloadXml, .resendEmail, .regenerateRide],
        retrySummary: AdminElectronicDocumentRetrySummary(canRetryReception: false, canRetryAuthorization: false, canResendEmail: true, canRegenerateRide: true, receptionRetryCount: 0, authorizationRetryCount: 0, emailAttempts: 1, rideRegenerationCount: 0, nextRetryAt: nil, lastRetryAt: nil, message: nil)
    )

    static let rejectedDetail = AdminElectronicDocumentDetail(
        id: rejected.id,
        summary: rejected,
        branchName: "Matriz",
        emissionPointName: "Caja principal",
        legalName: "ALTOS DEL MURCO S.A.S.",
        commercialName: "Altos del Murco",
        taxId: "1790000000001",
        totals: AdminElectronicDocumentTotals(subtotalWithoutTaxes: Decimal(string: "9.74") ?? 9.74, subtotalTaxed: Decimal(string: "9.74") ?? 9.74, subtotalZeroRate: .zero, subtotalExempt: .zero, subtotalNotSubject: .zero, discountTotal: .zero, taxTotal: Decimal(string: "1.46") ?? 1.46, tipTotal: .zero, grandTotal: Decimal(string: "11.20") ?? 11.20, currency: "USD"),
        lines: [],
        sri: AdminElectronicDocumentSriState(environment: "test", receptionStatus: "returned", authorizationStatus: "returned", authorizationNumber: nil, accessKey: rejected.accessKey, receivedAt: "2026-05-21T14:31:00Z", authorizedAt: nil, lastCheckedAt: "2026-05-21T14:31:00Z", retryCount: 1, nextRetryAt: nil),
        artifacts: AdminElectronicDocumentArtifacts(ride: nil, signedXml: AdminDocumentArtifact(id: "art_xml_002", kind: "signed_xml", fileName: "factura-fallida.xml", contentType: "application/xml", sizeBytes: 17_900, downloadURL: URL(string: "https://example.com/fallida.xml"), expiresAt: nil), authorizedXml: nil),
        email: AdminElectronicDocumentEmailState(recipient: "juan@example.com", status: "pending", sentAt: nil, lastError: nil, attempts: 0),
        timeline: [AdminElectronicDocumentTimelineEvent(id: "evt_r1", type: "returned", title: "Devuelto por SRI", message: "El SRI rechazó la recepción del comprobante.", actor: "SRI", createdAt: "2026-05-21T14:31:00Z", severity: .error)],
        errors: [
            AdminSriDocumentError(id: "err_1", code: "FIRMA_INVALIDA", type: "sri", rawMessage: "La firma electrónica no corresponde al RUC del emisor.", userMessage: "Hay un problema con la firma electrónica. Valida que la firma esté activa, vigente y configurada para este RUC.", technicalMessage: nil, field: "Signature", occurredAt: "2026-05-21T14:31:00Z", retryable: false, severity: .error)
        ],
        warnings: [],
        availableActions: [.viewDetail, .viewTimeline, .downloadXml, .retryReception, .retryAuthorization, .resendEmail],
        retrySummary: AdminElectronicDocumentRetrySummary(canRetryReception: true, canRetryAuthorization: true, canResendEmail: true, canRegenerateRide: false, receptionRetryCount: 1, authorizationRetryCount: 0, emailAttempts: 0, rideRegenerationCount: 0, nextRetryAt: nil, lastRetryAt: "2026-05-21T14:31:00Z", message: "Estado recuperable")
    )
}
