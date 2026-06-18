//
//  AdminTaxSriViewModel.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

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
            errorMessage = humanizedTaxSriError(error)
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
        let cleanAlias = alias.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanFileName = fileName.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanReason = reason.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleanAlias.isEmpty else {
            errorMessage = "Ingresa un alias para identificar la firma."
            return
        }

        guard cleanFileName.lowercased().hasSuffix(".p12") || cleanFileName.lowercased().hasSuffix(".pfx") else {
            errorMessage = "Selecciona un archivo de firma .p12 o .pfx."
            return
        }

        guard !fileData.isEmpty else {
            errorMessage = "El archivo de firma está vacío."
            return
        }

        guard !password.isEmpty else {
            errorMessage = "Ingresa la contraseña de la firma."
            return
        }

        guard !cleanReason.isEmpty else {
            errorMessage = "Ingresa un motivo de auditoría."
            return
        }

        let input = UploadAdminElectronicSignatureInput(
            alias: cleanAlias,
            fileName: cleanFileName,
            fileBase64: fileData.base64EncodedString(),
            password: password,
            reason: cleanReason
        )
        await mutate(success: "Firma electrónica cargada. Valídala antes de activarla.") {
            let signature = try await repository.uploadSignature(input)
            upsertSignature(signature)
        }
    }

    func validateSignature(id: String, reason: String) async {
        guard let signature = signatures.first(where: { $0.id == id }), signature.canValidate else {
            errorMessage = "Esta firma no está en un estado que permita validarla."
            return
        }

        await mutate(success: "Firma validada. Puedes activarla si será la firma principal.") {
            let signature = try await repository.validateSignature(AdminSignatureActionInput(signatureId: id, reason: reason))
            upsertSignature(signature)
        }
    }

    func activateSignature(id: String, reason: String) async {
        guard let signature = signatures.first(where: { $0.id == id }), signature.canActivate else {
            errorMessage = "Solo una firma válida puede activarse."
            return
        }

        await mutate(success: "Firma activa actualizada.") {
            let signature = try await repository.activateSignature(AdminSignatureActionInput(signatureId: id, reason: reason))
            signatures = try await repository.listSignatures()
            upsertSignature(signature)
        }
    }

    func revokeSignature(id: String, reason: String) async {
        guard let signature = signatures.first(where: { $0.id == id }), signature.canRevoke else {
            errorMessage = "Esta firma ya no puede revocarse desde su estado actual."
            return
        }

        await mutate(success: "Firma revocada. Carga una nueva si necesitas emitir comprobantes.") {
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
        await mutate(success: "Prueba de emisión iniciada.") {
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
            errorMessage = humanizedTaxSriError(error)
        }
    }



    private func humanizedTaxSriError(_ error: Error) -> String {
        let message = error.localizedDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalized = message.lowercased()

        if normalized.contains("at least one homologation scenario is required")
            || normalized.contains("homologation scenario")
            || normalized.contains("no hay pruebas de emisión configuradas")
            || normalized.contains("escenarios automáticos de homologación") {
            return "No hay pruebas de emisión configuradas. El backend todavía no tiene escenarios automáticos para ejecutar esta prueba desde Admin. Esto no es un problema de tu firma ni del SRI."
        }

        if normalized.contains("an active electronic signature is required")
            || normalized.contains("active electronic signature") {
            return "Falta una firma electrónica activa. Carga, valida y activa una firma vigente antes de probar la emisión."
        }

        if normalized.contains("test environment")
            || normalized.contains("only while organization sri settings are in test") {
            return "La prueba de emisión solo puede ejecutarse en ambiente de pruebas del SRI. Revisa la configuración SRI antes de continuar."
        }

        if normalized.contains("sri settings are required") {
            return "Falta completar la configuración SRI del negocio antes de probar la emisión."
        }

        return message.isEmpty ? "No se pudo completar la operación." : message
    }

    private func upsertSignature(_ signature: AdminElectronicSignature) {
        if let index = signatures.firstIndex(where: { $0.id == signature.id }) {
            signatures[index] = signature
        } else {
            signatures.insert(signature, at: 0)
        }
    }
}
