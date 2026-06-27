//
//  AdminBusinessMapper.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import Foundation

enum AdminBusinessMapper {
    static func map(_ dto: AdminBusinessDTO) -> AdminBusinessProfile {
        AdminBusinessProfile(
            id: dto.id,
            countryCode: dto.countryCode,
            taxId: dto.taxId,
            legalName: dto.legalName,
            commercialName: dto.commercialName,
            status: AdminBusinessStatus(apiValue: dto.status),
            ownerUserId: dto.ownerUserId,
            defaultCurrency: dto.defaultCurrency,
            timezone: dto.timezone,
            createdAt: dto.createdAt,
            updatedAt: dto.updatedAt,
            version: dto.version
        )
    }

    static func map(_ dto: AdminActivityDTO) -> AdminBusinessActivity {
        AdminBusinessActivity(
            id: dto.id,
            organizationId: dto.organizationId,
            code: dto.code,
            name: dto.name,
            description: dto.description,
            activityType: dto.activityType,
            workflowMode: dto.workflowMode,
            status: AdminActivityStatus(apiValue: dto.status),
            requiresScheduling: dto.requiresScheduling,
            tracksInventory: dto.tracksInventory,
            allowsReceivables: dto.allowsReceivables,
            sortOrder: dto.sortOrder,
            createdAt: dto.createdAt,
            updatedAt: dto.updatedAt
        )
    }

    static func map(_ dto: AdminBranchLocationDTO?) -> AdminBranchLocation? {
        guard let dto else { return nil }
        return AdminBranchLocation(
            countryCode: dto.countryCode,
            province: dto.province,
            city: dto.city,
            sector: dto.sector,
            addressLine: dto.addressLine,
            latitude: dto.latitude,
            longitude: dto.longitude,
            privacyMode: dto.privacyMode
        )
    }

    static func map(_ dto: AdminBranchDTO) -> AdminBusinessBranch {
        AdminBusinessBranch(
            id: dto.id,
            organizationId: dto.organizationId,
            code: dto.code,
            name: dto.name,
            type: dto.type,
            status: AdminBranchStatus(apiValue: dto.status),
            location: map(dto.location),
            businessHoursId: dto.businessHoursId,
            createdAt: dto.createdAt,
            updatedAt: dto.updatedAt
        )
    }

    static func map(_ dto: AdminEmissionPointDTO) -> AdminEmissionPoint {
        AdminEmissionPoint(
            id: dto.id,
            organizationId: dto.organizationId,
            branchId: dto.branchId,
            establishmentCode: dto.establishmentCode,
            emissionPointCode: dto.emissionPointCode,
            fullCode: dto.fullCode,
            displayName: dto.displayName,
            status: AdminEmissionPointStatus(apiValue: dto.status),
            createdAt: dto.createdAt,
            updatedAt: dto.updatedAt
        )
    }

    static func map(_ dto: AdminBusinessReadinessCheckDTO) -> AdminBusinessReadinessCheck {
        AdminBusinessReadinessCheck(
            code: dto.code,
            status: AdminReadinessStatus(apiValue: dto.status),
            required: dto.required,
            message: dto.message,
            action: dto.action
        )
    }

    static func map(_ dto: AdminBusinessReadinessResponseDTO) -> AdminBusinessReadiness {
        AdminBusinessReadiness(
            organizationId: dto.organizationId,
            overallStatus: AdminReadinessStatus(apiValue: dto.overallStatus),
            ready: dto.ready,
            generatedAt: dto.generatedAt,
            checks: dto.checks.map(map(_:))
        )
    }

    static func map(_ dto: AdminRestaurantReadinessCheckDTO) -> AdminRestaurantReadinessCheck {
        AdminRestaurantReadinessCheck(
            code: dto.code,
            status: AdminRestaurantReadinessStatus(apiValue: dto.status),
            message: dto.message,
            blocking: dto.blocking ?? false,
            details: dto.details ?? [:]
        )
    }

