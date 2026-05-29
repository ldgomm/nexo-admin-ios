//
//  AdminSupportRepository.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import Foundation

protocol AdminSupportRepository: Sendable {
    func getHealth() async throws -> AdminHealthSummary
    func listDevices() async throws -> [AdminRegisteredDevice]
}
