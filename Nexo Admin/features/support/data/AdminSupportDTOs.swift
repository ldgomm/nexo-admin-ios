//
//  AdminSupportDTOs.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import Foundation

struct AdminHealthResponseDTO: Decodable, Sendable {
    let status: String
    let environment: String?
    let version: String?
    let commit: String?
    let database: String?
    let sri: String?
    let outbox: String?
    let generatedAt: String?
}

struct AdminDevicesResponseDTO: Decodable, Sendable {
    let devices: [AdminRegisteredDeviceDTO]
}

struct AdminRegisteredDeviceDTO: Decodable, Sendable {
    let deviceId: String
    let userId: String?
    let organizationId: String?
    let appType: String
    let appVersion: String
    let platform: String
    let status: String
    let lastSeenAt: String?
}
