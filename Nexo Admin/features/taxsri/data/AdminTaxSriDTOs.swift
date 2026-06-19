//
//  AdminTaxSriDTOs.swift
//  Nexo Admin
//
//  Created by José Ruiz on 2/6/26.
//

import Foundation

struct AdminTaxSettingsResponseDTO: Decodable, Sendable {
    let organizationId: String
    let regimeCode: String?
    let regimeName: String?
    let defaultTaxProfileId: String?
    let defaultCurrency: String?
    let obligatedToKeepAccounting: Bool?
    let specialTaxpayerNumber: String?
    let rimpeLegend: String?
    let withholdingAgentResolution: String?
    let updatedAt: String?
    let version: Int?
}

struct UpdateAdminTaxSettingsRequestDTO: Encodable, Sendable {
    let regimeCode: String?
    let defaultTaxProfileId: String?
    let obligatedToKeepAccounting: Bool?
    let specialTaxpayerNumber: String?
    let clearSpecialTaxpayerNumber: Bool
    let rimpeLegend: String?
    let withholdingAgentResolution: String?
    let clearWithholdingAgentResolution: Bool
    let reason: String
}

struct AdminTaxProfilesResponseDTO: Decodable, Sendable { let profiles: [AdminTaxProfileResponseDTO] }
struct AdminTaxProfileEnvelopeDTO: Decodable, Sendable { let profile: AdminTaxProfileResponseDTO }

struct AdminTaxRateEmbeddedDTO: Decodable, Sendable {
    let id: String?
    let organizationId: String?
    let countryCode: String?
    let code: String?
    let name: String?
    let kind: String?
    let taxKind: String?
    let treatment: String?
    let taxTreatment: String?
    let rate: String?
    let status: String?
    let sriTaxCode: String?
    let sriRateCode: String?
    let legalBasis: String?
    let effectiveFrom: String?
    let effectiveTo: String?
    let source: String?
    let requiresTourismEligibility: Bool?
    let requiresConstructionMaterialAuxiliaryCode: Bool?
    let requiresActiveWindow: Bool?
    let eligibilityWindowCode: String?
    let createdAt: String?
    let updatedAt: String?
    let version: Int?
    let schemaVersion: Int?

    private enum CodingKeys: String, CodingKey {
        case id
        case mongoId = "_id"
        case organizationId
        case countryCode
        case code
        case name
        case kind
        case taxKind
        case treatment
        case taxTreatment
        case rate
        case status
        case sriTaxCode
        case sriRateCode
        case legalBasis
        case effectiveFrom
        case effectiveTo
        case source
        case requiresTourismEligibility
        case requiresConstructionMaterialAuxiliaryCode
        case requiresActiveWindow
        case eligibilityWindowCode
        case createdAt
        case updatedAt
        case version
        case schemaVersion
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id)
            ?? container.decodeIfPresent(String.self, forKey: .mongoId)
        organizationId = try container.decodeIfPresent(String.self, forKey: .organizationId)
        countryCode = try container.decodeIfPresent(String.self, forKey: .countryCode)
        code = try container.decodeIfPresent(String.self, forKey: .code)
        name = try container.decodeIfPresent(String.self, forKey: .name)
        kind = try container.decodeIfPresent(String.self, forKey: .kind)
        taxKind = try container.decodeIfPresent(String.self, forKey: .taxKind)
        treatment = try container.decodeIfPresent(String.self, forKey: .treatment)
        taxTreatment = try container.decodeIfPresent(String.self, forKey: .taxTreatment)
        rate = try container.decodeFlexibleStringIfPresent(forKey: .rate)
        status = try container.decodeIfPresent(String.self, forKey: .status)
        sriTaxCode = try container.decodeFlexibleStringIfPresent(forKey: .sriTaxCode)
        sriRateCode = try container.decodeFlexibleStringIfPresent(forKey: .sriRateCode)
        legalBasis = try container.decodeIfPresent(String.self, forKey: .legalBasis)
        effectiveFrom = try container.decodeIfPresent(String.self, forKey: .effectiveFrom)
        effectiveTo = try container.decodeIfPresent(String.self, forKey: .effectiveTo)
        source = try container.decodeIfPresent(String.self, forKey: .source)
        requiresTourismEligibility = try container.decodeIfPresent(Bool.self, forKey: .requiresTourismEligibility)
        requiresConstructionMaterialAuxiliaryCode = try container.decodeIfPresent(Bool.self, forKey: .requiresConstructionMaterialAuxiliaryCode)
        requiresActiveWindow = try container.decodeIfPresent(Bool.self, forKey: .requiresActiveWindow)
        eligibilityWindowCode = try container.decodeIfPresent(String.self, forKey: .eligibilityWindowCode)
        createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(String.self, forKey: .updatedAt)
        version = try container.decodeIfPresent(Int.self, forKey: .version)
        schemaVersion = try container.decodeIfPresent(Int.self, forKey: .schemaVersion)
    }
}

