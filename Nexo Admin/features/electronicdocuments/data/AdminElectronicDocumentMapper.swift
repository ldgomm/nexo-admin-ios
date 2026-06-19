//
//  AdminElectronicDocumentMapper.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import Foundation

enum AdminElectronicDocumentMapper {
    static func mapList(_ dto: AdminElectronicDocumentListResponseDTO) -> AdminElectronicDocumentList {
        let items = dto.documents ?? dto.items ?? []
        return AdminElectronicDocumentList(
            documents: items.map(mapSummary),
            total: dto.total ?? items.count,
            hasMore: dto.hasMore ?? false
        )
    }

    static func mapDetail(_ response: AdminElectronicDocumentDetailResponseDTO) throws -> AdminElectronicDocumentDetail {
        guard let dto = response.document else {
            throw AppError.decoding("La respuesta no contiene el comprobante.")
        }
        return mapDetail(dto)
    }

    static func mapDetail(_ dto: AdminElectronicDocumentDetailDTO) -> AdminElectronicDocumentDetail {
        let summary = dto.summary.map(mapSummary) ?? AdminElectronicDocumentSummary(
            id: dto.id ?? dto.documentId ?? UUID().uuidString,
            organizationId: dto.organizationId ?? "",
            saleId: dto.saleId,
            documentType: dto.documentType ?? "factura",
            displayNumber: dto.displayNumber ?? "—",
            accessKey: dto.accessKey,
            authorizationNumber: dto.authorizationNumber,
            customerName: dto.customerName ?? "Consumidor final",
            customerIdentification: dto.customerIdentification,
            customerEmail: dto.customerEmail,
            total: dto.total?.value ?? .zero,
            currency: dto.currency ?? "USD",
            status: dto.status ?? "pending",
            sriStatus: dto.sriStatus ?? dto.status ?? "pending",
            environment: dto.environment ?? "test",
            issueDate: dto.issueDate ?? "—",
            authorizedAt: dto.authorizedAt,
            updatedAt: dto.updatedAt ?? "—",
            hasRide: dto.artifacts?.ride != nil,
            hasXml: dto.artifacts?.authorizedXml != nil || dto.artifacts?.signedXml != nil || dto.artifacts?.xml != nil,
            emailSentAt: dto.email?.sentAt,
            lastErrorMessage: dto.errors?.first?.userMessage ?? dto.errors?.first?.message,
            availableActions: mapActions(dto.availableActions),
            retrySummary: mapRetrySummary(dto.retrySummary)
        )

        return AdminElectronicDocumentDetail(
            id: summary.id,
            summary: summary,
            branchName: dto.branchName,
            emissionPointName: dto.emissionPointName,
            legalName: dto.legalName,
            commercialName: dto.commercialName,
            taxId: dto.taxId,
            totals: mapTotals(dto.totals, fallbackTotal: summary.total, fallbackCurrency: summary.currency),
            lines: (dto.lines ?? []).map(mapLine),
            sri: mapSri(dto.sri, summary: summary),
            artifacts: mapArtifacts(dto.artifacts),
            email: mapEmail(dto.email, summary: summary),
            timeline: (dto.timeline ?? []).map(mapTimeline),
            errors: (dto.errors ?? []).map(mapSriError),
            warnings: dto.warnings ?? [],
            availableActions: mapActions(dto.availableActions).isEmpty ? summary.availableActions : mapActions(dto.availableActions),
            retrySummary: dto.retrySummary == nil ? summary.retrySummary : mapRetrySummary(dto.retrySummary)
        )
    }

