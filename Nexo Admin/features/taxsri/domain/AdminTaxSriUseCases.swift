//
//  AdminTaxSriUseCases.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import Foundation

struct LoadAdminTaxSriSummaryUseCase: Sendable {
    let repository: any AdminTaxSriRepository

    func execute() async throws -> AdminTaxSriSummary {
        async let taxSettings = repository.getTaxSettings()
        async let profiles = repository.listTaxProfiles()
        async let signatures = repository.listSignatures()
        async let sriSettings = repository.getSriSettings()
        async let readiness = repository.getReadiness()
        async let runs = repository.listHomologationRuns(limit: 20)
        return try await AdminTaxSriSummary(
            taxSettings: taxSettings,
            taxProfiles: profiles,
            signatures: signatures,
            sriSettings: sriSettings,
            readiness: readiness,
            homologationRuns: runs
        )
    }
}

struct UpdateAdminTaxSettingsUseCase: Sendable {
    let repository: any AdminTaxSriRepository
    func execute(_ input: UpdateAdminTaxSettingsInput) async throws -> AdminTaxSettings {
        try await repository.updateTaxSettings(input)
    }
}

struct UploadAdminElectronicSignatureUseCase: Sendable {
    let repository: any AdminTaxSriRepository
    func execute(_ input: UploadAdminElectronicSignatureInput) async throws -> AdminElectronicSignature {
        try await repository.uploadSignature(input)
    }
}

struct RunAdminSriReadinessUseCase: Sendable {
    let repository: any AdminTaxSriRepository
    func execute() async throws -> AdminSriReadiness { try await repository.runReadiness() }
}

struct StartAdminSriHomologationUseCase: Sendable {
    let repository: any AdminTaxSriRepository
    func execute(reason: String) async throws -> AdminSriHomologationRun {
        try await repository.startHomologation(reason: reason)
    }
}

struct RequestAdminSriProductionEnableUseCase: Sendable {
    let repository: any AdminTaxSriRepository
    func execute(_ input: RequestProductionEnableInput) async throws -> AdminSriSettings {
        try await repository.requestProductionEnable(input)
    }
}
