//
//  RemoteAdminElectronicDocumentRepository.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import Foundation

struct RemoteAdminElectronicDocumentRepository: AdminElectronicDocumentRepository {
    let api: any AdminElectronicDocumentAPI
    private let temporaryFileStore: AdminElectronicDocumentTemporaryFileStore

    init(
        api: any AdminElectronicDocumentAPI,
        temporaryFileStore: AdminElectronicDocumentTemporaryFileStore = AdminElectronicDocumentTemporaryFileStore()
    ) {
        self.api = api
        self.temporaryFileStore = temporaryFileStore
    }

    func listDocuments(filter: AdminElectronicDocumentListFilter) async throws -> AdminElectronicDocumentList {
        try await AdminElectronicDocumentMapper.mapList(api.listDocuments(filter: filter))
    }

    func getDocument(id: String) async throws -> AdminElectronicDocumentDetail {
        try await AdminElectronicDocumentMapper.mapDetail(api.getDocument(id: id))
    }

    func getTimeline(documentId: String, limit: Int) async throws -> [AdminElectronicDocumentTimelineEvent] {
        try await AdminElectronicDocumentMapper.mapTimelineResponse(api.getTimeline(documentId: documentId, limit: limit))
    }

    func retryReception(documentId: String, reason: String) async throws -> AdminDocumentRetryResult {
        let dto = try await api.retryReception(documentId: documentId, reason: reason)
        return AdminElectronicDocumentMapper.mapRetry(dto, fallbackDocumentId: documentId)
    }

    func retryAuthorization(documentId: String, reason: String) async throws -> AdminDocumentRetryResult {
        let dto = try await api.retryAuthorization(documentId: documentId, reason: reason)
        return AdminElectronicDocumentMapper.mapRetry(dto, fallbackDocumentId: documentId)
    }

    func resendEmail(documentId: String, recipientOverride: String?, reason: String) async throws -> AdminDocumentEmailResendResult {
        let dto = try await api.resendEmail(documentId: documentId, recipientOverride: recipientOverride, reason: reason)
        return AdminElectronicDocumentMapper.mapEmailResult(dto, fallbackDocumentId: documentId)
    }

    func regenerateRide(documentId: String, reason: String) async throws -> AdminDocumentRideRegenerationResult {
        let dto = try await api.regenerateRide(documentId: documentId, reason: reason)
        return AdminElectronicDocumentMapper.mapRideRegeneration(dto, fallbackDocumentId: documentId)
    }

    func getRideArtifact(documentId: String) async throws -> AdminDocumentArtifact {
        try await AdminElectronicDocumentMapper.mapArtifactResponse(api.getRideArtifact(documentId: documentId))
    }

    func getXmlArtifact(documentId: String, authorizedOnly: Bool) async throws -> AdminDocumentArtifact {
        try await AdminElectronicDocumentMapper.mapArtifactResponse(api.getXmlArtifact(documentId: documentId, authorizedOnly: authorizedOnly))
    }

    func downloadRideFile(documentId: String) async throws -> AdminElectronicDocumentDownloadedFile {
        guard let fileAPI = api as? any AdminElectronicDocumentFileAPI else {
            throw AppError.transport("El cliente de comprobantes no soporta descarga binaria de RIDE.")
        }

        let response = try await fileAPI.downloadRideFile(documentId: documentId)
        return try temporaryFileStore.write(
            data: response.data,
            preferredFileName: Self.fileName(fromContentDisposition: response.headerValue("Content-Disposition")),
            fallbackFileName: "\(documentId)_RIDE.pdf",
            contentType: response.headerValue("Content-Type")?.nexoAdminFileTrimmedNilIfBlank ?? "application/pdf",
            sha256: response.headerValue("X-Nexo-Artifact-Sha256")?.nexoAdminFileTrimmedNilIfBlank,
            kind: "ride"
        )
    }

    func downloadXmlFile(documentId: String, authorizedOnly: Bool) async throws -> AdminElectronicDocumentDownloadedFile {
        guard let fileAPI = api as? any AdminElectronicDocumentFileAPI else {
            throw AppError.transport("El cliente de comprobantes no soporta descarga binaria de XML.")
        }

        let response = try await fileAPI.downloadXmlFile(documentId: documentId, authorizedOnly: authorizedOnly)
        return try temporaryFileStore.write(
            data: response.data,
            preferredFileName: Self.fileName(fromContentDisposition: response.headerValue("Content-Disposition")),
            fallbackFileName: authorizedOnly ? "\(documentId)_authorized.xml" : "\(documentId)_signed.xml",
            contentType: response.headerValue("Content-Type")?.nexoAdminFileTrimmedNilIfBlank ?? "application/xml",
            sha256: response.headerValue("X-Nexo-Artifact-Sha256")?.nexoAdminFileTrimmedNilIfBlank,
            kind: authorizedOnly ? "authorizedXml" : "signedXml"
        )
    }

    private static func fileName(fromContentDisposition contentDisposition: String?) -> String? {
        guard let contentDisposition else { return nil }

        let parts = contentDisposition.split(separator: ";").map {
            $0.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        for part in parts {
            let lowercased = part.lowercased()

            if lowercased.hasPrefix("filename*=utf-8''") {
                let encoded = String(part.dropFirst("filename*=utf-8''".count))
                return encoded.removingPercentEncoding ?? encoded
            }

            if lowercased.hasPrefix("filename=") {
                return String(part.dropFirst("filename=".count))
                    .trimmingCharacters(in: CharacterSet(charactersIn: "\""))
                    .nexoAdminFileTrimmedNilIfBlank
            }
        }

        return nil
    }
}

private extension String {
    var nexoAdminFileTrimmedNilIfBlank: String? {
        let value = trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }
}
