//
//  AdminBusinessPackagesUseCases.swift
//  Nexo Admin
//
//  Created by Nexo on 22/6/26.
//

import Foundation

struct LoadAdminBusinessPackagesDiagnosticsUseCase: Sendable {
    let repository: any AdminBusinessPackagesRepository

    func execute() async throws -> AdminBusinessPackagesDiagnosticsPresentation {
        let response = try await repository.loadBusinessPackages()
        return AdminBusinessPackagesDiagnosticsPresentation(response: response)
    }
}
