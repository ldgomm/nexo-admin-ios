//
//  AdminBusinessModels.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import Foundation

enum AdminBusinessStatus: String, CaseIterable, Equatable, Sendable, Identifiable {
    case active
    case inactive
    case suspended
    case unknown

    var id: String { rawValue }

    init(apiValue: String) {
        self = AdminBusinessStatus(rawValue: apiValue.normalizedApiValue) ?? .unknown
    }

    var title: String {
        switch self {
        case .active: "Activo"
        case .inactive: "Inactivo"
        case .suspended: "Suspendido"
        case .unknown: "Desconocido"
        }
    }
}

enum AdminActivityStatus: String, CaseIterable, Equatable, Sendable, Identifiable {
    case draft
    case active
    case paused
    case archived
    case unknown

    var id: String { rawValue }

    init(apiValue: String) {
        self = AdminActivityStatus(rawValue: apiValue.normalizedApiValue) ?? .unknown
    }

    var title: String {
        switch self {
        case .draft: "Borrador"
        case .active: "Activa"
        case .paused: "Pausada"
        case .archived: "Archivada"
        case .unknown: "Desconocida"
        }
    }
}

enum AdminBranchStatus: String, CaseIterable, Equatable, Sendable, Identifiable {
    case active
    case inactive
    case archived
    case unknown

    var id: String { rawValue }

    init(apiValue: String) {
        self = AdminBranchStatus(rawValue: apiValue.normalizedApiValue) ?? .unknown
    }

    var title: String {
        switch self {
        case .active: "Activa"
        case .inactive: "Inactiva"
        case .archived: "Archivada"
        case .unknown: "Desconocida"
        }
    }
}

enum AdminEmissionPointStatus: String, CaseIterable, Equatable, Sendable, Identifiable {
    case active
    case inactive
    case archived
    case unknown

    var id: String { rawValue }

    init(apiValue: String) {
        self = AdminEmissionPointStatus(rawValue: apiValue.normalizedApiValue) ?? .unknown
    }

    var title: String {
        switch self {
        case .active: "Activo"
        case .inactive: "Inactivo"
        case .archived: "Archivado"
        case .unknown: "Desconocido"
        }
    }
}

enum AdminReadinessStatus: String, Equatable, Sendable {
    case ready
    case warning
    case blocked
    case missing
    case unknown

    init(apiValue: String) {
        self = AdminReadinessStatus(rawValue: apiValue.normalizedApiValue) ?? .unknown
    }

    var title: String {
        switch self {
        case .ready: "Listo"
        case .warning: "Advertencia"
        case .blocked: "Bloqueado"
        case .missing: "Pendiente"
        case .unknown: "Desconocido"
        }
    }
}

struct AdminBusinessProfile: Identifiable, Equatable, Sendable {
    let id: String
    let countryCode: String
    let taxId: String
    let legalName: String
    let commercialName: String
    let status: AdminBusinessStatus
    let ownerUserId: String
    let defaultCurrency: String?
    let timezone: String?
    let createdAt: String?
    let updatedAt: String?
    let version: Int

    var displayName: String { commercialName.trimmedOrNil ?? legalName }
    var fiscalSummary: String { "RUC \(taxId) • \(countryCode)" }
}

struct AdminBusinessActivity: Identifiable, Equatable, Sendable {
    let id: String
    let organizationId: String
    let code: String?
    let name: String
    let description: String?
    let activityType: String
    let workflowMode: String
    let status: AdminActivityStatus
    let requiresScheduling: Bool
    let tracksInventory: Bool
    let allowsReceivables: Bool
    let sortOrder: Int
    let createdAt: String?
    let updatedAt: String?

    var readableType: String { activityType.readableSnakeCase }
    var readableWorkflow: String { workflowMode.readableSnakeCase }
}

struct AdminBranchLocation: Equatable, Sendable {
    var countryCode: String?
    var province: String?
    var city: String?
    var sector: String?
    var addressLine: String?
    var latitude: Double?
    var longitude: Double?
    var privacyMode: String?

    var shortAddress: String {
        [city, sector, addressLine]
            .compactMap { $0?.trimmedOrNil }
            .joined(separator: " • ")
            .trimmedOrNil ?? "Sin ubicación configurada"
    }

    var coordinatesText: String? {
        guard let latitude, let longitude else { return nil }
        return String(format: "%.6f, %.6f", latitude, longitude)
    }
}

struct AdminBusinessBranch: Identifiable, Equatable, Sendable {
    let id: String
    let organizationId: String
    let code: String?
    let name: String
    let type: String
    let status: AdminBranchStatus
    let location: AdminBranchLocation?
    let businessHoursId: String?
    let createdAt: String?
    let updatedAt: String?

    var readableType: String { type.readableSnakeCase }
    var displayCode: String { code?.trimmedOrNil ?? "sin-código" }
    var isMain: Bool { type.normalizedApiValue == "main" }
}

struct AdminEmissionPoint: Identifiable, Equatable, Sendable {
    let id: String
    let organizationId: String
    let branchId: String
    let establishmentCode: String
    let emissionPointCode: String
    let fullCode: String
    let displayName: String
    let status: AdminEmissionPointStatus
    let createdAt: String?
    let updatedAt: String?

    func branchName(in branches: [AdminBusinessBranch]) -> String {
        branches.first(where: { $0.id == branchId })?.name ?? "Sucursal no encontrada"
    }
}

struct AdminBusinessReadinessCheck: Identifiable, Equatable, Sendable {
    let code: String
    let status: AdminReadinessStatus
    let required: Bool
    let message: String
    let action: String?

