//
//  AdminSupportMapper.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import Foundation

extension AdminHealthResponseDTO {
    func toDomain() -> AdminHealthSummary {
        AdminHealthSummary(
            status: status,
            environment: environment ?? "unknown",
            version: version ?? "unknown",
            commit: commit,
            database: database ?? "unknown",
            sri: sri,
            outbox: outbox,
            generatedAt: generatedAt
        )
    }
}

extension AdminRegisteredDeviceDTO {
    func toDomain() -> AdminRegisteredDevice {
        AdminRegisteredDevice(
            deviceId: deviceId,
            userId: userId,
            organizationId: organizationId,
            appType: appType,
            appVersion: appVersion,
            platform: platform,
            status: status,
            lastSeenAt: lastSeenAt
        )
    }
}
