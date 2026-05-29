//
//  AdminFoundationDTOs.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import Foundation

struct BusinessContextResponseDTO: Decodable, Sendable {
    let user: BusinessContextUserResponseDTO
    let organization: BusinessContextOrganizationResponseDTO
    let branches: [BusinessContextBranchResponseDTO]
    let activeBranchId: String?
    let activities: [BusinessContextActivityResponseDTO]
    let activeModules: [String]
    let effectivePermissions: [String]
    let catalogRevision: String
    let taxConfigurationRevision: String
    let realtime: BusinessContextRealtimeResponseDTO
}

struct BusinessContextUserResponseDTO: Decodable, Sendable {
    let id: String
    let displayName: String
    let email: String
}

struct BusinessContextOrganizationResponseDTO: Decodable, Sendable {
    let id: String
    let legalName: String
    let commercialName: String
    let countryCode: String
    let taxId: String
    let defaultCurrency: String
    let timezone: String
}

struct BusinessContextBranchResponseDTO: Decodable, Sendable {
    let id: String
    let code: String
    let name: String
    let type: String
    let status: String
    let main: Bool
}

struct BusinessContextActivityResponseDTO: Decodable, Sendable {
    let id: String
    let activityType: String
    let workflowMode: String
    let status: String
    let requiresScheduling: Bool
}

struct BusinessContextRealtimeResponseDTO: Decodable, Sendable {
    let enabled: Bool
    let sseUrl: String
}

struct ModulesResponseDTO: Decodable, Sendable {
    let organizationId: String
    let modules: [ResolvedModuleResponseDTO]
}

struct ResolvedModuleResponseDTO: Decodable, Sendable {
    let code: String
    let name: String
    let category: String
    let status: String
    let active: Bool
    let source: String
    let dependencies: [String]
    let compatibleActivityTypes: [String]
    let defaultWorkflowModes: [String]
    let permissions: [String]
    let screens: [String]
    let events: [String]
    let blockedReasons: [String]
}

struct ModuleReadinessResponseDTO: Decodable, Sendable {
    let organizationId: String
    let readiness: [ModuleReadinessItemResponseDTO]
}

struct ModuleReadinessItemResponseDTO: Decodable, Sendable {
    let code: String
    let ready: Bool
    let active: Bool
    let missingDependencies: [String]
    let warnings: [String]
    let blockers: [String]
}

struct ModuleToggleRequestDTO: Encodable, Sendable {
    let reason: String
}