    static func mapSummary(_ dto: AdminElectronicDocumentSummaryDTO) -> AdminElectronicDocumentSummary {
        AdminElectronicDocumentSummary(
            id: dto.id ?? dto.documentId ?? UUID().uuidString,
            organizationId: dto.organizationId ?? "",
            saleId: dto.saleId,
            documentType: dto.documentType ?? dto.type ?? "factura",
            displayNumber: dto.displayNumber ?? dto.number ?? "—",
            accessKey: dto.accessKey ?? dto.claveAcceso,
            authorizationNumber: dto.authorizationNumber ?? dto.numeroAutorizacion,
            customerName: dto.customerName ?? dto.customer ?? "Consumidor final",
            customerIdentification: dto.customerIdentification,
            customerEmail: dto.customerEmail,
            total: dto.total?.value ?? dto.grandTotal?.value ?? .zero,
            currency: dto.currency ?? "USD",
            status: dto.status ?? "pending",
            sriStatus: dto.sriStatus ?? dto.status ?? "pending",
            environment: dto.environment ?? "test",
            issueDate: dto.issueDate ?? dto.issuedAt ?? "—",
            authorizedAt: dto.authorizedAt,
            updatedAt: dto.updatedAt ?? "—",
            hasRide: dto.hasRide ?? false,
            hasXml: dto.hasXml ?? false,
            emailSentAt: dto.emailSentAt,
            lastErrorMessage: dto.lastErrorMessage,
            availableActions: mapActions(dto.availableActions),
            retrySummary: mapRetrySummary(dto.retrySummary)
        )
    }

    static func mapArtifactResponse(_ response: AdminDocumentArtifactResponseDTO) throws -> AdminDocumentArtifact {
        guard let dto = response.artifact ?? response.ride ?? response.xml else {
            throw AppError.decoding("La respuesta no contiene el archivo solicitado.")
        }
        return mapArtifact(dto)
    }

    static func mapTimelineResponse(_ response: AdminElectronicDocumentTimelineResponseDTO) -> [AdminElectronicDocumentTimelineEvent] {
        (response.events ?? response.timeline ?? []).map(mapTimeline)
    }

    static func mapRideRegeneration(_ dto: AdminDocumentRideRegenerationResponseDTO, fallbackDocumentId: String) -> AdminDocumentRideRegenerationResult {
        AdminDocumentRideRegenerationResult(
            documentId: dto.documentId ?? fallbackDocumentId,
            accepted: dto.accepted ?? true,
            status: dto.status ?? "queued",
            message: dto.message ?? "Regeneración de RIDE solicitada.",
            requestedAt: dto.requestedAt ?? ISO8601DateFormatter().string(from: Date()),
            artifact: (dto.artifact ?? dto.ride).map(mapArtifact)
        )
    }

    static func mapRetry(_ dto: AdminDocumentRetryResponseDTO, fallbackDocumentId: String) -> AdminDocumentRetryResult {
        AdminDocumentRetryResult(
            documentId: dto.documentId ?? fallbackDocumentId,
            accepted: dto.accepted ?? true,
            status: dto.status ?? "queued",
            message: dto.message ?? "Reintento solicitado.",
            requestedAt: dto.requestedAt ?? ISO8601DateFormatter().string(from: Date())
        )
    }

    static func mapEmailResult(_ dto: AdminDocumentEmailResendResponseDTO, fallbackDocumentId: String) -> AdminDocumentEmailResendResult {
        AdminDocumentEmailResendResult(
            documentId: dto.documentId ?? fallbackDocumentId,
            accepted: dto.accepted ?? true,
            recipient: dto.recipient,
            message: dto.message ?? "Reenvío solicitado.",
            requestedAt: dto.requestedAt ?? ISO8601DateFormatter().string(from: Date())
        )
    }

    private static func mapTotals(_ dto: AdminElectronicDocumentTotalsDTO?, fallbackTotal: Decimal, fallbackCurrency: String) -> AdminElectronicDocumentTotals {
        AdminElectronicDocumentTotals(
            subtotalWithoutTaxes: dto?.subtotalWithoutTaxes?.value ?? .zero,
            subtotalTaxed: dto?.subtotalTaxed?.value ?? .zero,
            subtotalZeroRate: dto?.subtotalZeroRate?.value ?? .zero,
            subtotalExempt: dto?.subtotalExempt?.value ?? .zero,
            subtotalNotSubject: dto?.subtotalNotSubject?.value ?? .zero,
            discountTotal: dto?.discountTotal?.value ?? .zero,
            taxTotal: dto?.taxTotal?.value ?? .zero,
            tipTotal: dto?.tipTotal?.value ?? .zero,
            grandTotal: dto?.grandTotal?.value ?? fallbackTotal,
            currency: dto?.currency ?? fallbackCurrency
        )
    }

