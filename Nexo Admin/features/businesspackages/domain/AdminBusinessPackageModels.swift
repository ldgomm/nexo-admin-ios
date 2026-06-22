//
//  AdminBusinessPackageModels.swift
//  Nexo Admin
//
//  Created by Nexo on 22/6/26.
//

import Foundation

struct AdminBusinessPackageCatalogResponse: Equatable, Sendable {
    let capabilityPackages: [AdminCapabilityPackage]
    let verticalPresets: [AdminVerticalPreset]
    let recommendedPresetCodes: [String]
    let activeModuleCodes: [String]
    let activityTypeCodes: [String]
    let warnings: [String]
}

struct AdminCapabilityPackage: Identifiable, Equatable, Sendable {
    var id: String { code }

    let code: String
    let displayName: String
    let description: String
    let category: String
    let status: AdminBusinessPackageStatus
    let coreModuleCodes: [String]
    let recommendedPermissionCodes: [String]
    let dependsOnCapabilityCodes: [String]
    let readinessHints: [AdminBusinessPackageReadinessHint]
    let notes: [String]

    var categoryTitle: String { category.nexoReadableKey }
}

struct AdminVerticalPreset: Identifiable, Equatable, Sendable {
    var id: String { code }

    let code: String
    let displayName: String
    let description: String
    let targetBusinessTypes: [String]
    let capabilityCodes: [String]
    let defaultModuleCodes: [String]
    let optionalCapabilityCodes: [String]
    let status: AdminBusinessPackageStatus
    let regulated: Bool
    let notes: [String]

    var isRegulated: Bool {
        regulated || status == .regulatedFuture
    }
}

struct AdminBusinessPackageReadinessHint: Identifiable, Equatable, Sendable {
    var id: String { code }

    let code: String
    let severity: AdminBusinessPackageReadinessSeverity
    let title: String
    let description: String
    let blocking: Bool
}

enum AdminBusinessPackageStatus: Equatable, Sendable {
    case availableNow
    case metadataOnly
    case future
    case regulatedFuture
    case conceptualOnly
    case unknown(String)

    var title: String {
        switch self {
        case .availableNow: return "Disponible ahora"
        case .metadataOnly: return "Metadata"
        case .future: return "Futuro"
        case .regulatedFuture: return "Regulado futuro"
        case .conceptualOnly: return "Conceptual"
        case .unknown(let raw): return raw.nexoReadableKey
        }
    }

    var sortRank: Int {
        switch self {
        case .availableNow: return 0
        case .metadataOnly: return 1
        case .future: return 2
        case .regulatedFuture: return 3
        case .conceptualOnly: return 4
        case .unknown: return 5
        }
    }
}

enum AdminBusinessPackageReadinessSeverity: Equatable, Sendable {
    case info
    case warning
    case blocker
    case unknown(String)

    var title: String {
        switch self {
        case .info: return "Info"
        case .warning: return "Advertencia"
        case .blocker: return "Bloqueante"
        case .unknown(let raw): return raw.nexoReadableKey
        }
    }
}

struct AdminBusinessPackagesDiagnosticsPresentation: Equatable, Sendable {
    let recommendedPresets: [AdminVerticalPreset]
    let availablePresets: [AdminVerticalPreset]
    let futurePresets: [AdminVerticalPreset]
    let regulatedPresets: [AdminVerticalPreset]
    let capabilitySections: [AdminBusinessPackageCapabilitySection]
    let activeModuleCodes: [String]
    let activityTypeCodes: [String]
    let warnings: [String]

    var hasRecommendations: Bool { !recommendedPresets.isEmpty }
    var totalCapabilities: Int { capabilitySections.reduce(0) { $0 + $1.capabilities.count } }
    var totalPresets: Int { recommendedPresets.count + availablePresets.count + futurePresets.count + regulatedPresets.count }

    init(response: AdminBusinessPackageCatalogResponse) {
        let recommendedSet = Set(response.recommendedPresetCodes)
        let sortedPresets = response.verticalPresets.sortedByBusinessPackageDisplayName

        self.recommendedPresets = sortedPresets.filter { recommendedSet.contains($0.code) }
        self.availablePresets = sortedPresets.filter { preset in
            !recommendedSet.contains(preset.code) && preset.status == .availableNow && !preset.isRegulated
        }
        self.regulatedPresets = sortedPresets.filter(\.isRegulated)
        self.futurePresets = sortedPresets.filter { preset in
            !recommendedSet.contains(preset.code) && !preset.isRegulated && preset.status != .availableNow
        }
        self.capabilitySections = Dictionary(grouping: response.capabilityPackages.sortedByBusinessPackageDisplayName, by: { $0.categoryTitle })
            .map { AdminBusinessPackageCapabilitySection(title: $0.key, capabilities: $0.value) }
            .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        self.activeModuleCodes = response.activeModuleCodes.sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
        self.activityTypeCodes = response.activityTypeCodes.sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
        self.warnings = response.warnings
    }
}

struct AdminBusinessPackageCapabilitySection: Identifiable, Equatable, Sendable {
    var id: String { title }

    let title: String
    let capabilities: [AdminCapabilityPackage]
}

extension Array where Element == AdminVerticalPreset {
    var sortedByBusinessPackageDisplayName: [AdminVerticalPreset] {
        sorted {
            if $0.status.sortRank != $1.status.sortRank {
                return $0.status.sortRank < $1.status.sortRank
            }
            return $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending
        }
    }
}

extension Array where Element == AdminCapabilityPackage {
    var sortedByBusinessPackageDisplayName: [AdminCapabilityPackage] {
        sorted {
            if $0.status.sortRank != $1.status.sortRank {
                return $0.status.sortRank < $1.status.sortRank
            }
            return $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending
        }
    }
}
