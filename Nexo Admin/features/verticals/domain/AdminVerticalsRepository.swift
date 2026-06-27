//
//  AdminVerticalsRepository.swift
//  Nexo Admin
//
//  Created by Nexo on 26/6/26.
//

import Foundation

protocol AdminVerticalsRepository: Sendable {
    func listPackages() async throws -> AdminVerticalPackagesResult
    func listActivations() async throws -> AdminVerticalActivationsResult
    func activate(verticalCode: String, request: AdminVerticalActivationRequest) async throws -> AdminVerticalActivation
    func deactivate(verticalCode: String, reason: String) async throws -> AdminVerticalActivation
    func readiness(verticalCode: String) async throws -> AdminVerticalReadinessResult
    func restaurantTablesReadiness(branchId: String?) async throws -> AdminRestaurantTablesReadiness
}

struct AdminVerticalActivationRequest: Equatable, Sendable {
    let reason: String
    let defaultWorkMode: String
    let enabledCapabilities: [String]
}
