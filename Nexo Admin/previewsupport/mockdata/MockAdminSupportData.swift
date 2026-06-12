//
//  MockAdminSupportData.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import Foundation

enum MockAdminSupportData {
    static let health = AdminHealthSummary(
        status: "healthy",
        environment: "staging",
        version: "2.4.0",
        commit: "local",
        database: "connected",
        sri: "test_ready",
        outbox: "ready",
        generatedAt: "2026-05-27T00:00:00Z"
    )

    static let devices = [
        AdminRegisteredDevice(
            deviceId: "dev_1",
            userId: "usr_1",
            organizationId: "org_1",
            appType: "admin_ios",
            appVersion: "v1.0.0 (1)",
            platform: "ios",
            status: "active",
            lastSeenAt: "2026-05-27T00:00:00Z"
        )
    ]
}
