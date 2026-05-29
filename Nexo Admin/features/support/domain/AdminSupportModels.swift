//
//  AdminSupportModels.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import Foundation

struct AdminHealthSummary: Equatable, Sendable {
    let status: String
    let environment: String
    let version: String
    let commit: String?
    let database: String
    let sri: String?
    let outbox: String?
    let generatedAt: String?

    var healthy: Bool { status.nexoNormalizedKey == "ok" || status.nexoNormalizedKey == "healthy" }
    var statusTitle: String { status.nexoReadableKey }
}

struct AdminRegisteredDevice: Identifiable, Equatable, Sendable {
    var id: String { deviceId }

    let deviceId: String
    let userId: String?
    let organizationId: String?
    let appType: String
    let appVersion: String
    let platform: String
    let status: String
    let lastSeenAt: String?

    var displayName: String { "\(appType) · \(platform)" }
}

struct AdminSupportDiagnosticsSnapshot: Equatable, Sendable {
    let buildInfo: BuildInfo
    let health: AdminHealthSummary?
    let devices: [AdminRegisteredDevice]

    var summaryTitle: String {
        guard let health else { return "Diagnóstico local" }
        return health.healthy ? "API saludable" : "API con advertencias"
    }

    var summaryMessage: String {
        guard let health else { return "No se cargó health remoto. Revisa permisos o endpoint." }
        return "\(health.environment) · \(health.version) · DB: \(health.database)"
    }
}
