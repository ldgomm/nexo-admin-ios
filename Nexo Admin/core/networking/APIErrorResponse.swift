//
//  APIErrorResponse.swift
//  Nexo Admin
//
//  Created by José Ruiz on 20/5/26.
//

import Foundation

struct APIErrorResponse: Decodable, Equatable, Sendable {
    let error: String?
    let message: String?
    let details: [String: String]?

    var bestMessage: String {
        message?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfBlank
            ?? error?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfBlank
            ?? "Error desconocido del servidor."
    }
}

extension String {
    var nilIfBlank: String? {
        isEmpty ? nil : self
    }
}