struct AdminTaxProfileResponseDTO: Decodable, Sendable {
    let id: String
    let code: String
    let name: String
    let description: String?
    let status: String?
    let taxName: String?
    let taxKind: String?
    let kind: String?
    let treatment: String?
    let taxTreatment: String?
    let rate: String?
    let sriTaxCode: String?
    let sriRateCode: String?
    let legalBasis: String?
    let effectiveFrom: String?
    let effectiveTo: String?
    let editable: Bool?
    let source: String?
    let requiresTourismEligibility: Bool?
    let requiresConstructionMaterialAuxiliaryCode: Bool?
    let requiresActiveWindow: Bool?
    let eligibilityWindowCode: String?
    let taxRate: AdminTaxRateEmbeddedDTO?

    private enum CodingKeys: String, CodingKey {
        case id
        case mongoId = "_id"
        case code
        case name
        case description
        case status
        case taxName
        case taxKind
        case kind
        case treatment
        case taxTreatment
        case rate
        case sriTaxCode
        case sriRateCode
        case legalBasis
        case effectiveFrom
        case effectiveTo
        case editable
        case source
        case requiresTourismEligibility
        case requiresConstructionMaterialAuxiliaryCode
        case requiresActiveWindow
        case eligibilityWindowCode
        case taxRate
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id)
            ?? container.decode(String.self, forKey: .mongoId)
        code = try container.decode(String.self, forKey: .code)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        status = try container.decodeIfPresent(String.self, forKey: .status)
        taxName = try container.decodeIfPresent(String.self, forKey: .taxName)
        taxKind = try container.decodeIfPresent(String.self, forKey: .taxKind)
        kind = try container.decodeIfPresent(String.self, forKey: .kind)
        treatment = try container.decodeIfPresent(String.self, forKey: .treatment)
        taxTreatment = try container.decodeIfPresent(String.self, forKey: .taxTreatment)
        rate = try container.decodeFlexibleStringIfPresent(forKey: .rate)
        sriTaxCode = try container.decodeFlexibleStringIfPresent(forKey: .sriTaxCode)
        sriRateCode = try container.decodeFlexibleStringIfPresent(forKey: .sriRateCode)
        legalBasis = try container.decodeIfPresent(String.self, forKey: .legalBasis)
        effectiveFrom = try container.decodeIfPresent(String.self, forKey: .effectiveFrom)
        effectiveTo = try container.decodeIfPresent(String.self, forKey: .effectiveTo)
        editable = try container.decodeIfPresent(Bool.self, forKey: .editable)
        source = try container.decodeIfPresent(String.self, forKey: .source)
        requiresTourismEligibility = try container.decodeIfPresent(Bool.self, forKey: .requiresTourismEligibility)
        requiresConstructionMaterialAuxiliaryCode = try container.decodeIfPresent(Bool.self, forKey: .requiresConstructionMaterialAuxiliaryCode)
        requiresActiveWindow = try container.decodeIfPresent(Bool.self, forKey: .requiresActiveWindow)
        eligibilityWindowCode = try container.decodeIfPresent(String.self, forKey: .eligibilityWindowCode)
        taxRate = try container.decodeIfPresent(AdminTaxRateEmbeddedDTO.self, forKey: .taxRate)
    }
}

