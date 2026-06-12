//
//  AdminElectronicDocumentDownloadedFile.swift
//  Nexo Admin
//
//  Created by José Ruiz on 12/6/26.
//

import Foundation

struct AdminElectronicDocumentDownloadedFile: Identifiable, Equatable, Sendable {
    let id: String
    let localURL: URL
    let fileName: String
    let contentType: String
    let sizeBytes: Int
    let sha256: String?
    let kind: String

    init(
        localURL: URL,
        fileName: String,
        contentType: String,
        sizeBytes: Int,
        sha256: String?,
        kind: String
    ) {
        self.localURL = localURL
        self.fileName = fileName
        self.contentType = contentType
        self.sizeBytes = sizeBytes
        self.sha256 = sha256
        self.kind = kind
        self.id = localURL.absoluteString
    }

    var humanName: String {
        switch kind.nexoDownloadedFileNormalizedKind {
        case "ride", "ride_pdf":
            return "RIDE PDF"
        case "authorized_xml", "authorizedxml", "xml":
            return "XML autorizado"
        case "signed_xml", "signedxml":
            return "XML firmado"
        default:
            return kind.nexoDownloadedFileReadableKind
        }
    }

    var sizeText: String {
        ByteCountFormatter.string(fromByteCount: Int64(sizeBytes), countStyle: .file)
    }
}

final class AdminElectronicDocumentTemporaryFileStore: @unchecked Sendable {
    private let baseDirectory: URL
    private let fileManager: FileManager

    init(
        baseDirectory: URL = FileManager.default.temporaryDirectory.appendingPathComponent("nexo-admin-electronic-documents", isDirectory: true),
        fileManager: FileManager = .default
    ) {
        self.baseDirectory = baseDirectory
        self.fileManager = fileManager
    }

    func write(
        data: Data,
        preferredFileName: String?,
        fallbackFileName: String,
        contentType: String,
        sha256: String?,
        kind: String
    ) throws -> AdminElectronicDocumentDownloadedFile {
        try fileManager.createDirectory(at: baseDirectory, withIntermediateDirectories: true, attributes: nil)

        let fileName = Self.sanitizedFileName(
            preferredFileName?.nexoDownloadedFileTrimmedNilIfBlank ?? fallbackFileName,
            contentType: contentType
        )
        let localURL = baseDirectory.appendingPathComponent("\(UUID().uuidString)-\(fileName)", isDirectory: false)

        if fileManager.fileExists(atPath: localURL.path) {
            try fileManager.removeItem(at: localURL)
        }

        try data.write(to: localURL, options: [.atomic])

        return AdminElectronicDocumentDownloadedFile(
            localURL: localURL,
            fileName: fileName,
            contentType: contentType,
            sizeBytes: data.count,
            sha256: sha256?.nexoDownloadedFileTrimmedNilIfBlank,
            kind: kind
        )
    }

    private static func sanitizedFileName(_ rawValue: String, contentType: String) -> String {
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        let fallback = trimmed.isEmpty ? "comprobante" : trimmed
        let forbidden = CharacterSet(charactersIn: "/\\:?%*|\"<>\n\r\t")

        let sanitized = fallback
            .components(separatedBy: forbidden)
            .joined(separator: "-")
            .replacingOccurrences(of: "..", with: ".")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let limited = String((sanitized.isEmpty ? "comprobante" : sanitized).prefix(120))

        guard !limited.contains(".") else {
            return limited
        }

        let lowercasedContentType = contentType.lowercased()
        if lowercasedContentType.contains("pdf") {
            return "\(limited).pdf"
        }
        if lowercasedContentType.contains("xml") {
            return "\(limited).xml"
        }
        return limited
    }
}

private extension String {
    var nexoDownloadedFileTrimmedNilIfBlank: String? {
        let value = trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }

    var nexoDownloadedFileNormalizedKind: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: "-", with: "_")
    }

    var nexoDownloadedFileReadableKind: String {
        let normalized = nexoDownloadedFileNormalizedKind
        if normalized.isEmpty { return "Archivo" }
        return normalized
            .split(separator: "_")
            .map { $0.prefix(1).uppercased() + $0.dropFirst().lowercased() }
            .joined(separator: " ")
    }
}
