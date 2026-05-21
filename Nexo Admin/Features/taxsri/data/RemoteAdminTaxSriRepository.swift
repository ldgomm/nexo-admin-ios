import Foundation

final class RemoteAdminTaxSriRepository: AdminTaxSriRepository, @unchecked Sendable {
    private let api: any AdminTaxSriAPI

    init(api: any AdminTaxSriAPI) { self.api = api }

    func getTaxSettings() async throws -> AdminTaxSettings { try await api.getTaxSettings().toDomain() }
    func updateTaxSettings(_ input: UpdateAdminTaxSettingsInput) async throws -> AdminTaxSettings { try await api.updateTaxSettings(input.toDTO()).toDomain() }
    func listTaxProfiles() async throws -> [AdminTaxProfile] { try await api.listTaxProfiles().profiles.map { $0.toDomain() } }
    func getTaxProfile(id: String) async throws -> AdminTaxProfile { try await api.getTaxProfile(id: id).profile.toDomain() }

    func listSignatures() async throws -> [AdminElectronicSignature] { try await api.listSignatures().signatures.map { $0.toDomain() } }
    func uploadSignature(_ input: UploadAdminElectronicSignatureInput) async throws -> AdminElectronicSignature { try await api.uploadSignature(input.toDTO()).signature.toDomain() }
    func validateSignature(_ input: AdminSignatureActionInput) async throws -> AdminElectronicSignature { try await api.validateSignature(id: input.signatureId, request: AdminSignatureActionRequestDTO(reason: input.reason)).signature.toDomain() }
    func activateSignature(_ input: AdminSignatureActionInput) async throws -> AdminElectronicSignature { try await api.activateSignature(id: input.signatureId, request: AdminSignatureActionRequestDTO(reason: input.reason)).signature.toDomain() }
    func revokeSignature(_ input: AdminSignatureActionInput) async throws -> AdminElectronicSignature { try await api.revokeSignature(id: input.signatureId, request: AdminSignatureActionRequestDTO(reason: input.reason)).signature.toDomain() }

    func getSriSettings() async throws -> AdminSriSettings { try await api.getSriSettings().toDomain() }
    func updateSriSettings(_ input: UpdateAdminSriSettingsInput) async throws -> AdminSriSettings { try await api.updateSriSettings(input.toDTO()).toDomain() }
    func runReadiness() async throws -> AdminSriReadiness { try await api.runReadiness().toDomain() }
    func getReadiness() async throws -> AdminSriReadiness { try await api.getReadiness().toDomain() }
    func startHomologation(reason: String) async throws -> AdminSriHomologationRun { try await api.startHomologation(AdminReasonRequestDTO(reason: reason)).run.toDomain() }
    func listHomologationRuns(limit: Int) async throws -> [AdminSriHomologationRun] { try await api.listHomologationRuns(limit: limit).runs.map { $0.toDomain() } }
    func requestProductionEnable(_ input: RequestProductionEnableInput) async throws -> AdminSriSettings { try await api.requestProductionEnable(RequestProductionEnableRequestDTO(confirmationText: input.confirmationText, reason: input.reason)).toDomain() }
}