struct AdminElectronicSignaturesResponseDTO: Decodable, Sendable { let signatures: [AdminElectronicSignatureResponseDTO] }
struct AdminElectronicSignatureEnvelopeDTO: Decodable, Sendable { let signature: AdminElectronicSignatureResponseDTO }

struct AdminElectronicSignatureResponseDTO: Decodable, Sendable {
    let id: String
    let organizationId: String?
    let alias: String?
    let subject: String?
    let issuer: String?
    let serialNumber: String?
    let validFrom: String?
    let validTo: String?
    let status: String?
    let effectiveStatus: String?
    let isActive: Bool?
    let usable: Bool?
    let daysUntilExpiration: Int?
    let expiresInDays: Int?
    let expiresSoon: Bool?
    let uploadedBy: String?
    let uploadedAt: String?
    let lastUsedAt: String?
    let lastValidatedAt: String?
    let createdAt: String?
}

struct UploadAdminElectronicSignatureRequestDTO: Encodable, Sendable {
    let alias: String
    let fileName: String
    let fileBase64: String
    let password: String
    let reason: String
}

struct AdminSignatureActionRequestDTO: Encodable, Sendable { let reason: String }

struct AdminSriSettingsResponseDTO: Decodable, Sendable {
    let organizationId: String
    let environment: String?
    let emissionType: String?
    let authorizationMode: String?
    let establishmentCode: String?
    let emissionPointCode: String?
    let productionEnabled: Bool?
    let productionRequestedAt: String?
    let productionEnabledAt: String?
    let lastReadinessStatus: String?
    let updatedAt: String?
}

struct UpdateAdminSriSettingsRequestDTO: Encodable, Sendable {
    let environment: String?
    let emissionType: String?
    let authorizationMode: String?
    let establishmentCode: String?
    let emissionPointCode: String?
    let reason: String
}

struct AdminSriReadinessResponseDTO: Decodable, Sendable {
    let status: String?
    let score: Int?
    let checkedAt: String?
    let items: [AdminSriReadinessItemResponseDTO]?
    let blockers: [String]?
    let warnings: [String]?
}

struct AdminSriReadinessItemResponseDTO: Decodable, Sendable {
    let id: String?
    let code: String?
    let title: String?
    let description: String?
    let status: String?
    let required: Bool?
    let actionLabel: String?
}

struct AdminSriHomologationRunsResponseDTO: Decodable, Sendable { let runs: [AdminSriHomologationRunResponseDTO] }
struct AdminSriHomologationRunEnvelopeDTO: Decodable, Sendable { let run: AdminSriHomologationRunResponseDTO }

struct AdminSriHomologationRunResponseDTO: Decodable, Sendable {
    let id: String
    let status: String?
    let environment: String?
    let startedAt: String?
    let finishedAt: String?
    let invoiceAccessKey: String?
    let authorizationNumber: String?
    let errorMessage: String?
    let documentId: String?
    let saleId: String?
    let finalDocumentStatus: String?
    let artifactTypes: [String]?
    let checklist: [AdminSriReadinessItemResponseDTO]?
}

struct AdminReasonRequestDTO: Encodable, Sendable { let reason: String }
struct RequestProductionEnableRequestDTO: Encodable, Sendable { let confirmationText: String; let reason: String }

private extension KeyedDecodingContainer {
    func decodeFlexibleStringIfPresent(forKey key: Key) throws -> String? {
        if let value = try decodeIfPresent(String.self, forKey: key) {
            return value
        }
        if let value = try decodeIfPresent(Int.self, forKey: key) {
            return String(value)
        }
        if let value = try decodeIfPresent(Double.self, forKey: key) {
            return Decimal(value).description
        }
        if let value = try decodeIfPresent(Decimal.self, forKey: key) {
            return value.description
        }
        return nil
    }
}
