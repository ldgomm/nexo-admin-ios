//
//  AdminBusinessPackageMapper.swift
//  Nexo Admin
//
//  Created by Nexo on 22/6/26.
//

import Foundation

extension AdminBusinessPackageCatalogResponseDTO {
    func toDomain() -> AdminBusinessPackageCatalogResponse {
        AdminBusinessPackageCatalogResponse(
            capabilityPackages: capabilityPackages.map { $0.toDomain() },
            verticalPresets: verticalPresets.map { $0.toDomain() },
            recommendedPresetCodes: recommendedPresetCodes,
            activeModuleCodes: activeModuleCodes,
            activityTypeCodes: activityTypeCodes,
            warnings: warnings
        )
    }
}

extension AdminCapabilityPackageDTO {
    func toDomain() -> AdminCapabilityPackage {
        AdminCapabilityPackage(
            code: code,
            displayName: displayName,
            description: description,
            category: category,
            status: status.toDomain(),
            coreModuleCodes: coreModuleCodes,
            recommendedPermissionCodes: recommendedPermissionCodes,
            dependsOnCapabilityCodes: dependsOnCapabilityCodes,
            readinessHints: readinessHints.map { $0.toDomain() },
            notes: notes
        )
    }
}

extension AdminVerticalPresetDTO {
    func toDomain() -> AdminVerticalPreset {
        AdminVerticalPreset(
            code: code,
            displayName: displayName,
            description: description,
            targetBusinessTypes: targetBusinessTypes,
            capabilityCodes: capabilityCodes,
            defaultModuleCodes: defaultModuleCodes,
            optionalCapabilityCodes: optionalCapabilityCodes,
            status: status.toDomain(),
            regulated: regulated,
            notes: notes
        )
    }
}

extension AdminBusinessPackageReadinessHintDTO {
    func toDomain() -> AdminBusinessPackageReadinessHint {
        AdminBusinessPackageReadinessHint(
            code: code,
            severity: severity.toDomain(),
            title: title,
            description: description,
            blocking: blocking
        )
    }
}

extension AdminBusinessPackageStatusDTO {
    func toDomain() -> AdminBusinessPackageStatus {
        switch self {
        case .availableNow: return .availableNow
        case .metadataOnly: return .metadataOnly
        case .future: return .future
        case .regulatedFuture: return .regulatedFuture
        case .conceptualOnly: return .conceptualOnly
        case .unknown(let raw): return .unknown(raw)
        }
    }
}

extension AdminBusinessPackageReadinessSeverityDTO {
    func toDomain() -> AdminBusinessPackageReadinessSeverity {
        switch self {
        case .info: return .info
        case .warning: return .warning
        case .blocker: return .blocker
        case .unknown(let raw): return .unknown(raw)
        }
    }
}
