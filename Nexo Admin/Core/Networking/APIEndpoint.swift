//
//  APIEndpoint.swift
//  Nexo Admin
//
//  Created by José Ruiz on 20/5/26.
//

import Foundation

struct APIEndpoint: Sendable {
    let path: String
    let method: HTTPMethod
    var queryItems: [URLQueryItem] = []
    var headers: [String: String] = [:]
    var requiresAuth: Bool = true
    var requiresOrganization: Bool = false

    init(
        path: String,
        method: HTTPMethod,
        queryItems: [URLQueryItem] = [],
        headers: [String: String] = [:],
        requiresAuth: Bool = true,
        requiresOrganization: Bool = false
    ) {
        self.path = path
        self.method = method
        self.queryItems = queryItems
        self.headers = headers
        self.requiresAuth = requiresAuth
        self.requiresOrganization = requiresOrganization
    }
}
