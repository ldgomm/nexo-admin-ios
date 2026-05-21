import Foundation

struct AdminTaxSettings: Equatable, Sendable {
    let organizationId: String
    let regimeCode: String
    let regimeName: String
    let defaultTaxProfileId: String?
    let defaultCurrency: String
    let obligatedToKeepAccounting: Bool
    let specialTaxpayerNumber: String?
    let rimpeLegend: String?
    let withholdingAgentResolution: String?
    let updatedAt: String?
    let version: Int
}

struct AdminTaxProfile: Identifiable, Equatable, Sendable {
    let id: String
    let code: String
    let name: String
    let description: String
    let status: String
    let taxName: String
    let rate: Decimal
    let sriTaxCode: String
    let sriRateCode: String
    let legalBasis: String?
    let effectiveFrom: String?
    let effectiveTo: String?
    let editable: Bool
}

struct AdminElectronicSignature: Identifiable, Equatable, Sendable {
    let id: String
    let organizationId: String
    let alias: String
    let subject: String
    let issuer: String
    let serialNumber: String
    let validFrom: String?
    let validTo: String?
    let status: String
    let isActive: Bool
    let expiresInDays: Int?
    let lastValidatedAt: String?
    let createdAt: String?
}

struct AdminSriSettings: Equatable, Sendable {
    let organizationId: String
    let environment: String
    let emissionType: String
    let authorizationMode: String
    let establishmentCode: String?
    let emissionPointCode: String?
    let productionEnabled: Bool
    let productionRequestedAt: String?
    let productionEnabledAt: String?
    let lastReadinessStatus: String?
    let updatedAt: String?
}

struct AdminSriReadiness: Equatable, Sendable {
    let status: String
    let score: Int
    let checkedAt: String
    let items: [AdminSriReadinessItem]
    let blockers: [String]
    let warnings: [String]

    var ready: Bool { status.lowercased() == "ready" || status.lowercased() == "ok" }
}

struct AdminSriReadinessItem: Identifiable, Equatable, Sendable {
    let id: String
    let code: String
    let title: String
    let description: String
    let status: String
    let required: Bool
    let actionLabel: String?
}

struct AdminSriHomologationRun: Identifiable, Equatable, Sendable {
    let id: String
    let status: String
    let environment: String
    let startedAt: String?
    let finishedAt: String?
    let invoiceAccessKey: String?
    let authorizationNumber: String?
    let errorMessage: String?
    let checklist: [AdminSriReadinessItem]
}

struct AdminTaxSriSummary: Equatable, Sendable {
    let taxSettings: AdminTaxSettings
    let taxProfiles: [AdminTaxProfile]
    let signatures: [AdminElectronicSignature]
    let sriSettings: AdminSriSettings
    let readiness: AdminSriReadiness
    let homologationRuns: [AdminSriHomologationRun]
}

struct UpdateAdminTaxSettingsInput: Equatable, Sendable {
    var regimeCode: String?
    var defaultTaxProfileId: String?
    var obligatedToKeepAccounting: Bool?
    var specialTaxpayerNumber: String?
    var clearSpecialTaxpayerNumber: Bool = false
    var rimpeLegend: String?
    var withholdingAgentResolution: String?
    var clearWithholdingAgentResolution: Bool = false
    var reason: String
}

struct UploadAdminElectronicSignatureInput: Equatable, Sendable {
    var alias: String
    var fileName: String
    var fileBase64: String
    var password: String
    var reason: String
}

struct AdminSignatureActionInput: Equatable, Sendable {
    var signatureId: String
    var reason: String
}

struct UpdateAdminSriSettingsInput: Equatable, Sendable {
    var environment: String?
    var emissionType: String?
    var authorizationMode: String?
    var establishmentCode: String?
    var emissionPointCode: String?
    var reason: String
}

struct RequestProductionEnableInput: Equatable, Sendable {
    var confirmationText: String
    var reason: String
}
