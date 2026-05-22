//
//  MockAdminTaxSriRepository.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import Foundation

actor MockAdminTaxSriRepository: AdminTaxSriRepository {
    private var taxSettings = MockAdminTaxSriData.taxSettings
    private var profiles = MockAdminTaxSriData.profiles
    private var signatures = MockAdminTaxSriData.signatures
    private var sriSettings = MockAdminTaxSriData.sriSettings
    private var readiness = MockAdminTaxSriData.readiness
    private var runs = MockAdminTaxSriData.runs

    func getTaxSettings() async throws -> AdminTaxSettings { taxSettings }
    func updateTaxSettings(_ input: UpdateAdminTaxSettingsInput) async throws -> AdminTaxSettings {
        taxSettings = AdminTaxSettings(
            organizationId: taxSettings.organizationId,
            regimeCode: input.regimeCode ?? taxSettings.regimeCode,
            regimeName: input.regimeCode ?? taxSettings.regimeName,
            defaultTaxProfileId: input.defaultTaxProfileId ?? taxSettings.defaultTaxProfileId,
            defaultCurrency: taxSettings.defaultCurrency,
            obligatedToKeepAccounting: input.obligatedToKeepAccounting ?? taxSettings.obligatedToKeepAccounting,
            specialTaxpayerNumber: input.clearSpecialTaxpayerNumber ? nil : input.specialTaxpayerNumber ?? taxSettings.specialTaxpayerNumber,
            rimpeLegend: input.rimpeLegend ?? taxSettings.rimpeLegend,
            withholdingAgentResolution: input.clearWithholdingAgentResolution ? nil : input.withholdingAgentResolution ?? taxSettings.withholdingAgentResolution,
            updatedAt: "now",
            version: taxSettings.version + 1
        )
        return taxSettings
    }
    func listTaxProfiles() async throws -> [AdminTaxProfile] { profiles }
    func getTaxProfile(id: String) async throws -> AdminTaxProfile { profiles.first { $0.id == id } ?? profiles[0] }

    func listSignatures() async throws -> [AdminElectronicSignature] { signatures }
    func uploadSignature(_ input: UploadAdminElectronicSignatureInput) async throws -> AdminElectronicSignature {
        let signature = AdminElectronicSignature(id: "sig_\(signatures.count + 1)", organizationId: "org_altos", alias: input.alias, subject: "Certificado cargado", issuer: "Entidad certificadora", serialNumber: "NEW", validFrom: "2026-05-21", validTo: "2027-05-21", status: "uploaded", isActive: false, expiresInDays: 365, lastValidatedAt: nil, createdAt: "now")
        signatures.insert(signature, at: 0)
        return signature
    }
    func validateSignature(_ input: AdminSignatureActionInput) async throws -> AdminElectronicSignature { try updateSignature(input.signatureId, status: "valid", active: nil) }
    func activateSignature(_ input: AdminSignatureActionInput) async throws -> AdminElectronicSignature {
        signatures = signatures.map { AdminElectronicSignature(id: $0.id, organizationId: $0.organizationId, alias: $0.alias, subject: $0.subject, issuer: $0.issuer, serialNumber: $0.serialNumber, validFrom: $0.validFrom, validTo: $0.validTo, status: $0.status, isActive: false, expiresInDays: $0.expiresInDays, lastValidatedAt: $0.lastValidatedAt, createdAt: $0.createdAt) }
        return try updateSignature(input.signatureId, status: "valid", active: true)
    }
    func revokeSignature(_ input: AdminSignatureActionInput) async throws -> AdminElectronicSignature { try updateSignature(input.signatureId, status: "revoked", active: false) }

    func getSriSettings() async throws -> AdminSriSettings { sriSettings }
    func updateSriSettings(_ input: UpdateAdminSriSettingsInput) async throws -> AdminSriSettings {
        sriSettings = AdminSriSettings(organizationId: sriSettings.organizationId, environment: input.environment ?? sriSettings.environment, emissionType: input.emissionType ?? sriSettings.emissionType, authorizationMode: input.authorizationMode ?? sriSettings.authorizationMode, establishmentCode: input.establishmentCode ?? sriSettings.establishmentCode, emissionPointCode: input.emissionPointCode ?? sriSettings.emissionPointCode, productionEnabled: sriSettings.productionEnabled, productionRequestedAt: sriSettings.productionRequestedAt, productionEnabledAt: sriSettings.productionEnabledAt, lastReadinessStatus: sriSettings.lastReadinessStatus, updatedAt: "now")
        return sriSettings
    }
    func runReadiness() async throws -> AdminSriReadiness { readiness }
    func getReadiness() async throws -> AdminSriReadiness { readiness }
    func startHomologation(reason: String) async throws -> AdminSriHomologationRun {
        let run = AdminSriHomologationRun(id: "homologation_run_\(runs.count + 1)", status: "running", environment: sriSettings.environment, startedAt: "now", finishedAt: nil, invoiceAccessKey: nil, authorizationNumber: nil, errorMessage: nil, checklist: readiness.items)
        runs.insert(run, at: 0)
        return run
    }
    func listHomologationRuns(limit: Int) async throws -> [AdminSriHomologationRun] { Array(runs.prefix(limit)) }
    func requestProductionEnable(_ input: RequestProductionEnableInput) async throws -> AdminSriSettings {
        sriSettings = AdminSriSettings(organizationId: sriSettings.organizationId, environment: sriSettings.environment, emissionType: sriSettings.emissionType, authorizationMode: sriSettings.authorizationMode, establishmentCode: sriSettings.establishmentCode, emissionPointCode: sriSettings.emissionPointCode, productionEnabled: false, productionRequestedAt: "now", productionEnabledAt: nil, lastReadinessStatus: sriSettings.lastReadinessStatus, updatedAt: "now")
        return sriSettings
    }

    private func updateSignature(_ id: String, status: String, active: Bool?) throws -> AdminElectronicSignature {
        guard let index = signatures.firstIndex(where: { $0.id == id }) else { throw AppError.notFound }
        let old = signatures[index]
        let next = AdminElectronicSignature(id: old.id, organizationId: old.organizationId, alias: old.alias, subject: old.subject, issuer: old.issuer, serialNumber: old.serialNumber, validFrom: old.validFrom, validTo: old.validTo, status: status, isActive: active ?? old.isActive, expiresInDays: old.expiresInDays, lastValidatedAt: "now", createdAt: old.createdAt)
        signatures[index] = next
        return next
    }
}
