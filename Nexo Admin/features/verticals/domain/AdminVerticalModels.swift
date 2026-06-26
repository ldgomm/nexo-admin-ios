//
//  AdminVerticalModels.swift
//  Nexo Admin
//
//  Created by Nexo on 26/6/26.
//

import Foundation

struct AdminVerticalPackagesResult: Equatable, Sendable {
    let packages: [AdminVerticalPackage]

    var restaurantPackage: AdminVerticalPackage? {
        packages.first { $0.code == AdminVerticalCode.restaurant }
    }
}

struct AdminVerticalActivationsResult: Equatable, Sendable {
    let activations: [AdminVerticalActivation]

    func activation(for verticalCode: String) -> AdminVerticalActivation? {
        activations.first { $0.verticalCode == verticalCode }
    }
}

struct AdminVerticalPackage: Identifiable, Equatable, Sendable {
    var id: String { code }

    let packageId: String
    let code: String
    let displayName: String
    let version: String
    let status: AdminVerticalPackageStatus
    let capabilities: [AdminVerticalCapability]
    let workModes: [AdminVerticalWorkMode]
    let surfaces: [AdminVerticalSurface]
    let readinessChecks: [AdminVerticalReadinessDefinition]
    let seedRefs: [AdminVerticalSeedRef]

    var defaultCapabilityCodes: [String] {
        capabilities.filter(\.defaultEnabled).map(\.code)
    }

    var defaultWorkModeCode: String? {
        workModes.first(where: \.defaultMode)?.code ?? workModes.first?.code
    }
}

struct AdminVerticalCapability: Identifiable, Equatable, Sendable {
    var id: String { code }

    let code: String
    let displayName: String
    let description: String
    let defaultEnabled: Bool
}

struct AdminVerticalWorkMode: Identifiable, Equatable, Sendable {
    var id: String { code }

    let code: String
    let displayName: String
    let description: String
    let defaultMode: Bool
}

struct AdminVerticalSurface: Identifiable, Equatable, Sendable {
    var id: String { code }

    let code: String
    let description: String
}

struct AdminVerticalReadinessDefinition: Identifiable, Equatable, Sendable {
    var id: String { code }

    let code: String
    let displayName: String
    let blocking: Bool
}

struct AdminVerticalSeedRef: Identifiable, Equatable, Sendable {
    var id: String { code }

    let code: String
    let displayName: String
    let phase: String
}

struct AdminVerticalActivation: Identifiable, Equatable, Sendable {
    let id: String
    let organizationId: String
    let verticalCode: String
    let packageVersion: String
    let status: AdminVerticalActivationStatus
    let enabledCapabilities: [String]
    let defaultWorkMode: String?
    let branchOverrides: [String: String]
    let readinessSnapshot: AdminVerticalReadinessSnapshot?
    let activatedAt: String?
    let activatedBy: String?
    let deactivatedAt: String?
    let deactivatedBy: String?
    let lastReason: String?
    let createdAt: String?
    let updatedAt: String?

    var isActive: Bool { status == .active }
}

struct AdminVerticalReadinessResult: Equatable, Sendable {
    let organizationId: String
    let verticalCode: String
    let checks: [AdminVerticalReadinessCheck]

    var blockingFailures: [AdminVerticalReadinessCheck] {
        checks.filter { $0.status == .fail }
    }

    var warnings: [AdminVerticalReadinessCheck] {
        checks.filter { $0.status == .warn }
    }

    var passCount: Int {
        checks.filter { $0.status == .pass }.count
    }

    var failCount: Int {
        checks.filter { $0.status == .fail }.count
    }

    var warnCount: Int {
        checks.filter { $0.status == .warn }.count
    }
}

struct AdminVerticalReadinessSnapshot: Equatable, Sendable {
    let checkedAt: String?
    let checks: [AdminVerticalReadinessCheck]
}

struct AdminVerticalReadinessCheck: Identifiable, Equatable, Sendable {
    var id: String { code }

    let code: String
    let status: AdminVerticalReadinessStatus
    let message: String
    let details: [String: String]
}

enum AdminVerticalCode {
    static let restaurant = "restaurant"
}

enum AdminVerticalPackageStatus: Equatable, Sendable {
    case draft
    case active
    case deprecated
    case unknown(String)

    var title: String {
        switch self {
        case .draft: return "Borrador"
        case .active: return "Activo"
        case .deprecated: return "Deprecado"
        case .unknown(let raw): return raw.nexoReadableKey
        }
    }
}

enum AdminVerticalActivationStatus: Equatable, Sendable {
    case configuring
    case active
    case disabled
    case suspended
    case unknown(String)

    var title: String {
        switch self {
        case .configuring: return "Configurando"
        case .active: return "Activo"
        case .disabled: return "Desactivado"
        case .suspended: return "Suspendido"
        case .unknown(let raw): return raw.nexoReadableKey
        }
    }
}

enum AdminVerticalReadinessStatus: Equatable, Sendable {
    case pass
    case warn
    case fail
    case unknown(String)

    var title: String {
        switch self {
        case .pass: return "PASS"
        case .warn: return "WARN"
        case .fail: return "FAIL"
        case .unknown(let raw): return raw.nexoReadableKey
        }
    }
}

struct AdminVerticalActivationPresentation: Equatable, Sendable {
    let package: AdminVerticalPackage?
    let activation: AdminVerticalActivation?
    let readiness: AdminVerticalReadinessResult?
    let allPackages: [AdminVerticalPackage]
    let allActivations: [AdminVerticalActivation]

    var isRestaurantAvailable: Bool { package != nil }
    var isRestaurantActive: Bool { activation?.isActive == true }

    var defaultEnabledCapabilities: [String] {
        let fromActivation = activation?.enabledCapabilities ?? []
        if !fromActivation.isEmpty { return fromActivation.sorted() }
        return package?.defaultCapabilityCodes.sorted() ?? []
    }

    var defaultWorkMode: String {
        activation?.defaultWorkMode ?? package?.defaultWorkModeCode ?? "quick_sale"
    }

    var readinessSummaryTitle: String {
        guard let readiness else { return "Sin readiness" }
        if readiness.failCount > 0 { return "Con bloqueos" }
        if readiness.warnCount > 0 { return "Listo con advertencias" }
        return "Listo"
    }
}
