//
//  APIRequestHeaders.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import Foundation

enum APIRequestHeaders {
    static let clientApp = "X-Client-App"
    static let organizationId = "X-Organization-Id"
    static let branchId = "X-Branch-Id"
    static let deviceId = "X-Device-Id"
    static let appType = "X-App-Type"
    static let appVersion = "X-App-Version"
    static let correlationId = "X-Correlation-Id"
    static let idempotencyKey = "Idempotency-Key"
    static let catalogRevision = "X-Catalog-Revision"
}

struct APIRequestIdentity: Sendable {
    let correlationId: String
    let idempotencyKey: String

    static func new() -> APIRequestIdentity {
        let value = UUID().uuidString.lowercased()
        return APIRequestIdentity(correlationId: value, idempotencyKey: value)
    }
}