    private static func mapLine(_ dto: AdminElectronicDocumentLineDTO) -> AdminElectronicDocumentLine {
        AdminElectronicDocumentLine(
            id: dto.id ?? UUID().uuidString,
            code: dto.code,
            description: dto.description ?? "Línea sin descripción",
            quantity: dto.quantity?.value ?? .zero,
            unitPrice: dto.unitPrice?.value ?? .zero,
            discount: dto.discount?.value ?? .zero,
            subtotal: dto.subtotal?.value ?? .zero,
            taxProfileCode: dto.taxProfileCode,
            taxRate: dto.taxRate?.value,
            taxValue: dto.taxValue?.value ?? .zero
        )
    }

    private static func mapSri(_ dto: AdminElectronicDocumentSriStateDTO?, summary: AdminElectronicDocumentSummary) -> AdminElectronicDocumentSriState {
        AdminElectronicDocumentSriState(
            environment: dto?.environment ?? summary.environment,
            receptionStatus: dto?.receptionStatus,
            authorizationStatus: dto?.authorizationStatus ?? summary.sriStatus,
            authorizationNumber: dto?.authorizationNumber ?? summary.authorizationNumber,
            accessKey: dto?.accessKey ?? summary.accessKey,
            receivedAt: dto?.receivedAt,
            authorizedAt: dto?.authorizedAt ?? summary.authorizedAt,
            lastCheckedAt: dto?.lastCheckedAt,
            retryCount: dto?.retryCount ?? 0,
            nextRetryAt: dto?.nextRetryAt
        )
    }

    private static func mapArtifacts(_ dto: AdminElectronicDocumentArtifactsDTO?) -> AdminElectronicDocumentArtifacts {
        AdminElectronicDocumentArtifacts(
            ride: dto?.ride.map(mapArtifact),
            signedXml: dto?.signedXml.map(mapArtifact),
            authorizedXml: (dto?.authorizedXml ?? dto?.xml).map(mapArtifact)
        )
    }

    private static func mapArtifact(_ dto: AdminDocumentArtifactDTO) -> AdminDocumentArtifact {
        let rawURL = dto.downloadURL ?? dto.downloadUrl ?? dto.url
        return AdminDocumentArtifact(
            id: dto.id ?? dto.artifactId ?? UUID().uuidString,
            kind: dto.kind ?? "artifact",
            fileName: dto.fileName ?? "archivo",
            contentType: dto.contentType ?? "application/octet-stream",
            sizeBytes: dto.sizeBytes,
            downloadURL: rawURL.flatMap(URL.init(string:)),
            expiresAt: dto.expiresAt
        )
    }

    private static func mapEmail(_ dto: AdminElectronicDocumentEmailStateDTO?, summary: AdminElectronicDocumentSummary) -> AdminElectronicDocumentEmailState {
        AdminElectronicDocumentEmailState(
            recipient: dto?.recipient ?? summary.customerEmail,
            status: dto?.status ?? (summary.emailSentAt == nil ? "pending" : "sent"),
            sentAt: dto?.sentAt ?? summary.emailSentAt,
            lastError: dto?.lastError,
            attempts: dto?.attempts ?? 0
        )
    }

    private static func mapSriError(_ dto: AdminSriDocumentErrorDTO) -> AdminSriDocumentError {
        let raw = dto.rawMessage ?? dto.message ?? "Error SRI sin detalle técnico."
        return AdminSriDocumentError(
            id: dto.id ?? "\(dto.code ?? "sri")_\(UUID().uuidString)",
            code: dto.code ?? "SIN_CODIGO",
            type: dto.type ?? "sri",
            rawMessage: raw,
            userMessage: dto.userMessage ?? SriErrorTranslator.translate(code: dto.code, rawMessage: raw),
            technicalMessage: dto.technicalMessage,
            field: dto.field,
            occurredAt: dto.occurredAt,
            retryable: dto.retryable ?? SriErrorTranslator.isProbablyRetryable(code: dto.code, rawMessage: raw),
            severity: AdminSriErrorSeverity(rawValue: dto.severity?.lowercased() ?? "") ?? .error
        )
    }

