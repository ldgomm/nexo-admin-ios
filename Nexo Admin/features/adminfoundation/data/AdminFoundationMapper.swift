//
//  AdminFoundationMapper.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import Foundation

extension BusinessContextResponseDTO {
    func toDomain() -> AdminBusinessContext {
        AdminBusinessContext(
            user: user.toDomain(),
            organization: organization.toDomain(),
            branches: branches.map { $0.toDomain() },
            activeBranchId: activeBranchId,
            activities: activities.map { $0.toDomain() },
            activeModules: activeModules,
            effectivePermissions: Set(effectivePermissions),
            catalogRevision: catalogRevision,
            taxConfigurationRevision: taxConfigurationRevision,
            realtime: realtime.toDomain()
        )
    }
}

extension BusinessContextUserResponseDTO {
    func toDomain() -> AdminBusinessContextUser {
        AdminBusinessContextUser(id: id, displayName: displayName, email: email)
    }
}

extension BusinessContextOrganizationResponseDTO {
    func toDomain() -> AdminBusinessContextOrganization {
        AdminBusinessContextOrganization(
            id: id,
            legalName: legalName,
            commercialName: commercialName,
            countryCode: countryCode,
            taxId: taxId,
            defaultCurrency: defaultCurrency,
            timezone: timezone
        )
    }
}

extension BusinessContextBranchResponseDTO {
    func toDomain() -> AdminBusinessContextBranch {
        AdminBusinessContextBranch(id: id, code: code, name: name, type: type, status: status, main: main)
    }
}

extension BusinessContextActivityResponseDTO {
    func toDomain() -> AdminBusinessContextActivity {
        AdminBusinessContextActivity(
            id: id,
            activityType: activityType,
            workflowMode: workflowMode,
            status: status,
            requiresScheduling: requiresScheduling
        )
    }
}

extension BusinessContextRealtimeResponseDTO {
    func toDomain() -> AdminBusinessContextRealtime {
        AdminBusinessContextRealtime(enabled: enabled, sseUrl: sseUrl)
    }
}

extension ModulesResponseDTO {
    func toDomain() -> AdminModulesResult {
        AdminModulesResult(
            organizationId: organizationId,
            modules: modules.map { $0.toDomain() }
        )
    }
}

extension ResolvedModuleResponseDTO {
    func toDomain() -> AdminResolvedModule {
        AdminResolvedModule(
            code: code,
            name: name,
            category: category,
            status: status,
            active: active,
            source: source,
            dependencies: dependencies,
            compatibleActivityTypes: compatibleActivityTypes,
            defaultWorkflowModes: defaultWorkflowModes,
            permissions: permissions,
            screens: screens,
            events: events,
            blockedReasons: blockedReasons
        )
    }
}

extension ModuleReadinessResponseDTO {
    func toDomain() -> AdminModuleReadinessResult {
        AdminModuleReadinessResult(
            organizationId: organizationId,
            readiness: readiness.map { $0.toDomain() }
        )
    }
}

extension ModuleReadinessItemResponseDTO {
    func toDomain() -> AdminModuleReadinessItem {
        AdminModuleReadinessItem(
            code: code,
            ready: ready,
            active: active,
            missingDependencies: missingDependencies,
            warnings: warnings,
            blockers: blockers
        )
    }
}
