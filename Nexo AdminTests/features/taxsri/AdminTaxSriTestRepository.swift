//
//  AdminTaxSriTestRepository.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import Foundation
@testable import Nexo_Admin

actor AdminTaxSriTestRepository: AdminTaxSriRepository {
    var taxSettings = MockAdminTaxSriData.taxSettings
    var profiles = MockAdminTaxSriData.profiles
    var signatures = MockAdminTaxSriData.signatures
    var sriSettings = MockAdminTaxSriData.sriSettings
    var readiness = MockAdminTaxSriData.readiness
    var runs = MockAdminTaxSriData.runs
    var didRunReadiness = false
    var didRequestProduction = false

    func getTaxSettings() async throws -> AdminTaxSettings {
        taxSettings
    }

    func updateTaxSettings(_ input: UpdateAdminTaxSettingsInput) async throws -> AdminTaxSettings {
        taxSettings = AdminTaxSettings(
            organizationId: taxSettings.organizationId,
            regimeCode: input.regimeCode ?? taxSettings.regimeCode,
            regimeName: taxSettings.regimeName,
            defaultTaxProfileId: input.defaultTaxProfileId ?? taxSettings.defaultTaxProfileId,
            defaultCurrency: taxSettings.defaultCurrency,
            obligatedToKeepAccounting: input.obligatedToKeepAccounting ?? taxSettings.obligatedToKeepAccounting,
            specialTaxpayerNumber: input.clearSpecialTaxpayerNumber ? nil : (input.specialTaxpayerNumber ?? taxSettings.specialTaxpayerNumber),
            rimpeLegend: input.rimpeLegend ?? taxSettings.rimpeLegend,
            withholdingAgentResolution: input.clearWithholdingAgentResolution ? nil : (input.withholdingAgentResolution ?? taxSettings.withholdingAgentResolution),
            updatedAt: "now",
            version: taxSettings.version + 1
        )

        return taxSettings
    }

    func listTaxProfiles() async throws -> [AdminTaxProfile] {
        profiles
    }

    func getTaxProfile(id: String) async throws -> AdminTaxProfile {
        profiles.first { $0.id == id } ?? profiles[0]
    }

    func listSignatures() async throws -> [AdminElectronicSignature] {
        signatures
    }

    func uploadSignature(_ input: UploadAdminElectronicSignatureInput) async throws -> AdminElectronicSignature {
        let signature = AdminElectronicSignature(
            id: "sig_new",
            organizationId: taxSettings.organizationId,
            alias: input.alias,
            subject: "subject",
            issuer: "issuer",
            serialNumber: "serial",
            validFrom: nil,
            validTo: nil,
            status: "uploaded",
            effectiveStatus: "uploaded",
            usable: false,
            expiresInDays: nil,
            expiresSoon: false,
            uploadedBy: "test",
            uploadedAt: "now",
            lastUsedAt: nil,
            lastValidatedAt: nil,
            createdAt: "now"
        )

        signatures.insert(signature, at: 0)
        return signature
    }

    func validateSignature(_ input: AdminSignatureActionInput) async throws -> AdminElectronicSignature {
        let signature = updatedSignature(
            for: input.signatureId,
            status: "valid",
            effectiveStatus: "valid",
            usable: true,
            lastValidatedAt: "now"
        )

        return signature
    }

    func activateSignature(_ input: AdminSignatureActionInput) async throws -> AdminElectronicSignature {
        let signature = updatedSignature(
            for: input.signatureId,
            status: "active",
            effectiveStatus: "active",
            usable: true,
            lastValidatedAt: signatures.first { $0.id == input.signatureId }?.lastValidatedAt
        )

        return signature
    }

    func revokeSignature(_ input: AdminSignatureActionInput) async throws -> AdminElectronicSignature {
        let signature = updatedSignature(
            for: input.signatureId,
            status: "revoked",
            effectiveStatus: "revoked",
            usable: false,
            lastValidatedAt: signatures.first { $0.id == input.signatureId }?.lastValidatedAt
        )

        return signature
    }

    func getSriSettings() async throws -> AdminSriSettings {
        sriSettings
    }

    func updateSriSettings(_ input: UpdateAdminSriSettingsInput) async throws -> AdminSriSettings {
        sriSettings = AdminSriSettings(
            organizationId: sriSettings.organizationId,
            environment: input.environment ?? sriSettings.environment,
            emissionType: input.emissionType ?? sriSettings.emissionType,
            authorizationMode: input.authorizationMode ?? sriSettings.authorizationMode,
            establishmentCode: input.establishmentCode ?? sriSettings.establishmentCode,
            emissionPointCode: input.emissionPointCode ?? sriSettings.emissionPointCode,
            productionEnabled: sriSettings.productionEnabled,
            productionRequestedAt: sriSettings.productionRequestedAt,
            productionEnabledAt: sriSettings.productionEnabledAt,
            lastReadinessStatus: sriSettings.lastReadinessStatus,
            updatedAt: "now"
        )

        return sriSettings
    }

    func runReadiness() async throws -> AdminSriReadiness {
        didRunReadiness = true
        return readiness
    }

    func getReadiness() async throws -> AdminSriReadiness {
        readiness
    }

    func startHomologation(reason: String) async throws -> AdminSriHomologationRun {
        let run = AdminSriHomologationRun(
            id: "run_new",
            status: "running",
            environment: "test",
            startedAt: "now",
            finishedAt: nil,
            invoiceAccessKey: nil,
            authorizationNumber: nil,
            errorMessage: nil,
            checklist: []
        )

        runs.insert(run, at: 0)
        return run
    }

    func listHomologationRuns(limit: Int) async throws -> [AdminSriHomologationRun] {
        Array(runs.prefix(limit))
    }

    func requestProductionEnable(_ input: RequestProductionEnableInput) async throws -> AdminSriSettings {
        didRequestProduction = true
        return sriSettings
    }

    private func updatedSignature(
        for id: String,
        status: String,
        effectiveStatus: String,
        usable: Bool,
        lastValidatedAt: String?
    ) -> AdminElectronicSignature {
        let index = signatures.firstIndex { $0.id == id } ?? 0
        let current = signatures[index]

        let signature = AdminElectronicSignature(
            id: current.id,
            organizationId: current.organizationId,
            alias: current.alias,
            subject: current.subject,
            issuer: current.issuer,
            serialNumber: current.serialNumber,
            validFrom: current.validFrom,
            validTo: current.validTo,
            status: status,
            effectiveStatus: effectiveStatus,
            usable: usable,
            expiresInDays: current.expiresInDays,
            expiresSoon: current.expiresSoon,
            uploadedBy: current.uploadedBy,
            uploadedAt: current.uploadedAt,
            lastUsedAt: current.lastUsedAt,
            lastValidatedAt: lastValidatedAt,
            createdAt: current.createdAt
        )

        signatures[index] = signature
        return signature
    }
}
