//
//  AppEnvironment.swift
//  Nexo Admin
//
//  Created by José Ruiz on 20/5/26.
//

import Foundation

enum BuildConfiguration: String, Sendable {
    case debug
    case staging
    case production
}

struct AppEnvironment: Sendable {
    let baseURL: URL
    let appName: String
    let apiVersion: String
    let buildConfiguration: BuildConfiguration

    static let debug = AppEnvironment(
        baseURL: URL(string: "http://localhost:8080")!,
        appName: "Nexo Admin",
        apiVersion: "v1",
        buildConfiguration: .debug
    )
}
