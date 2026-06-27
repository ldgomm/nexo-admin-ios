//
//  AdminVerticalMapper.swift
//  Nexo Admin
//
//  Created by Nexo on 26/6/26.
//

import Foundation

extension AdminVerticalPackagesResponseDTO {
    func toDomain() -> AdminVerticalPackagesResult {
        AdminVerticalPackagesResult(packages: packages.map { $0.toDomain() })
    }
}

extension AdminVerticalActivationsResponseDTO {
    func toDomain() -> AdminVerticalActivationsResult {
        AdminVerticalActivationsResult(activations: activations.map { $0.toDomain() })
    }
}

extension AdminVerticalPackageDTO {
    func toDomain() -> AdminVerticalPackage {
        AdminVerticalPackage(
            packageId: id,
            code: code,
            displayName: displayName,
            version: version,
            status: status.toDomain(),
            capabilities: capabilities.map { $0.toDomain() },
            workModes: workModes.map { $0.toDomain() },
            surfaces: surfaces.map { $0.toDomain() },
            readinessChecks: readinessChecks.map { $0.toDomain() },
            seedRefs: seedRefs.map { $0.toDomain() }
        )
    }
}

extension AdminVerticalCapabilityDTO {
    func toDomain() -> AdminVerticalCapability {
        AdminVerticalCapability(code: code, displayName: displayName, description: description, defaultEnabled: defaultEnabled)
    }
}

extension AdminVerticalWorkModeDTO {
    func toDomain() -> AdminVerticalWorkMode {
        AdminVerticalWorkMode(code: code, displayName: displayName, description: description, defaultMode: defaultMode)
    }
}

extension AdminVerticalSurfaceDTO {
    func toDomain() -> AdminVerticalSurface {
        AdminVerticalSurface(code: code, description: description)
    }
}

extension AdminVerticalReadinessDefinitionDTO {
    func toDomain() -> AdminVerticalReadinessDefinition {
        AdminVerticalReadinessDefinition(code: code, displayName: displayName, blocking: blocking)
    }
}

extension AdminVerticalSeedRefDTO {
    func toDomain() -> AdminVerticalSeedRef {
        AdminVerticalSeedRef(code: code, displayName: displayName, phase: phase)
    }
}

extension AdminVerticalActivationDTO {
    func toDomain() -> AdminVerticalActivation {
        AdminVerticalActivation(
            id: id,
            organizationId: organizationId,
            verticalCode: verticalCode,
            packageVersion: packageVersion,
            status: status.toDomain(),
            enabledCapabilities: enabledCapabilities.sorted(),
            defaultWorkMode: defaultWorkMode,
            branchOverrides: branchOverrides,
            readinessSnapshot: readinessSnapshot?.toDomain(),
            activatedAt: activatedAt,
            activatedBy: activatedBy,
            deactivatedAt: deactivatedAt,
            deactivatedBy: deactivatedBy,
            lastReason: lastReason,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

extension AdminVerticalReadinessResponseDTO {
    func toDomain() -> AdminVerticalReadinessResult {
        AdminVerticalReadinessResult(
            organizationId: organizationId,
            verticalCode: verticalCode,
            checks: checks.map { $0.toDomain() }
        )
    }
}

extension AdminVerticalReadinessSnapshotDTO {
    func toDomain() -> AdminVerticalReadinessSnapshot {
        AdminVerticalReadinessSnapshot(checkedAt: checkedAt, checks: checks.map { $0.toDomain() })
    }
}

extension AdminVerticalReadinessCheckDTO {
    func toDomain() -> AdminVerticalReadinessCheck {
        AdminVerticalReadinessCheck(code: code, status: status.toDomain(), message: message, details: details)
    }
}

extension AdminVerticalPackageStatusDTO {
    func toDomain() -> AdminVerticalPackageStatus {
        switch self {
        case .draft: return .draft
        case .active: return .active
        case .deprecated: return .deprecated
        case .unknown(let raw): return .unknown(raw)
        }
    }
}

extension AdminVerticalActivationStatusDTO {
    func toDomain() -> AdminVerticalActivationStatus {
        switch self {
        case .configuring: return .configuring
        case .active: return .active
        case .disabled: return .disabled
        case .suspended: return .suspended
        case .unknown(let raw): return .unknown(raw)
        }
    }
}

extension AdminVerticalReadinessStatusDTO {
    func toDomain() -> AdminVerticalReadinessStatus {
        switch self {
        case .pass: return .pass
        case .warn: return .warn
        case .fail: return .fail
        case .unknown(let raw): return .unknown(raw)
        }
    }
}

extension AdminVerticalActivationRequest {
    func toDTO() -> AdminVerticalActivateRequestDTO {
        AdminVerticalActivateRequestDTO(
            reason: reason,
            defaultWorkMode: defaultWorkMode,
            enabledCapabilities: enabledCapabilities
        )
    }
}

// MARK: - Admin Restaurant Tables Readiness

extension AdminRestaurantTablesReadinessResponseDTO {
    func toDomain() -> AdminRestaurantTablesReadiness {
        AdminRestaurantTablesReadiness(
            organizationId: organizationId,
            branchId: branchId,
            restaurantTablesOptionalActive: restaurantTablesOptionalActive,
            businessUiReady: businessUiReady,
            warnings: warnings,
            summary: summary.toDomain(),
            tables: tables.map { $0.toDomain() }
        )
    }
}

extension AdminRestaurantTablesReadinessSummaryDTO {
    func toDomain() -> AdminRestaurantTablesReadinessSummary {
        AdminRestaurantTablesReadinessSummary(
            total: total,
            available: available,
            occupied: occupied,
            disabled: disabled,
            openSessions: openSessions
        )
    }
}

extension AdminRestaurantTableReadinessDTO {
    func toDomain() -> AdminRestaurantTableReadiness {
        AdminRestaurantTableReadiness(
            tableId: tableId,
            code: code,
            name: name,
            area: area,
            capacity: capacity,
            status: status,
            activeSessionId: activeSessionId,
            linkedSaleId: linkedSaleId,
            openedAt: openedAt,
            canOpen: canOpen,
            canClose: canClose,
            canCancel: canCancel,
            canLinkSale: canLinkSale,
            reasonIfBlocked: reasonIfBlocked
        )
    }
}

