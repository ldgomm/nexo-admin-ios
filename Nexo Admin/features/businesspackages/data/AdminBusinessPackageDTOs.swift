//
//  AdminBusinessPackageDTOs.swift
//  Nexo Admin
//
//  Created by Nexo on 22/6/26.
//

import Foundation

struct AdminBusinessPackageCatalogResponseDTO: Decodable, Equatable, Sendable {
    let capabilityPackages: [AdminCapabilityPackageDTO]
    let verticalPresets: [AdminVerticalPresetDTO]
    let recommendedPresetCodes: [String]
    let activeModuleCodes: [String]
    let activityTypeCodes: [String]
    let warnings: [String]

    private enum CodingKeys: String, CodingKey {
        case capabilityPackages
        case verticalPresets
        case recommendedPresetCodes
        case activeModuleCodes
        case activityTypeCodes
        case warnings
    }

    init(
        capabilityPackages: [AdminCapabilityPackageDTO] = [],
        verticalPresets: [AdminVerticalPresetDTO] = [],
        recommendedPresetCodes: [String] = [],
        activeModuleCodes: [String] = [],
        activityTypeCodes: [String] = [],
        warnings: [String] = []
    ) {
        self.capabilityPackages = capabilityPackages
        self.verticalPresets = verticalPresets
        self.recommendedPresetCodes = recommendedPresetCodes
        self.activeModuleCodes = activeModuleCodes
        self.activityTypeCodes = activityTypeCodes
        self.warnings = warnings
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.capabilityPackages = try container.decodeIfPresent([AdminCapabilityPackageDTO].self, forKey: .capabilityPackages) ?? []
        self.verticalPresets = try container.decodeIfPresent([AdminVerticalPresetDTO].self, forKey: .verticalPresets) ?? []
        self.recommendedPresetCodes = try container.decodeIfPresent([String].self, forKey: .recommendedPresetCodes) ?? []
        self.activeModuleCodes = try container.decodeIfPresent([String].self, forKey: .activeModuleCodes) ?? []
        self.activityTypeCodes = try container.decodeIfPresent([String].self, forKey: .activityTypeCodes) ?? []
        self.warnings = try container.decodeIfPresent([String].self, forKey: .warnings) ?? []
    }
}

struct AdminCapabilityPackageDTO: Decodable, Identifiable, Equatable, Sendable {
    var id: String { code }

    let code: String
    let displayName: String
    let description: String
    let category: String
    let status: AdminBusinessPackageStatusDTO
    let coreModuleCodes: [String]
    let recommendedPermissionCodes: [String]
    let dependsOnCapabilityCodes: [String]
    let readinessHints: [AdminBusinessPackageReadinessHintDTO]
    let notes: [String]

    private enum CodingKeys: String, CodingKey {
        case code
        case displayName
        case description
        case category
        case status
        case coreModuleCodes
        case recommendedPermissionCodes
        case dependsOnCapabilityCodes
        case readinessHints
        case notes
    }

    init(
        code: String,
        displayName: String,
        description: String,
        category: String,
        status: AdminBusinessPackageStatusDTO,
        coreModuleCodes: [String] = [],
        recommendedPermissionCodes: [String] = [],
        dependsOnCapabilityCodes: [String] = [],
        readinessHints: [AdminBusinessPackageReadinessHintDTO] = [],
        notes: [String] = []
    ) {
        self.code = code
        self.displayName = displayName
        self.description = description
        self.category = category
        self.status = status
        self.coreModuleCodes = coreModuleCodes
        self.recommendedPermissionCodes = recommendedPermissionCodes
        self.dependsOnCapabilityCodes = dependsOnCapabilityCodes
        self.readinessHints = readinessHints
        self.notes = notes
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.code = try container.decode(String.self, forKey: .code)
        self.displayName = try container.decodeIfPresent(String.self, forKey: .displayName) ?? code.nexoReadableKey
        self.description = try container.decodeIfPresent(String.self, forKey: .description) ?? ""
        self.category = try container.decodeIfPresent(String.self, forKey: .category) ?? "uncategorized"
        self.status = try container.decodeIfPresent(AdminBusinessPackageStatusDTO.self, forKey: .status) ?? .unknown("UNKNOWN")
        self.coreModuleCodes = try container.decodeIfPresent([String].self, forKey: .coreModuleCodes) ?? []
        self.recommendedPermissionCodes = try container.decodeIfPresent([String].self, forKey: .recommendedPermissionCodes) ?? []
        self.dependsOnCapabilityCodes = try container.decodeIfPresent([String].self, forKey: .dependsOnCapabilityCodes) ?? []
        self.readinessHints = try container.decodeIfPresent([AdminBusinessPackageReadinessHintDTO].self, forKey: .readinessHints) ?? []
        self.notes = try container.decodeIfPresent([String].self, forKey: .notes) ?? []
    }
}

