//
//  RemoteAdminElectronicDocumentRepository.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import Foundation

struct RemoteAdminElectronicDocumentRepository: AdminElectronicDocumentRepository {
    let api: any AdminElectronicDocumentAPI

    func listDocuments(filter: AdminElectronicDocumentListFilter) async throws -> AdminElectronicDocumentList {
        try await AdminElectronicDocumentMapper.mapList(api.listDocuments(filter: filter))
    }

    func getDocument(id: String) async throws -> AdminElectronicDocumentDetail {
        try await AdminElectronicDocumentMapper.mapDetail(api.getDocument(id: id))
    }

    func retryAuthorization(documentId: String, reason: String) async throws -> AdminDocumentRetryResult {
        let dto = try await api.retryAuthorization(documentId: documentId, reason: reason)
        return AdminElectronicDocumentMapper.mapRetry(dto, fallbackDocumentId: documentId)
    }

    func resendEmail(documentId: String, recipientOverride: String?, reason: String) async throws -> AdminDocumentEmailResendResult {
        let dto = try await api.resendEmail(documentId: documentId, recipientOverride: recipientOverride, reason: reason)
        return AdminElectronicDocumentMapper.mapEmailResult(dto, fallbackDocumentId: documentId)
    }

    func getRideArtifact(documentId: String) async throws -> AdminDocumentArtifact {
        try await AdminElectronicDocumentMapper.mapArtifactResponse(api.getRideArtifact(documentId: documentId))
    }

    func getXmlArtifact(documentId: String, authorizedOnly: Bool) async throws -> AdminDocumentArtifact {
        try await AdminElectronicDocumentMapper.mapArtifactResponse(api.getXmlArtifact(documentId: documentId, authorizedOnly: authorizedOnly))
    }
}