    static func map(_ dto: AdminRestaurantReadinessComponentDTO) -> AdminRestaurantReadinessComponent {
        AdminRestaurantReadinessComponent(
            code: dto.code,
            status: AdminRestaurantReadinessStatus(apiValue: dto.status),
            path: dto.path,
            supportOnly: dto.supportOnly ?? false,
            details: dto.details ?? [:]
        )
    }

    static func map(_ dto: AdminRestaurantTableSummaryDTO?) -> AdminRestaurantTableSummary? {
        guard let dto else { return nil }
        return AdminRestaurantTableSummary(
            total: dto.total,
            available: dto.available,
            occupied: dto.occupied,
            disabled: dto.disabled,
            openSessions: dto.openSessions
        )
    }

    static func map(_ dto: AdminRestaurantSupportLinkDTO) -> AdminRestaurantSupportLink {
        AdminRestaurantSupportLink(
            label: dto.label,
            method: dto.method,
            path: dto.path,
            supportOnly: dto.supportOnly ?? false
        )
    }

    static func map(_ dto: AdminRestaurantReadinessResponseDTO) -> AdminRestaurantReadiness {
        AdminRestaurantReadiness(
            organizationId: dto.organizationId,
            branchId: dto.branchId,
            status: AdminRestaurantReadinessStatus(apiValue: dto.status),
            overallStatus: AdminRestaurantReadinessStatus(apiValue: dto.overallStatus),
            ready: dto.ready,
            surface: dto.surface,
            capabilities: dto.capabilities,
            supportMode: dto.supportMode,
            warnings: dto.warnings,
            blockers: dto.blockers,
            checks: dto.checks.map(map(_:)),
            components: dto.components.map(map(_:)),
            tables: map(dto.tables),
            supportLinks: dto.supportLinks.map(map(_:))
        )
    }

    static func map(_ dto: AdminBusinessFoundationCountsDTO) -> AdminBusinessFoundationCounts {
        AdminBusinessFoundationCounts(
            totalActivities: dto.totalActivities,
            activeActivities: dto.activeActivities,
            pausedActivities: dto.pausedActivities,
            archivedActivities: dto.archivedActivities,
            totalBranches: dto.totalBranches,
            activeBranches: dto.activeBranches,
            inactiveBranches: dto.inactiveBranches,
            archivedBranches: dto.archivedBranches,
            totalEmissionPoints: dto.totalEmissionPoints,
            activeEmissionPoints: dto.activeEmissionPoints,
            inactiveEmissionPoints: dto.inactiveEmissionPoints,
            archivedEmissionPoints: dto.archivedEmissionPoints,
            readinessChecks: dto.readinessChecks,
            readyChecks: dto.readyChecks,
            warningChecks: dto.warningChecks,
            blockedChecks: dto.blockedChecks
        )
    }

    static func map(_ dto: AdminBusinessFoundationNextActionDTO) -> AdminBusinessNextAction {
        AdminBusinessNextAction(
            code: dto.code,
            status: AdminReadinessStatus(apiValue: dto.status),
            required: dto.required,
            action: dto.action
        )
    }

    static func map(_ dto: AdminBusinessFoundationOverviewDTO) -> AdminBusinessOverview {
        AdminBusinessOverview(
            organizationId: dto.organizationId,
            overallStatus: AdminReadinessStatus(apiValue: dto.overallStatus),
            ready: dto.ready,
            generatedAt: dto.generatedAt,
            business: map(dto.business),
            readiness: map(dto.readiness),
            counts: map(dto.counts),
            nextActions: dto.nextActions.map(map(_:)),
            activities: dto.activities.map(map(_:)),
            branches: dto.branches.map(map(_:)),
            emissionPoints: dto.emissionPoints.map(map(_:))
        )
    }

    static func request(_ input: UpdateAdminBusinessProfileInput) -> UpdateAdminBusinessRequestDTO {
        UpdateAdminBusinessRequestDTO(
            countryCode: input.countryCode.cleanedForAPI,
            taxId: input.taxId.cleanedForAPI,
            legalName: input.legalName.cleanedForAPI,
            commercialName: input.commercialName.cleanedForAPI,
            defaultCurrency: input.defaultCurrency.cleanedForAPI,
            timezone: input.timezone.cleanedForAPI,
            reason: input.reason
        )
    }

