//
//  AdminFoundationModels.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import Foundation

struct AdminBusinessContext: Equatable, Sendable {
    let user: AdminBusinessContextUser
    let organization: AdminBusinessContextOrganization
    let branches: [AdminBusinessContextBranch]
    let activeBranchId: String?
    let activities: [AdminBusinessContextActivity]
    let activeModules: [String]
    let effectivePermissions: Set<String>
    let catalogRevision: String
    let taxConfigurationRevision: String
    let realtime: AdminBusinessContextRealtime

    var activeModuleSet: Set<String> {
        Set(activeModules)
    }

    var activeBranch: AdminBusinessContextBranch? {
        guard let activeBranchId else { return branches.first(where: \.main) ?? branches.first }
        return branches.first { $0.id == activeBranchId }
    }

    var displayName: String {
        organization.commercialName.isEmpty ? organization.legalName : organization.commercialName
    }
}

struct AdminBusinessContextUser: Equatable, Sendable {
    let id: String
    let displayName: String
    let email: String
}

struct AdminBusinessContextOrganization: Equatable, Sendable {
    let id: String
    let legalName: String
    let commercialName: String
    let countryCode: String
    let taxId: String
    let defaultCurrency: String
    let timezone: String
}

struct AdminBusinessContextBranch: Identifiable, Equatable, Sendable {
    let id: String
    let code: String
    let name: String
    let type: String
    let status: String
    let main: Bool
}

struct AdminBusinessContextActivity: Identifiable, Equatable, Sendable {
    let id: String
    let activityType: String
    let workflowMode: String
    let status: String
    let requiresScheduling: Bool
}

struct AdminBusinessContextRealtime: Equatable, Sendable {
    let enabled: Bool
    let sseUrl: String
}

struct AdminResolvedModule: Identifiable, Equatable, Sendable {
    var id: String { code }

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

    var canBeEnabled: Bool {
        blockedReasons.isEmpty && status.nexoNormalizedKey != "deprecated"
    }

    var categoryTitle: String {
        category.nexoReadableKey
    }

    var statusTitle: String {
        status.nexoReadableKey
    }

    var activeTitle: String {
        active ? "Activo" : "Inactivo"
    }
}

struct AdminModuleReadinessItem: Identifiable, Equatable, Sendable {
    var id: String { code }

    let code: String
    let ready: Bool
    let active: Bool
    let missingDependencies: [String]
    let warnings: [String]
    let blockers: [String]

    var hasProblems: Bool {
        !missingDependencies.isEmpty || !warnings.isEmpty || !blockers.isEmpty
    }
}

struct AdminModulesResult: Equatable, Sendable {
    let organizationId: String
    let modules: [AdminResolvedModule]
}

struct AdminModuleReadinessResult: Equatable, Sendable {
    let organizationId: String
    let readiness: [AdminModuleReadinessItem]
}

struct AdminFoundationSnapshot: Equatable, Sendable {
    let context: AdminBusinessContext
    let modules: [AdminResolvedModule]
    let readiness: [AdminModuleReadinessItem]

    var activeModules: [AdminResolvedModule] {
        modules.filter(\.active).sortedByCode
    }

    var inactiveModules: [AdminResolvedModule] {
        modules.filter { !$0.active }.sortedByCode
    }

    var blockedModules: [AdminResolvedModule] {
        modules.filter { !$0.blockedReasons.isEmpty }.sortedByCode
    }

    var readinessByCode: [String: AdminModuleReadinessItem] {
        Dictionary(uniqueKeysWithValues: readiness.map { ($0.code, $0) })
    }

    var operationalSummary: String {
        "\(activeModules.count) módulos activos · \(context.branches.count) sucursales · \(context.activities.count) actividades"
    }
}

struct AdminFoundationModuleActionDraft: Equatable, Sendable {
    var moduleCode = ""
    var reason = "Actualizar módulo desde Nexo Admin iOS"
    var enable = true
}

extension Array where Element == AdminResolvedModule {
    var sortedByCode: [AdminResolvedModule] {
        sorted { $0.code.localizedCaseInsensitiveCompare($1.code) == .orderedAscending }
    }
}

extension String {
    var nexoNormalizedKey: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: "-", with: "_")
    }

    var nexoReadableKey: String {
        let normalized = nexoNormalizedKey
        if normalized.isEmpty { return "—" }
        return normalized
            .split(separator: "_")
            .map { $0.prefix(1).uppercased() + $0.dropFirst().lowercased() }
            .joined(separator: " ")
    }
}
