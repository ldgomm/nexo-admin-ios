//
//  APIEndpoint.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import Foundation

struct APIEndpoint: Sendable {
    let path: String
    let method: HTTPMethod
    var queryItems: [URLQueryItem]
    var headers: [String: String]
    var requiresAuth: Bool
    var requiresOrganization: Bool
    var branchId: String?
    var idempotencyKey: String?
    var catalogRevision: String?
    var correlationId: String?
    
    init(
        path: String,
        method: HTTPMethod,
        queryItems: [URLQueryItem] = [],
        headers: [String: String] = [:],
        requiresAuth: Bool = true,
        requiresOrganization: Bool = false,
        branchId: String? = nil,
        idempotencyKey: String? = nil,
        catalogRevision: String? = nil,
        correlationId: String? = nil
    ) {
        self.path = path
        self.method = method
        self.queryItems = queryItems
        self.headers = headers
        self.requiresAuth = requiresAuth
        self.requiresOrganization = requiresOrganization
        self.branchId = branchId
        self.idempotencyKey = idempotencyKey
        self.catalogRevision = catalogRevision
        self.correlationId = correlationId
    }
    
    func withIdempotencyKey(_ key: String) -> APIEndpoint {
        var copy = self
        copy.idempotencyKey = key
        return copy
    }
    
    func withCatalogRevision(_ revision: String?) -> APIEndpoint {
        var copy = self
        copy.catalogRevision = revision
        return copy
    }
    
    func withBranchId(_ branchId: String?) -> APIEndpoint {
        var copy = self
        copy.branchId = branchId
        return copy
    }
}
