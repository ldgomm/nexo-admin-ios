import Combine
import Foundation

@MainActor
final class AdminTaxSriViewModel: ObservableObject {
    @Published private(set) var isLoading = false
    @Published private(set) var isMutating = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published private(set) var taxSettings: AdminTaxSettings?
    @Published private(set) var taxProfiles: [AdminTaxProfile] = []
    @Published private(set) var signatures: [AdminElectronicSignature] = []
    @Published private(set) var sriSettings: AdminSriSettings?
    @Published private(set) var readiness: AdminSriReadiness?
    @Published private(set) var homologationRuns: [AdminSriHomologationRun] = []

    private let repository: any AdminTaxSriRepository
    private let loadSummary: LoadAdminTaxSriSummaryUseCase
    private let runReadinessUseCase: RunAdminSriReadinessUseCase
    private let startHomologationUseCase: StartAdminSriHomologationUseCase
    private let requestProductionUseCase: RequestAdminSriProductionEnableUseCase

    init(repository: any AdminTaxSriRepository) {
        self.repository = repository
        self.loadSummary = LoadAdminTaxSriSummaryUseCase(repository: repository)
        self.runReadinessUseCase = RunAdminSriReadinessUseCase(repository: repository)
        self.startHomologationUseCase = StartAdminSriHomologationUseCase(repository: repository)
        self.requestProductionUseCase = RequestAdminSriProductionEnableUseCase(repository: repository)
    }

    var activeSignature: AdminElectronicSignature? { signatures.first { $0.isActive } }
    var hasSignatureExpiringSoon: Bool { signatures.contains { ($0.expiresInDays ?? 999) <= 30 } }
    var hasReadinessBlockers: Bool { !(readiness?.blockers.isEmpty ?? true) }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let summary = try await loadSummary.execute()
            apply(summary)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func refresh() async { await load() }

    func updateTaxSettings(_ input: UpdateAdminTaxSettingsInput) async {
        await mutate(success: "Configuración tributaria actualizada.") {
            taxSettings = try await repository.updateTaxSettings(input)
        }
    }

    func updateSriSettings(_ input: UpdateAdminSriSettingsInput) async {
        await mutate(success: "Configuración SRI actualizada.") {
            sriSettings = try await repository.updateSriSettings(input)
        }
    }

    func uploadSignature(alias: String, fileName: String, fileData: Data, password: String, reason: String) async {
        let input = UploadAdminElectronicSignatureInput(
            alias: alias,
            fileName: fileName,
            fileBase64: fileData.base64EncodedString(),
            password: password,
            reason: reason
        )
        await mutate(success: "Firma electrónica subida de forma segura.") {
            let signature = try await repository.uploadSignature(input)
            upsertSignature(signature)
        }
    }

    func validateSignature(id: String, reason: String) async {
        await mutate(success: "Firma validada.") {
            let signature = try await repository.validateSignature(AdminSignatureActionInput(signatureId: id, reason: reason))
            upsertSignature(signature)
        }
    }

    func activateSignature(id: String, reason: String) async {
        await mutate(success: "Firma activa actualizada.") {
            let signature = try await repository.activateSignature(AdminSignatureActionInput(signatureId: id, reason: reason))
            signatures = try await repository.listSignatures()
            upsertSignature(signature)
        }
    }

    func revokeSignature(id: String, reason: String) async {
        await mutate(success: "Firma revocada.") {
            let signature = try await repository.revokeSignature(AdminSignatureActionInput(signatureId: id, reason: reason))
            upsertSignature(signature)
        }
    }

    func runReadiness() async {
        await mutate(success: "Readiness SRI ejecutado.") {
            readiness = try await runReadinessUseCase.execute()
        }
    }

    func startHomologation(reason: String) async {
        await mutate(success: "Homologación iniciada.") {
            let run = try await startHomologationUseCase.execute(reason: reason)
            homologationRuns.insert(run, at: 0)
        }
    }

    func requestProductionEnable(confirmationText: String, reason: String) async {
        guard confirmationText == "HABILITAR PRODUCCION" else {
            errorMessage = "La confirmación debe decir exactamente: HABILITAR PRODUCCION"
            return
        }
        await mutate(success: "Solicitud de producción enviada al backend.") {
            sriSettings = try await requestProductionUseCase.execute(RequestProductionEnableInput(confirmationText: confirmationText, reason: reason))
        }
    }

    private func apply(_ summary: AdminTaxSriSummary) {
        taxSettings = summary.taxSettings
        taxProfiles = summary.taxProfiles
        signatures = summary.signatures
        sriSettings = summary.sriSettings
        readiness = summary.readiness
        homologationRuns = summary.homologationRuns
    }

    private func mutate(success: String, operation: () async throws -> Void) async {
        isMutating = true
        errorMessage = nil
        successMessage = nil
        defer { isMutating = false }
        do {
            try await operation()
            successMessage = success
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func upsertSignature(_ signature: AdminElectronicSignature) {
        if let index = signatures.firstIndex(where: { $0.id == signature.id }) {
            signatures[index] = signature
        } else {
            signatures.insert(signature, at: 0)
        }
    }
}
