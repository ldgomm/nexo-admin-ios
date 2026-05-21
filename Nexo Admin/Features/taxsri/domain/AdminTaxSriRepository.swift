import Foundation

protocol AdminTaxSriRepository: Sendable {
    func getTaxSettings() async throws -> AdminTaxSettings
    func updateTaxSettings(_ input: UpdateAdminTaxSettingsInput) async throws -> AdminTaxSettings
    func listTaxProfiles() async throws -> [AdminTaxProfile]
    func getTaxProfile(id: String) async throws -> AdminTaxProfile

    func listSignatures() async throws -> [AdminElectronicSignature]
    func uploadSignature(_ input: UploadAdminElectronicSignatureInput) async throws -> AdminElectronicSignature
    func validateSignature(_ input: AdminSignatureActionInput) async throws -> AdminElectronicSignature
    func activateSignature(_ input: AdminSignatureActionInput) async throws -> AdminElectronicSignature
    func revokeSignature(_ input: AdminSignatureActionInput) async throws -> AdminElectronicSignature

    func getSriSettings() async throws -> AdminSriSettings
    func updateSriSettings(_ input: UpdateAdminSriSettingsInput) async throws -> AdminSriSettings
    func runReadiness() async throws -> AdminSriReadiness
    func getReadiness() async throws -> AdminSriReadiness
    func startHomologation(reason: String) async throws -> AdminSriHomologationRun
    func listHomologationRuns(limit: Int) async throws -> [AdminSriHomologationRun]
    func requestProductionEnable(_ input: RequestProductionEnableInput) async throws -> AdminSriSettings
}
