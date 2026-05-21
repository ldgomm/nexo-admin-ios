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

    func getTaxSettings() async throws -> AdminTaxSettings { taxSettings }
    func updateTaxSettings(_ input: UpdateAdminTaxSettingsInput) async throws -> AdminTaxSettings {
        taxSettings = AdminTaxSettings(organizationId: taxSettings.organizationId, regimeCode: input.regimeCode ?? taxSettings.regimeCode, regimeName: input.regimeCode ?? taxSettings.regimeName, defaultTaxProfileId: taxSettings.defaultTaxProfileId, defaultCurrency: taxSettings.defaultCurrency, obligatedToKeepAccounting: input.obligatedToKeepAccounting ?? taxSettings.obligatedToKeepAccounting, specialTaxpayerNumber: taxSettings.specialTaxpayerNumber, rimpeLegend: input.rimpeLegend ?? taxSettings.rimpeLegend, withholdingAgentResolution: taxSettings.withholdingAgentResolution, updatedAt: "now", version: taxSettings.version + 1)
        return taxSettings
    }
    func listTaxProfiles() async throws -> [AdminTaxProfile] { profiles }
    func getTaxProfile(id: String) async throws -> AdminTaxProfile { profiles[0] }
    func listSignatures() async throws -> [AdminElectronicSignature] { signatures }
    func uploadSignature(_ input: UploadAdminElectronicSignatureInput) async throws -> AdminElectronicSignature {
        let signature = AdminElectronicSignature(id: "sig_new", organizationId: "org", alias: input.alias, subject: "subject", issuer: "issuer", serialNumber: "serial", validFrom: nil, validTo: nil, status: "uploaded", isActive: false, expiresInDays: nil, lastValidatedAt: nil, createdAt: nil)
        signatures.insert(signature, at: 0)
        return signature
    }
    func validateSignature(_ input: AdminSignatureActionInput) async throws -> AdminElectronicSignature { signatures[0] }
    func activateSignature(_ input: AdminSignatureActionInput) async throws -> AdminElectronicSignature { signatures[0] }
    func revokeSignature(_ input: AdminSignatureActionInput) async throws -> AdminElectronicSignature { signatures[0] }
    func getSriSettings() async throws -> AdminSriSettings { sriSettings }
    func updateSriSettings(_ input: UpdateAdminSriSettingsInput) async throws -> AdminSriSettings { sriSettings }
    func runReadiness() async throws -> AdminSriReadiness { didRunReadiness = true; return readiness }
    func getReadiness() async throws -> AdminSriReadiness { readiness }
    func startHomologation(reason: String) async throws -> AdminSriHomologationRun { let run = AdminSriHomologationRun(id: "run_new", status: "running", environment: "test", startedAt: "now", finishedAt: nil, invoiceAccessKey: nil, authorizationNumber: nil, errorMessage: nil, checklist: []); runs.insert(run, at: 0); return run }
    func listHomologationRuns(limit: Int) async throws -> [AdminSriHomologationRun] { runs }
    func requestProductionEnable(_ input: RequestProductionEnableInput) async throws -> AdminSriSettings { didRequestProduction = true; return sriSettings }
}
