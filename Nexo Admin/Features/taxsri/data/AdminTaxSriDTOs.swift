//
//  AdminTaxSriDTOs.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
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

struct AdminTaxProfileResponseDTO: Decodable, Sendable {
    let id: String
    let code: String
    let name: String
    let description: String?
    let status: String?
    let taxName: String?
    let rate: String?
    let sriTaxCode: String?
    let sriRateCode: String?
    let legalBasis: String?
    let effectiveFrom: String?
    let effectiveTo: String?
    let editable: Bool?
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
    let isActive: Bool?
    let expiresInDays: Int?
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
    let checklist: [AdminSriReadinessItemResponseDTO]?
}

struct AdminReasonRequestDTO: Encodable, Sendable { let reason: String }
struct RequestProductionEnableRequestDTO: Encodable, Sendable { let confirmationText: String; let reason: String }