struct AdminVerticalPresetDTO: Decodable, Identifiable, Equatable, Sendable {
    var id: String { code }

    let code: String
    let displayName: String
    let description: String
    let targetBusinessTypes: [String]
    let capabilityCodes: [String]
    let defaultModuleCodes: [String]
    let optionalCapabilityCodes: [String]
    let status: AdminBusinessPackageStatusDTO
    let regulated: Bool
    let notes: [String]

    private enum CodingKeys: String, CodingKey {
        case code
        case displayName
        case description
        case targetBusinessTypes
        case capabilityCodes
        case defaultModuleCodes
        case optionalCapabilityCodes
        case status
        case regulated
        case notes
    }

    init(
        code: String,
        displayName: String,
        description: String,
        targetBusinessTypes: [String] = [],
        capabilityCodes: [String] = [],
        defaultModuleCodes: [String] = [],
        optionalCapabilityCodes: [String] = [],
        status: AdminBusinessPackageStatusDTO,
        regulated: Bool = false,
        notes: [String] = []
    ) {
        self.code = code
        self.displayName = displayName
        self.description = description
        self.targetBusinessTypes = targetBusinessTypes
        self.capabilityCodes = capabilityCodes
        self.defaultModuleCodes = defaultModuleCodes
        self.optionalCapabilityCodes = optionalCapabilityCodes
        self.status = status
        self.regulated = regulated
        self.notes = notes
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.code = try container.decode(String.self, forKey: .code)
        self.displayName = try container.decodeIfPresent(String.self, forKey: .displayName) ?? code.nexoReadableKey
        self.description = try container.decodeIfPresent(String.self, forKey: .description) ?? ""
        self.targetBusinessTypes = try container.decodeIfPresent([String].self, forKey: .targetBusinessTypes) ?? []
        self.capabilityCodes = try container.decodeIfPresent([String].self, forKey: .capabilityCodes) ?? []
        self.defaultModuleCodes = try container.decodeIfPresent([String].self, forKey: .defaultModuleCodes) ?? []
        self.optionalCapabilityCodes = try container.decodeIfPresent([String].self, forKey: .optionalCapabilityCodes) ?? []
        self.status = try container.decodeIfPresent(AdminBusinessPackageStatusDTO.self, forKey: .status) ?? .unknown("UNKNOWN")
        self.regulated = try container.decodeIfPresent(Bool.self, forKey: .regulated) ?? false
        self.notes = try container.decodeIfPresent([String].self, forKey: .notes) ?? []
    }
}

struct AdminBusinessPackageReadinessHintDTO: Decodable, Identifiable, Equatable, Sendable {
    var id: String { code }

    let code: String
    let severity: AdminBusinessPackageReadinessSeverityDTO
    let title: String
    let description: String
    let blocking: Bool

    private enum CodingKeys: String, CodingKey {
        case code
        case severity
        case title
        case description
        case blocking
    }

    init(
        code: String,
        severity: AdminBusinessPackageReadinessSeverityDTO,
        title: String,
        description: String,
        blocking: Bool = false
    ) {
        self.code = code
        self.severity = severity
        self.title = title
        self.description = description
        self.blocking = blocking
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.code = try container.decode(String.self, forKey: .code)
        self.severity = try container.decodeIfPresent(AdminBusinessPackageReadinessSeverityDTO.self, forKey: .severity) ?? .info
        self.title = try container.decodeIfPresent(String.self, forKey: .title) ?? code.nexoReadableKey
        self.description = try container.decodeIfPresent(String.self, forKey: .description) ?? ""
        self.blocking = try container.decodeIfPresent(Bool.self, forKey: .blocking) ?? false
    }
}

enum AdminBusinessPackageStatusDTO: Equatable, Decodable, Sendable {
    case availableNow
    case metadataOnly
    case future
    case regulatedFuture
    case conceptualOnly
    case unknown(String)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = (try? container.decode(String.self)) ?? "UNKNOWN"
        switch rawValue.trimmingCharacters(in: .whitespacesAndNewlines).uppercased() {
        case "AVAILABLE_NOW": self = .availableNow
        case "METADATA_ONLY": self = .metadataOnly
        case "FUTURE": self = .future
        case "REGULATED_FUTURE": self = .regulatedFuture
        case "CONCEPTUAL_ONLY": self = .conceptualOnly
        default: self = .unknown(rawValue)
        }
    }
}

enum AdminBusinessPackageReadinessSeverityDTO: Equatable, Decodable, Sendable {
    case info
    case warning
    case blocker
    case unknown(String)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = (try? container.decode(String.self)) ?? "INFO"
        switch rawValue.trimmingCharacters(in: .whitespacesAndNewlines).uppercased() {
        case "INFO": self = .info
        case "WARNING": self = .warning
        case "BLOCKER": self = .blocker
        default: self = .unknown(rawValue)
        }
    }
}
