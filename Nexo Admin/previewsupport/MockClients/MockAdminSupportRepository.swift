//
//  MockAdminSupportRepository.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import Foundation

final class MockAdminSupportRepository: AdminSupportRepository, @unchecked Sendable {
    var health: AdminHealthSummary
    var devices: [AdminRegisteredDevice]

    init(
        health: AdminHealthSummary = MockAdminSupportData.health,
        devices: [AdminRegisteredDevice] = MockAdminSupportData.devices
    ) {
        self.health = health
        self.devices = devices
    }

    func getHealth() async throws -> AdminHealthSummary { health }
    func listDevices() async throws -> [AdminRegisteredDevice] { devices }
}
