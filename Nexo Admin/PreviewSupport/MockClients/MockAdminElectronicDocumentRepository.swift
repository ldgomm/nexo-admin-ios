//
//  MockAdminElectronicDocumentRepository.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import Foundation

final class MockAdminElectronicDocumentRepository: AdminElectronicDocumentRepository, @unchecked Sendable {
    var listResult: AdminElectronicDocumentList
    var details: [String: AdminElectronicDocumentDetail]
    var shouldFail = false

    init(
        listResult: AdminElectronicDocumentList = MockAdminElectronicDocumentData.list,
        details: [String: AdminElectronicDocumentDetail] = [
            MockAdminElectronicDocumentData.detail.id: MockAdminElectronicDocumentData.detail,
            MockAdminElectronicDocumentData.rejectedDetail.id: MockAdminElectronicDocumentData.rejectedDetail,
        ]
    ) {
        self.listResult = listResult
        self.details = details
    }

    func listDocuments(filter: AdminElectronicDocumentListFilter) async throws -> AdminElectronicDocumentList {
        if shouldFail { throw AppError.server("Error simulado de comprobantes.") }
        let filtered = listResult.documents.filter { document in
            let query = filter.query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let matchesQuery = query.isEmpty || document.displayNumber.lowercased().contains(query) || document.customerName.lowercased().contains(query) || (document.accessKey ?? "").contains(query)
            let matchesStatus = filter.status == .all || document.status.lowercased() == filter.status.rawValue
            let matchesSri = filter.sriStatus == .all || document.sriStatus.lowercased() == filter.sriStatus.rawValue
            return matchesQuery && matchesStatus && matchesSri
        }
        return AdminElectronicDocumentList(documents: filtered, total: filtered.count, hasMore: false)
    }

    func getDocument(id: String) async throws -> AdminElectronicDocumentDetail {
        if shouldFail { throw AppError.server("Error simulado de detalle.") }
        guard let detail = details[id] else { throw AppError.notFound }
        return detail
    }

    func retryAuthorization(documentId: String, reason: String) async throws -> AdminDocumentRetryResult {
        if shouldFail { throw AppError.server("No se pudo reintentar.") }
        return AdminDocumentRetryResult(documentId: documentId, accepted: true, status: "queued", message: "Reintento encolado correctamente.", requestedAt: "2026-05-21T15:00:00Z")
    }

    func resendEmail(documentId: String, recipientOverride: String?, reason: String) async throws -> AdminDocumentEmailResendResult {
        if shouldFail { throw AppError.server("No se pudo reenviar email.") }
        return AdminDocumentEmailResendResult(documentId: documentId, accepted: true, recipient: recipientOverride ?? "cliente@nexo.ec", message: "Email encolado correctamente.", requestedAt: "2026-05-21T15:00:00Z")
    }

    func getRideArtifact(documentId: String) async throws -> AdminDocumentArtifact {
        guard let artifact = details[documentId]?.artifacts.ride else { throw AppError.notFound }
        return artifact
    }

    func getXmlArtifact(documentId: String, authorizedOnly: Bool) async throws -> AdminDocumentArtifact {
        guard let artifacts = details[documentId]?.artifacts else { throw AppError.notFound }
        if authorizedOnly, let authorizedXml = artifacts.authorizedXml { return authorizedXml }
        if let signedXml = artifacts.signedXml { return signedXml }
        if let authorizedXml = artifacts.authorizedXml { return authorizedXml }
        throw AppError.notFound
    }
}
