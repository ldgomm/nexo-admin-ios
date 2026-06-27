//
//  AdminBusinessDTOs.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import Foundation

struct AdminBusinessDTO: Decodable, Sendable {
    let id: String
    let countryCode: String
    let taxId: String
    let legalName: String
    let commercialName: String
    let status: String
    let ownerUserId: String
    let defaultCurrency: String?
    let timezone: String?
    let createdAt: String?
    let updatedAt: String?
    let version: Int
}

struct AdminBusinessEnvelopeDTO: Decodable, Sendable {
    let business: AdminBusinessDTO
}

struct UpdateAdminBusinessRequestDTO: Encodable, Sendable {
    let countryCode: String?
    let taxId: String?
    let legalName: String?
    let commercialName: String?
    let defaultCurrency: String?
    let timezone: String?
    let reason: String
}

struct AdminActivityDTO: Decodable, Sendable {
    let id: String
    let organizationId: String
    let code: String?
    let name: String
    let description: String?
    let activityType: String
    let workflowMode: String
    let status: String
    let requiresScheduling: Bool
    let tracksInventory: Bool
    let allowsReceivables: Bool
    let sortOrder: Int
    let createdAt: String?
    let updatedAt: String?
}

struct AdminActivityEnvelopeDTO: Decodable, Sendable {
    let activity: AdminActivityDTO
}

struct AdminActivitiesResponseDTO: Decodable, Sendable {
    let activities: [AdminActivityDTO]
}

struct CreateAdminActivityRequestDTO: Encodable, Sendable {
    let code: String
    let name: String
    let description: String?
    let activityType: String
    let workflowMode: String
    let status: String
    let requiresScheduling: Bool
    let tracksInventory: Bool
    let allowsReceivables: Bool
    let sortOrder: Int
    let reason: String
}

struct UpdateAdminActivityRequestDTO: Encodable, Sendable {
    let code: String?
    let name: String?
    let description: String?
    let clearDescription: Bool
    let activityType: String?
    let workflowMode: String?
    let requiresScheduling: Bool?
    let tracksInventory: Bool?
    let allowsReceivables: Bool?
    let sortOrder: Int?
    let reason: String
}

struct AdminBusinessActionRequestDTO: Encodable, Sendable {
    let reason: String
}

struct AdminBranchLocationDTO: Codable, Sendable {
    let countryCode: String?
    let province: String?
    let city: String?
    let sector: String?
    let addressLine: String?
    let latitude: Double?
    let longitude: Double?
    let privacyMode: String?
}

struct AdminBranchDTO: Decodable, Sendable {
    let id: String
    let organizationId: String
    let code: String?
    let name: String
    let type: String
    let status: String
    let location: AdminBranchLocationDTO?
    let businessHoursId: String?
    let createdAt: String?
    let updatedAt: String?
}

struct AdminBranchEnvelopeDTO: Decodable, Sendable {
    let branch: AdminBranchDTO
}

struct AdminBranchesResponseDTO: Decodable, Sendable {
    let branches: [AdminBranchDTO]
}

struct CreateAdminBranchRequestDTO: Encodable, Sendable {
    let code: String
    let name: String
    let type: String
    let status: String
    let location: AdminBranchLocationDTO?
    let businessHoursId: String?
    let reason: String
}

struct UpdateAdminBranchRequestDTO: Encodable, Sendable {
    let code: String?
    let name: String?
    let type: String?
    let location: AdminBranchLocationDTO?
    let clearLocation: Bool
    let businessHoursId: String?
    let clearBusinessHoursId: Bool
    let reason: String
}

struct AdminEmissionPointDTO: Decodable, Sendable {
    let id: String
    let organizationId: String
    let branchId: String
    let establishmentCode: String
    let emissionPointCode: String
    let fullCode: String
    let displayName: String
    let status: String
    let createdAt: String?
    let updatedAt: String?
}

struct AdminEmissionPointEnvelopeDTO: Decodable, Sendable {
    let emissionPoint: AdminEmissionPointDTO
}

struct AdminEmissionPointsResponseDTO: Decodable, Sendable {
    let emissionPoints: [AdminEmissionPointDTO]
}

struct CreateAdminEmissionPointRequestDTO: Encodable, Sendable {
    let branchId: String
    let establishmentCode: String
    let emissionPointCode: String
    let displayName: String
    let status: String
    let reason: String
}

struct UpdateAdminEmissionPointRequestDTO: Encodable, Sendable {
    let branchId: String?
    let establishmentCode: String?
    let emissionPointCode: String?
    let displayName: String?
    let reason: String
}

struct AdminBusinessReadinessResponseDTO: Decodable, Sendable {
    let organizationId: String
    let overallStatus: String
    let ready: Bool
    let generatedAt: String
    let checks: [AdminBusinessReadinessCheckDTO]
}

struct AdminBusinessReadinessCheckDTO: Decodable, Sendable {
    let code: String
    let status: String
    let required: Bool
    let message: String
    let action: String?
}

struct AdminRestaurantReadinessResponseDTO: Decodable, Sendable {
    let organizationId: String
    let branchId: String?
    let status: String
    let overallStatus: String
    let ready: Bool
    let surface: String
    let capabilities: [String]
    let supportMode: String
    let warnings: [String]
    let blockers: [String]
    let checks: [AdminRestaurantReadinessCheckDTO]
    let components: [AdminRestaurantReadinessComponentDTO]
    let tables: AdminRestaurantTableSummaryDTO?
    let supportLinks: [AdminRestaurantSupportLinkDTO]
}

struct AdminRestaurantReadinessCheckDTO: Decodable, Sendable {
    let code: String
    let status: String
    let message: String
    let blocking: Bool?
    let details: [String: String]?
}

struct AdminRestaurantReadinessComponentDTO: Decodable, Sendable {
    let code: String
    let status: String
    let path: String?
    let supportOnly: Bool?
    let details: [String: String]?
}

struct AdminRestaurantTableSummaryDTO: Decodable, Sendable {
    let total: Int
    let available: Int
    let occupied: Int
    let disabled: Int
    let openSessions: Int
}

struct AdminRestaurantSupportLinkDTO: Decodable, Sendable {
    let label: String
    let method: String
    let path: String
    let supportOnly: Bool?
}

struct AdminBusinessFoundationOverviewDTO: Decodable, Sendable {
    let organizationId: String
    let overallStatus: String
    let ready: Bool
    let generatedAt: String
    let business: AdminBusinessDTO
    let readiness: AdminBusinessReadinessResponseDTO
    let counts: AdminBusinessFoundationCountsDTO
    let nextActions: [AdminBusinessFoundationNextActionDTO]
    let activities: [AdminActivityDTO]
    let branches: [AdminBranchDTO]
    let emissionPoints: [AdminEmissionPointDTO]
}

struct AdminBusinessFoundationCountsDTO: Decodable, Sendable {
    let totalActivities: Int
    let activeActivities: Int
    let pausedActivities: Int
    let archivedActivities: Int
    let totalBranches: Int
    let activeBranches: Int
    let inactiveBranches: Int
    let archivedBranches: Int
    let totalEmissionPoints: Int
    let activeEmissionPoints: Int
    let inactiveEmissionPoints: Int
    let archivedEmissionPoints: Int
    let readinessChecks: Int
    let readyChecks: Int
    let warningChecks: Int
    let blockedChecks: Int
}

struct AdminBusinessFoundationNextActionDTO: Decodable, Sendable {
    let code: String
    let status: String
    let required: Bool
    let action: String
}
