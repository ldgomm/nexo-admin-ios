//
//  AdminElectronicDocumentRepository.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import Foundation

protocol AdminElectronicDocumentRepository: Sendable {
    func listDocuments(filter: AdminElectronicDocumentListFilter) async throws -> AdminElectronicDocumentList
    func getDocument(id: String) async throws -> AdminElectronicDocumentDetail
    func retryAuthorization(documentId: String, reason: String) async throws -> AdminDocumentRetryResult
    func resendEmail(documentId: String, recipientOverride: String?, reason: String) async throws -> AdminDocumentEmailResendResult
    func getRideArtifact(documentId: String) async throws -> AdminDocumentArtifact
    func getXmlArtifact(documentId: String, authorizedOnly: Bool) async throws -> AdminDocumentArtifact
}

struct ListAdminElectronicDocumentsUseCase: Sendable {
    let repository: any AdminElectronicDocumentRepository

    func execute(filter: AdminElectronicDocumentListFilter) async throws -> AdminElectronicDocumentList {
        try await repository.listDocuments(filter: filter)
    }
}

struct GetAdminElectronicDocumentUseCase: Sendable {
    let repository: any AdminElectronicDocumentRepository

    func execute(id: String) async throws -> AdminElectronicDocumentDetail {
        try await repository.getDocument(id: id)
    }
}

struct RetryAdminElectronicDocumentAuthorizationUseCase: Sendable {
    let repository: any AdminElectronicDocumentRepository

    func execute(documentId: String, reason: String) async throws -> AdminDocumentRetryResult {
        guard !reason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw AppError.validation("Indica el motivo del reintento para dejar trazabilidad.")
        }
        return try await repository.retryAuthorization(documentId: documentId, reason: reason)
    }
}

struct ResendAdminElectronicDocumentEmailUseCase: Sendable {
    let repository: any AdminElectronicDocumentRepository

    func execute(documentId: String, recipientOverride: String?, reason: String) async throws -> AdminDocumentEmailResendResult {
        guard !reason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw AppError.validation("Indica el motivo del reenvío para dejar trazabilidad.")
        }
        return try await repository.resendEmail(documentId: documentId, recipientOverride: recipientOverride, reason: reason)
    }
}
