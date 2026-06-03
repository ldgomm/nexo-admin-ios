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
    let taxKind: String
    let treatment: String
    let rate: Decimal
    let sriTaxCode: String
    let sriRateCode: String
    let legalBasis: String?
    let effectiveFrom: String?
    let effectiveTo: String?
    let editable: Bool
    let source: String?
    let requiresTourismEligibility: Bool
    let requiresConstructionMaterialAuxiliaryCode: Bool
    let requiresActiveWindow: Bool
    let eligibilityWindowCode: String?

    var displayRate: String {
        "\(NSDecimalNumber(decimal: rate).stringValue)%"
    }

    var displaySriCodes: String {
        let taxCode = sriTaxCode.trimmingCharacters(in: .whitespacesAndNewlines)
        let rateCode = sriRateCode.trimmingCharacters(in: .whitespacesAndNewlines)

        if taxCode.isEmpty && rateCode.isEmpty {
            return "Sin códigos SRI"
        }
        if taxCode.isEmpty {
            return "SRI —/\(rateCode)"
        }
        if rateCode.isEmpty {
            return "SRI \(taxCode)/—"
        }
        return "SRI \(taxCode)/\(rateCode)"
    }

    var normalizedTreatment: String {
        treatment.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    }

    var normalizedCode: String {
        code.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    var isTourismReducedIva: Bool {
        normalizedTreatment == "IVA_REDUCED_TOURISM" || normalizedCode.contains("tourism")
    }

    var isConstructionReducedIva: Bool {
        normalizedTreatment == "IVA_REDUCED_CONSTRUCTION_MATERIALS" || normalizedCode.contains("construction")
    }

    var isInternalOnly: Bool {
        normalizedTreatment == "NO_TAX_INTERNAL" || normalizedCode.contains("no_tax_internal")
    }

    var isElectronicallyBillable: Bool {
        !isInternalOnly && !sriTaxCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var requiresEligibilityNotice: Bool {
        requiresTourismEligibility || requiresConstructionMaterialAuxiliaryCode || requiresActiveWindow
    }

    var eligibilitySummary: String? {
        var items: [String] = []
        if requiresTourismEligibility {
            items.append("requiere elegibilidad turística")
        }
        if requiresConstructionMaterialAuxiliaryCode {
            items.append("requiere código auxiliar de material")
        }
        if requiresActiveWindow {
            items.append("requiere ventana/decreto vigente")
        }
        if let eligibilityWindowCode, !eligibilityWindowCode.isEmpty {
            items.append("ventana: \(eligibilityWindowCode)")
        }
        return items.isEmpty ? nil : items.joined(separator: " • ")
    }
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
    let effectiveStatus: String
    let usable: Bool
    let expiresInDays: Int?
    let expiresSoon: Bool
    let uploadedBy: String?
    let uploadedAt: String?
    let lastUsedAt: String?
    let lastValidatedAt: String?
    let createdAt: String?

    var isActive: Bool {
        if usable { return true }

        let normalizedStatus = status.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        let normalizedEffectiveStatus = effectiveStatus.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        return normalizedStatus == "ACTIVE"
            || normalizedStatus == "VALID"
            || normalizedEffectiveStatus == "ACTIVE"
            || normalizedEffectiveStatus == "VALID"
    }
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