    var id: String { code }
}

struct AdminBusinessReadiness: Equatable, Sendable {
    let organizationId: String
    let overallStatus: AdminReadinessStatus
    let ready: Bool
    let generatedAt: String
    let checks: [AdminBusinessReadinessCheck]

    var blockingChecks: [AdminBusinessReadinessCheck] {
        checks.filter { $0.status == .blocked || ($0.required && $0.status != .ready) }
    }
}

enum AdminRestaurantReadinessStatus: String, Equatable, Sendable {
    case pass
    case warn
    case fail
    case unknown

    init(apiValue: String) {
        switch apiValue.normalizedApiValue {
        case "pass", "ready": self = .pass
        case "warn", "warning": self = .warn
        case "fail", "blocked": self = .fail
        default: self = .unknown
        }
    }

    var title: String {
        switch self {
        case .pass: "Listo"
        case .warn: "Con advertencias"
        case .fail: "Bloqueado"
        case .unknown: "Desconocido"
        }
    }

    var systemImage: String {
        switch self {
        case .pass: "checkmark.seal.fill"
        case .warn: "exclamationmark.triangle.fill"
        case .fail: "xmark.octagon.fill"
        case .unknown: "questionmark.circle.fill"
        }
    }

    var isEmphasis: Bool { self != .pass }
}

struct AdminRestaurantReadinessCheck: Identifiable, Equatable, Sendable {
    let code: String
    let status: AdminRestaurantReadinessStatus
    let message: String
    let blocking: Bool
    let details: [String: String]

    var id: String { code }
}

struct AdminRestaurantReadinessComponent: Identifiable, Equatable, Sendable {
    let code: String
    let status: AdminRestaurantReadinessStatus
    let path: String?
    let supportOnly: Bool
    let details: [String: String]

    var id: String { code }
}

struct AdminRestaurantTableSummary: Equatable, Sendable {
    let total: Int
    let available: Int
    let occupied: Int
    let disabled: Int
    let openSessions: Int

    var hasOpenSessions: Bool { openSessions > 0 }
}

struct AdminRestaurantSupportLink: Identifiable, Equatable, Sendable {
    let label: String
    let method: String
    let path: String
    let supportOnly: Bool

    var id: String { "\(method):\(path)" }
}

struct AdminRestaurantReadiness: Equatable, Sendable {
    let organizationId: String
    let branchId: String?
    let status: AdminRestaurantReadinessStatus
    let overallStatus: AdminRestaurantReadinessStatus
    let ready: Bool
    let surface: String
    let capabilities: [String]
    let supportMode: String
    let warnings: [String]
    let blockers: [String]
    let checks: [AdminRestaurantReadinessCheck]
    let components: [AdminRestaurantReadinessComponent]
    let tables: AdminRestaurantTableSummary?
    let supportLinks: [AdminRestaurantSupportLink]

    var hasWarnings: Bool { !warnings.isEmpty }
    var hasBlockers: Bool { !blockers.isEmpty }
    var isSupportOnly: Bool { supportMode.normalizedApiValue.contains("support_only") }
}

struct AdminBusinessFoundationCounts: Equatable, Sendable {
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

struct AdminBusinessNextAction: Identifiable, Equatable, Sendable {
    let code: String
    let status: AdminReadinessStatus
    let required: Bool
    let action: String

    var id: String { code }
}

struct AdminBusinessOverview: Equatable, Sendable {
    let organizationId: String
    let overallStatus: AdminReadinessStatus
    let ready: Bool
    let generatedAt: String
    let business: AdminBusinessProfile
    let readiness: AdminBusinessReadiness
    let counts: AdminBusinessFoundationCounts
    let nextActions: [AdminBusinessNextAction]
    let activities: [AdminBusinessActivity]
    let branches: [AdminBusinessBranch]
    let emissionPoints: [AdminEmissionPoint]
}

struct UpdateAdminBusinessProfileInput: Equatable, Sendable {
    var countryCode: String?
    var taxId: String?
    var legalName: String?
    var commercialName: String?
    var defaultCurrency: String?
    var timezone: String?
    var reason: String
}

struct SaveAdminActivityInput: Equatable, Sendable {
    var id: String?
    var code: String
    var name: String
    var description: String?
    var activityType: String
    var workflowMode: String
    var status: String
    var requiresScheduling: Bool
    var tracksInventory: Bool
    var allowsReceivables: Bool
    var sortOrder: Int
    var reason: String
}

struct SaveAdminBranchInput: Equatable, Sendable {
    var id: String?
    var code: String
    var name: String
    var type: String
    var status: String
    var location: AdminBranchLocation?
    var businessHoursId: String?
    var clearLocation: Bool
    var clearBusinessHoursId: Bool
    var reason: String
}

struct SaveAdminEmissionPointInput: Equatable, Sendable {
    var id: String?
    var branchId: String
    var establishmentCode: String
    var emissionPointCode: String
    var displayName: String
    var status: String
    var reason: String
}

struct AdminBusinessActionInput: Equatable, Sendable {
    var reason: String
}

extension String {
    var normalizedApiValue: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: "-", with: "_")
    }

    var trimmedOrNil: String? {
        let value = trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }

    var readableSnakeCase: String {
        normalizedApiValue
            .split(separator: "_")
            .map { part in
                let lower = String(part)
                return lower.prefix(1).uppercased() + lower.dropFirst()
            }
            .joined(separator: " ")
    }
}