    private static func mapActions(_ dto: [AdminElectronicDocumentActionDTO]?) -> [AdminElectronicDocumentAction] {
        var seen = Set<String>()
        return (dto ?? [])
            .map { AdminElectronicDocumentAction(rawValue: $0.rawValue) }
            .filter { action in
                let key = action.publicRawValue
                guard !seen.contains(key) else { return false }
                seen.insert(key)
                return true
            }
    }

    private static func mapRetrySummary(_ dto: AdminElectronicDocumentRetrySummaryDTO?) -> AdminElectronicDocumentRetrySummary {
        AdminElectronicDocumentRetrySummary(
            canRetryReception: dto?.canRetryReception ?? false,
            canRetryAuthorization: dto?.canRetryAuthorization ?? false,
            canResendEmail: dto?.canResendEmail ?? false,
            canRegenerateRide: dto?.canRegenerateRide ?? false,
            receptionRetryCount: dto?.receptionRetryCount ?? 0,
            authorizationRetryCount: dto?.authorizationRetryCount ?? 0,
            emailAttempts: dto?.emailAttempts ?? 0,
            rideRegenerationCount: dto?.rideRegenerationCount ?? 0,
            nextRetryAt: dto?.nextRetryAt,
            lastRetryAt: dto?.lastRetryAt,
            message: dto?.message
        )
    }

    private static func mapTimeline(_ dto: AdminElectronicDocumentTimelineEventDTO) -> AdminElectronicDocumentTimelineEvent {
        let rawType = dto.type ?? dto.action ?? dto.status ?? "event"
        return AdminElectronicDocumentTimelineEvent(
            id: dto.id ?? UUID().uuidString,
            type: rawType,
            title: AdminElectronicDocumentText.timelineTitle(rawType, backendTitle: dto.title),
            message: AdminElectronicDocumentText.timelineMessage(rawType, backendMessage: dto.message),
            actor: dto.actor ?? dto.actorUserId,
            createdAt: dto.createdAt ?? dto.occurredAt ?? "—",
            severity: AdminElectronicDocumentText.timelineSeverity(dto.severity ?? dto.status ?? rawType)
        )
    }
}

enum SriErrorTranslator {
    static func translate(code: String?, rawMessage: String) -> String {
        let normalized = rawMessage.lowercased()
        if normalized.contains("clave de acceso") && normalized.contains("registrada") {
            return "La clave de acceso ya existe o ya fue recibida por el SRI. Revisa si el comprobante fue enviado antes de reintentar."
        }
        if normalized.contains("firma") || normalized.contains("certificado") {
            return "Hay un problema con la firma electrónica. Valida que la firma esté activa, vigente y configurada para este RUC."
        }
        if normalized.contains("ruc") || normalized.contains("identificación") || normalized.contains("identificacion") {
            return "Revisa el RUC o identificación del emisor/receptor. Debe coincidir exactamente con los datos del comprobante."
        }
        if normalized.contains("secuencial") {
            return "El secuencial del comprobante tiene conflicto. Verifica el punto de emisión y el último número utilizado."
        }
        if normalized.contains("ambiente") {
            return "El ambiente de emisión no coincide con la configuración autorizada. Revisa si estás en pruebas o producción."
        }
        if normalized.contains("web service") || normalized.contains("timeout") || normalized.contains("no disponible") {
            return "El SRI o la conexión no respondió correctamente. Puedes reintentar cuando el servicio esté disponible."
        }
        if let code, !code.isEmpty {
            return "El SRI devolvió el código \(code). Revisa el detalle técnico antes de reintentar."
        }
        return rawMessage
    }

    static func isProbablyRetryable(code: String?, rawMessage: String) -> Bool {
        let normalized = rawMessage.lowercased()
        return normalized.contains("timeout") || normalized.contains("no disponible") || normalized.contains("procesando") || normalized.contains("ppr") || code == "PPR"
    }
}
