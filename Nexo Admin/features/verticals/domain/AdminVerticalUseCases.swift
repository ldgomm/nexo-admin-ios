//
//  AdminVerticalUseCases.swift
//  Nexo Admin
//
//  Created by Nexo on 26/6/26.
//

import Foundation

struct LoadAdminVerticalActivationUseCase: Sendable {
    let repository: any AdminVerticalsRepository

    func execute(verticalCode: String) async throws -> AdminVerticalActivationPresentation {
        async let packagesTask = repository.listPackages()
        async let activationsTask = repository.listActivations()
        async let readinessTask = repository.readiness(verticalCode: verticalCode)

        let packages = try await packagesTask
        let activations = try await activationsTask
        let readiness = try await readinessTask

        return AdminVerticalActivationPresentation(
            package: packages.packages.first { $0.code == verticalCode },
            activation: activations.activation(for: verticalCode),
            readiness: readiness,
            allPackages: packages.packages,
            allActivations: activations.activations
        )
    }
}

struct ChangeAdminVerticalActivationUseCase: Sendable {
    let repository: any AdminVerticalsRepository

    func activateRestaurant(reason: String, defaultWorkMode: String, enabledCapabilities: [String]) async throws -> AdminVerticalActivation {
        try await repository.activate(
            verticalCode: AdminVerticalCode.restaurant,
            request: AdminVerticalActivationRequest(
                reason: reason,
                defaultWorkMode: defaultWorkMode,
                enabledCapabilities: enabledCapabilities
            )
        )
    }

    func deactivateRestaurant(reason: String) async throws -> AdminVerticalActivation {
        try await repository.deactivate(verticalCode: AdminVerticalCode.restaurant, reason: reason)
    }
}