    static func createRequest(_ input: SaveAdminActivityInput) -> CreateAdminActivityRequestDTO {
        CreateAdminActivityRequestDTO(
            code: input.code,
            name: input.name,
            description: input.description.cleanedForAPI,
            activityType: input.activityType,
            workflowMode: input.workflowMode,
            status: input.status,
            requiresScheduling: input.requiresScheduling,
            tracksInventory: input.tracksInventory,
            allowsReceivables: input.allowsReceivables,
            sortOrder: input.sortOrder,
            reason: input.reason
        )
    }

    static func updateRequest(_ input: SaveAdminActivityInput) -> UpdateAdminActivityRequestDTO {
        UpdateAdminActivityRequestDTO(
            code: input.code.cleanedForAPI,
            name: input.name.cleanedForAPI,
            description: input.description.cleanedForAPI,
            clearDescription: input.description?.trimmedOrNil == nil,
            activityType: input.activityType.cleanedForAPI,
            workflowMode: input.workflowMode.cleanedForAPI,
            requiresScheduling: input.requiresScheduling,
            tracksInventory: input.tracksInventory,
            allowsReceivables: input.allowsReceivables,
            sortOrder: input.sortOrder,
            reason: input.reason
        )
    }

    static func request(_ location: AdminBranchLocation?) -> AdminBranchLocationDTO? {
        guard let location else { return nil }
        return AdminBranchLocationDTO(
            countryCode: location.countryCode.cleanedForAPI,
            province: location.province.cleanedForAPI,
            city: location.city.cleanedForAPI,
            sector: location.sector.cleanedForAPI,
            addressLine: location.addressLine.cleanedForAPI,
            latitude: location.latitude,
            longitude: location.longitude,
            privacyMode: location.privacyMode.cleanedForAPI
        )
    }

    static func createRequest(_ input: SaveAdminBranchInput) -> CreateAdminBranchRequestDTO {
        CreateAdminBranchRequestDTO(
            code: input.code,
            name: input.name,
            type: input.type,
            status: input.status,
            location: request(input.location),
            businessHoursId: input.businessHoursId.cleanedForAPI,
            reason: input.reason
        )
    }

    static func updateRequest(_ input: SaveAdminBranchInput) -> UpdateAdminBranchRequestDTO {
        UpdateAdminBranchRequestDTO(
            code: input.code.cleanedForAPI,
            name: input.name.cleanedForAPI,
            type: input.type.cleanedForAPI,
            location: request(input.location),
            clearLocation: input.clearLocation,
            businessHoursId: input.businessHoursId.cleanedForAPI,
            clearBusinessHoursId: input.clearBusinessHoursId,
            reason: input.reason
        )
    }

    static func createRequest(_ input: SaveAdminEmissionPointInput) -> CreateAdminEmissionPointRequestDTO {
        CreateAdminEmissionPointRequestDTO(
            branchId: input.branchId,
            establishmentCode: input.establishmentCode,
            emissionPointCode: input.emissionPointCode,
            displayName: input.displayName,
            status: input.status,
            reason: input.reason
        )
    }

    static func updateRequest(_ input: SaveAdminEmissionPointInput) -> UpdateAdminEmissionPointRequestDTO {
        UpdateAdminEmissionPointRequestDTO(
            branchId: input.branchId.cleanedForAPI,
            establishmentCode: input.establishmentCode.cleanedForAPI,
            emissionPointCode: input.emissionPointCode.cleanedForAPI,
            displayName: input.displayName.cleanedForAPI,
            reason: input.reason
        )
    }
}

private extension Optional where Wrapped == String {
    var cleanedForAPI: String? {
        guard let value = self else { return nil }
        return value.trimmingCharacters(in: .whitespacesAndNewlines).trimmedOrNil
    }
}

private extension String {
    var cleanedForAPI: String? {
        trimmingCharacters(in: .whitespacesAndNewlines).trimmedOrNil
    }
}
