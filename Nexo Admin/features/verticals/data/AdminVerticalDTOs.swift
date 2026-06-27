//
//  AdminVerticalDTOs.swift
//  Nexo Admin
//
//  Created by Nexo on 26/6/26.
//

import Foundation

struct AdminVerticalPackagesResponseDTO: Decodable, Equatable, Sendable {
    let packages: [AdminVerticalPackageDTO]

    private enum CodingKeys: String, CodingKey { case packages }

    init(packages: [AdminVerticalPackageDTO] = []) {
        self.packages = packages
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.packages = try container.decodeIfPresent([AdminVerticalPackageDTO].self, forKey: .packages) ?? []
    }
}

struct AdminVerticalActivationsResponseDTO: Decodable, Equatable, Sendable {
    let activations: [AdminVerticalActivationDTO]

    private enum CodingKeys: String, CodingKey { case activations }

    init(activations: [AdminVerticalActivationDTO] = []) {
        self.activations = activations
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.activations = try container.decodeIfPresent([AdminVerticalActivationDTO].self, forKey: .activations) ?? []
    }
}

struct AdminVerticalPackageDTO: Decodable, Equatable, Sendable {
    let id: String
    let code: String
    let displayName: String
    let version: String
    let status: AdminVerticalPackageStatusDTO
    let capabilities: [AdminVerticalCapabilityDTO]
    let workModes: [AdminVerticalWorkModeDTO]
    let surfaces: [AdminVerticalSurfaceDTO]
    let readinessChecks: [AdminVerticalReadinessDefinitionDTO]
    let seedRefs: [AdminVerticalSeedRefDTO]

    private enum CodingKeys: String, CodingKey {
        case id
        case code
        case displayName
        case version
        case status
        case capabilities
        case workModes
        case surfaces
        case readinessChecks
        case seedRefs
    }

    init(
        id: String,
        code: String,
        displayName: String,
        version: String,
        status: AdminVerticalPackageStatusDTO,
        capabilities: [AdminVerticalCapabilityDTO] = [],
        workModes: [AdminVerticalWorkModeDTO] = [],
        surfaces: [AdminVerticalSurfaceDTO] = [],
        readinessChecks: [AdminVerticalReadinessDefinitionDTO] = [],
        seedRefs: [AdminVerticalSeedRefDTO] = []
    ) {
        self.id = id
        self.code = code
        self.displayName = displayName
        self.version = version
        self.status = status
        self.capabilities = capabilities
        self.workModes = workModes
        self.surfaces = surfaces
        self.readinessChecks = readinessChecks
        self.seedRefs = seedRefs
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.code = try container.decode(String.self, forKey: .code)
        self.id = try container.decodeIfPresent(String.self, forKey: .id) ?? code
        self.displayName = try container.decodeIfPresent(String.self, forKey: .displayName) ?? code.nexoReadableKey
        self.version = try container.decodeIfPresent(String.self, forKey: .version) ?? "1.0.0"
        self.status = try container.decodeIfPresent(AdminVerticalPackageStatusDTO.self, forKey: .status) ?? .unknown("UNKNOWN")
        self.capabilities = try container.decodeIfPresent([AdminVerticalCapabilityDTO].self, forKey: .capabilities) ?? []
        self.workModes = try container.decodeIfPresent([AdminVerticalWorkModeDTO].self, forKey: .workModes) ?? []
        self.surfaces = try container.decodeIfPresent([AdminVerticalSurfaceDTO].self, forKey: .surfaces) ?? []
        self.readinessChecks = try container.decodeIfPresent([AdminVerticalReadinessDefinitionDTO].self, forKey: .readinessChecks) ?? []
        self.seedRefs = try container.decodeIfPresent([AdminVerticalSeedRefDTO].self, forKey: .seedRefs) ?? []
    }
}

struct AdminVerticalCapabilityDTO: Decodable, Equatable, Sendable {
    let code: String
    let displayName: String
    let description: String
    let defaultEnabled: Bool

    private enum CodingKeys: String, CodingKey { case code, displayName, description, defaultEnabled }

    init(code: String, displayName: String, description: String, defaultEnabled: Bool = false) {
        self.code = code
        self.displayName = displayName
        self.description = description
        self.defaultEnabled = defaultEnabled
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.code = try container.decode(String.self, forKey: .code)
        self.displayName = try container.decodeIfPresent(String.self, forKey: .displayName) ?? code.nexoReadableKey
        self.description = try container.decodeIfPresent(String.self, forKey: .description) ?? ""
        self.defaultEnabled = try container.decodeIfPresent(Bool.self, forKey: .defaultEnabled) ?? false
    }
}

struct AdminVerticalWorkModeDTO: Decodable, Equatable, Sendable {
    let code: String
    let displayName: String
    let description: String
    let defaultMode: Bool

    private enum CodingKeys: String, CodingKey { case code, displayName, description, defaultMode = "default" }

    init(code: String, displayName: String, description: String, defaultMode: Bool = false) {
        self.code = code
        self.displayName = displayName
        self.description = description
        self.defaultMode = defaultMode
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.code = try container.decode(String.self, forKey: .code)
        self.displayName = try container.decodeIfPresent(String.self, forKey: .displayName) ?? code.nexoReadableKey
        self.description = try container.decodeIfPresent(String.self, forKey: .description) ?? ""
        self.defaultMode = try container.decodeIfPresent(Bool.self, forKey: .defaultMode) ?? false
    }
}

struct AdminVerticalSurfaceDTO: Decodable, Equatable, Sendable {
    let code: String
    let description: String

    private enum CodingKeys: String, CodingKey { case code, description }

    init(code: String, description: String) {
        self.code = code
        self.description = description
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.code = try container.decode(String.self, forKey: .code)
        self.description = try container.decodeIfPresent(String.self, forKey: .description) ?? ""
    }
}

struct AdminVerticalReadinessDefinitionDTO: Decodable, Equatable, Sendable {
    let code: String
    let displayName: String
    let blocking: Bool

    private enum CodingKeys: String, CodingKey { case code, displayName, blocking }

    init(code: String, displayName: String, blocking: Bool = false) {
        self.code = code
        self.displayName = displayName
        self.blocking = blocking
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.code = try container.decode(String.self, forKey: .code)
        self.displayName = try container.decodeIfPresent(String.self, forKey: .displayName) ?? code.nexoReadableKey
        self.blocking = try container.decodeIfPresent(Bool.self, forKey: .blocking) ?? false
    }
}

struct AdminVerticalSeedRefDTO: Decodable, Equatable, Sendable {
    let code: String
    let displayName: String
    let phase: String

    private enum CodingKeys: String, CodingKey { case code, displayName, phase }

    init(code: String, displayName: String, phase: String) {
        self.code = code
        self.displayName = displayName
        self.phase = phase
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.code = try container.decode(String.self, forKey: .code)
        self.displayName = try container.decodeIfPresent(String.self, forKey: .displayName) ?? code.nexoReadableKey
        self.phase = try container.decodeIfPresent(String.self, forKey: .phase) ?? "future"
    }
}

struct AdminVerticalActivationDTO: Decodable, Equatable, Sendable {
    let id: String
    let organizationId: String
    let verticalCode: String
    let packageVersion: String
    let status: AdminVerticalActivationStatusDTO
    let enabledCapabilities: [String]
    let defaultWorkMode: String?
    let branchOverrides: [String: String]
    let readinessSnapshot: AdminVerticalReadinessSnapshotDTO?
    let activatedAt: String?
    let activatedBy: String?
    let deactivatedAt: String?
    let deactivatedBy: String?
    let lastReason: String?
    let createdAt: String?
    let updatedAt: String?

    private enum CodingKeys: String, CodingKey {
        case id, organizationId, verticalCode, packageVersion, status, enabledCapabilities, defaultWorkMode
        case branchOverrides, readinessSnapshot, activatedAt, activatedBy, deactivatedAt, deactivatedBy
        case lastReason, createdAt, updatedAt
    }

    init(
        id: String,
        organizationId: String,
        verticalCode: String,
        packageVersion: String = "1.0.0",
        status: AdminVerticalActivationStatusDTO,
        enabledCapabilities: [String] = [],
        defaultWorkMode: String? = nil,
        branchOverrides: [String: String] = [:],
        readinessSnapshot: AdminVerticalReadinessSnapshotDTO? = nil,
        activatedAt: String? = nil,
        activatedBy: String? = nil,
        deactivatedAt: String? = nil,
        deactivatedBy: String? = nil,
        lastReason: String? = nil,
        createdAt: String? = nil,
        updatedAt: String? = nil
    ) {
        self.id = id
        self.organizationId = organizationId
        self.verticalCode = verticalCode
        self.packageVersion = packageVersion
        self.status = status
        self.enabledCapabilities = enabledCapabilities
        self.defaultWorkMode = defaultWorkMode
        self.branchOverrides = branchOverrides
        self.readinessSnapshot = readinessSnapshot
        self.activatedAt = activatedAt
        self.activatedBy = activatedBy
        self.deactivatedAt = deactivatedAt
        self.deactivatedBy = deactivatedBy
        self.lastReason = lastReason
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.verticalCode = try container.decode(String.self, forKey: .verticalCode)
        self.id = try container.decodeIfPresent(String.self, forKey: .id) ?? verticalCode
        self.organizationId = try container.decodeIfPresent(String.self, forKey: .organizationId) ?? ""
        self.packageVersion = try container.decodeIfPresent(String.self, forKey: .packageVersion) ?? "1.0.0"
        self.status = try container.decodeIfPresent(AdminVerticalActivationStatusDTO.self, forKey: .status) ?? .unknown("UNKNOWN")
        self.enabledCapabilities = try container.decodeIfPresent([String].self, forKey: .enabledCapabilities) ?? []
        self.defaultWorkMode = try container.decodeIfPresent(String.self, forKey: .defaultWorkMode)
        self.branchOverrides = (try? container.decode([String: String].self, forKey: .branchOverrides)) ?? [:]
        self.readinessSnapshot = try container.decodeIfPresent(AdminVerticalReadinessSnapshotDTO.self, forKey: .readinessSnapshot)
        self.activatedAt = try container.decodeIfPresent(String.self, forKey: .activatedAt)
        self.activatedBy = try container.decodeIfPresent(String.self, forKey: .activatedBy)
        self.deactivatedAt = try container.decodeIfPresent(String.self, forKey: .deactivatedAt)
        self.deactivatedBy = try container.decodeIfPresent(String.self, forKey: .deactivatedBy)
        self.lastReason = try container.decodeIfPresent(String.self, forKey: .lastReason)
        self.createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt)
        self.updatedAt = try container.decodeIfPresent(String.self, forKey: .updatedAt)
    }
}

struct AdminVerticalReadinessResponseDTO: Decodable, Equatable, Sendable {
    let organizationId: String
    let verticalCode: String
    let checks: [AdminVerticalReadinessCheckDTO]

    private enum CodingKeys: String, CodingKey { case organizationId, verticalCode, checks }

    init(organizationId: String, verticalCode: String, checks: [AdminVerticalReadinessCheckDTO] = []) {
        self.organizationId = organizationId
        self.verticalCode = verticalCode
        self.checks = checks
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.organizationId = try container.decodeIfPresent(String.self, forKey: .organizationId) ?? ""
        self.verticalCode = try container.decodeIfPresent(String.self, forKey: .verticalCode) ?? ""
        self.checks = try container.decodeIfPresent([AdminVerticalReadinessCheckDTO].self, forKey: .checks) ?? []
    }
}

struct AdminVerticalReadinessSnapshotDTO: Decodable, Equatable, Sendable {
    let checkedAt: String?
    let checks: [AdminVerticalReadinessCheckDTO]

    private enum CodingKeys: String, CodingKey { case checkedAt, checks }

    init(checkedAt: String? = nil, checks: [AdminVerticalReadinessCheckDTO] = []) {
        self.checkedAt = checkedAt
        self.checks = checks
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.checkedAt = try container.decodeIfPresent(String.self, forKey: .checkedAt)
        self.checks = try container.decodeIfPresent([AdminVerticalReadinessCheckDTO].self, forKey: .checks) ?? []
    }
}

struct AdminVerticalReadinessCheckDTO: Decodable, Equatable, Sendable {
    let code: String
    let status: AdminVerticalReadinessStatusDTO
    let message: String
    let details: [String: String]

    private enum CodingKeys: String, CodingKey { case code, status, message, details }

    init(code: String, status: AdminVerticalReadinessStatusDTO, message: String, details: [String: String] = [:]) {
        self.code = code
        self.status = status
        self.message = message
        self.details = details
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.code = try container.decode(String.self, forKey: .code)
        self.status = try container.decodeIfPresent(AdminVerticalReadinessStatusDTO.self, forKey: .status) ?? .unknown("UNKNOWN")
        self.message = try container.decodeIfPresent(String.self, forKey: .message) ?? ""
        self.details = try container.decodeIfPresent([String: String].self, forKey: .details) ?? [:]
    }
}

struct AdminVerticalActivateRequestDTO: Encodable, Equatable, Sendable {
    let reason: String
    let defaultWorkMode: String
    let enabledCapabilities: [String]
}

struct AdminVerticalDeactivateRequestDTO: Encodable, Equatable, Sendable {
    let reason: String
}

enum AdminVerticalPackageStatusDTO: Equatable, Decodable, Sendable {
    case draft
    case active
    case deprecated
    case unknown(String)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = (try? container.decode(String.self)) ?? "UNKNOWN"
        switch rawValue.trimmingCharacters(in: .whitespacesAndNewlines).uppercased() {
        case "DRAFT": self = .draft
        case "ACTIVE": self = .active
        case "DEPRECATED": self = .deprecated
        default: self = .unknown(rawValue)
        }
    }
}

enum AdminVerticalActivationStatusDTO: Equatable, Decodable, Sendable {
    case configuring
    case active
    case disabled
    case suspended
    case unknown(String)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = (try? container.decode(String.self)) ?? "UNKNOWN"
        switch rawValue.trimmingCharacters(in: .whitespacesAndNewlines).uppercased() {
        case "CONFIGURING": self = .configuring
        case "ACTIVE": self = .active
        case "DISABLED": self = .disabled
        case "SUSPENDED": self = .suspended
        default: self = .unknown(rawValue)
        }
    }
}

enum AdminVerticalReadinessStatusDTO: Equatable, Decodable, Sendable {
    case pass
    case warn
    case fail
    case unknown(String)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = (try? container.decode(String.self)) ?? "UNKNOWN"
        switch rawValue.trimmingCharacters(in: .whitespacesAndNewlines).uppercased() {
        case "PASS": self = .pass
        case "WARN", "WARNING": self = .warn
        case "FAIL", "BLOCKER": self = .fail
        default: self = .unknown(rawValue)
        }
    }
}

// MARK: - Admin Restaurant Tables Readiness

struct AdminRestaurantTablesReadinessResponseDTO: Decodable, Equatable, Sendable {
    let organizationId: String
    let branchId: String?
    let restaurantTablesOptionalActive: Bool
    let businessUiReady: Bool
    let warnings: [String]
    let summary: AdminRestaurantTablesReadinessSummaryDTO
    let tables: [AdminRestaurantTableReadinessDTO]

    private enum CodingKeys: String, CodingKey {
        case organizationId
        case branchId
        case restaurantTablesOptionalActive
        case businessUiReady
        case warnings
        case summary
        case tables
    }

    init(
        organizationId: String,
        branchId: String?,
        restaurantTablesOptionalActive: Bool,
        businessUiReady: Bool,
        warnings: [String],
        summary: AdminRestaurantTablesReadinessSummaryDTO,
        tables: [AdminRestaurantTableReadinessDTO]
    ) {
        self.organizationId = organizationId
        self.branchId = branchId
        self.restaurantTablesOptionalActive = restaurantTablesOptionalActive
        self.businessUiReady = businessUiReady
        self.warnings = warnings
        self.summary = summary
        self.tables = tables
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.organizationId = try container.decodeIfPresent(String.self, forKey: .organizationId) ?? ""
        self.branchId = try container.decodeIfPresent(String.self, forKey: .branchId)
        self.restaurantTablesOptionalActive = try container.decodeIfPresent(Bool.self, forKey: .restaurantTablesOptionalActive) ?? false
        self.businessUiReady = try container.decodeIfPresent(Bool.self, forKey: .businessUiReady) ?? false
        self.warnings = try container.decodeIfPresent([String].self, forKey: .warnings) ?? []
        self.summary = try container.decodeIfPresent(AdminRestaurantTablesReadinessSummaryDTO.self, forKey: .summary) ?? .empty
        self.tables = try container.decodeIfPresent([AdminRestaurantTableReadinessDTO].self, forKey: .tables) ?? []
    }
}

struct AdminRestaurantTablesReadinessSummaryDTO: Decodable, Equatable, Sendable {
    let total: Int
    let available: Int
    let occupied: Int
    let disabled: Int
    let openSessions: Int

    static let empty = AdminRestaurantTablesReadinessSummaryDTO(total: 0, available: 0, occupied: 0, disabled: 0, openSessions: 0)

    private enum CodingKeys: String, CodingKey {
        case total
        case available
        case occupied
        case disabled
        case openSessions
    }

    init(total: Int, available: Int, occupied: Int, disabled: Int, openSessions: Int) {
        self.total = total
        self.available = available
        self.occupied = occupied
        self.disabled = disabled
        self.openSessions = openSessions
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.total = try container.decodeIfPresent(Int.self, forKey: .total) ?? 0
        self.available = try container.decodeIfPresent(Int.self, forKey: .available) ?? 0
        self.occupied = try container.decodeIfPresent(Int.self, forKey: .occupied) ?? 0
        self.disabled = try container.decodeIfPresent(Int.self, forKey: .disabled) ?? 0
        self.openSessions = try container.decodeIfPresent(Int.self, forKey: .openSessions) ?? 0
    }
}

struct AdminRestaurantTableReadinessDTO: Decodable, Equatable, Sendable {
    let tableId: String
    let code: String
    let name: String
    let area: String?
    let capacity: Int?
    let status: String
    let activeSessionId: String?
    let linkedSaleId: String?
    let openedAt: String?
    let canOpen: Bool
    let canClose: Bool
    let canCancel: Bool
    let canLinkSale: Bool
    let reasonIfBlocked: String?

    private enum CodingKeys: String, CodingKey {
        case tableId
        case code
        case name
        case area
        case capacity
        case status
        case activeSessionId
        case linkedSaleId
        case openedAt
        case canOpen
        case canClose
        case canCancel
        case canLinkSale
        case reasonIfBlocked
    }

    init(
        tableId: String,
        code: String,
        name: String,
        area: String?,
        capacity: Int?,
        status: String,
        activeSessionId: String?,
        linkedSaleId: String?,
        openedAt: String?,
        canOpen: Bool,
        canClose: Bool,
        canCancel: Bool,
        canLinkSale: Bool,
        reasonIfBlocked: String?
    ) {
        self.tableId = tableId
        self.code = code
        self.name = name
        self.area = area
        self.capacity = capacity
        self.status = status
        self.activeSessionId = activeSessionId
        self.linkedSaleId = linkedSaleId
        self.openedAt = openedAt
        self.canOpen = canOpen
        self.canClose = canClose
        self.canCancel = canCancel
        self.canLinkSale = canLinkSale
        self.reasonIfBlocked = reasonIfBlocked
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.tableId = try container.decodeIfPresent(String.self, forKey: .tableId) ?? ""
        self.code = try container.decodeIfPresent(String.self, forKey: .code) ?? tableId
        self.name = try container.decodeIfPresent(String.self, forKey: .name) ?? code
        self.area = try container.decodeIfPresent(String.self, forKey: .area)
        self.capacity = try container.decodeIfPresent(Int.self, forKey: .capacity)
        self.status = try container.decodeIfPresent(String.self, forKey: .status) ?? "unknown"
        self.activeSessionId = try container.decodeIfPresent(String.self, forKey: .activeSessionId)
        self.linkedSaleId = try container.decodeIfPresent(String.self, forKey: .linkedSaleId)
        self.openedAt = try container.decodeIfPresent(String.self, forKey: .openedAt)
        self.canOpen = try container.decodeIfPresent(Bool.self, forKey: .canOpen) ?? false
        self.canClose = try container.decodeIfPresent(Bool.self, forKey: .canClose) ?? false
        self.canCancel = try container.decodeIfPresent(Bool.self, forKey: .canCancel) ?? false
        self.canLinkSale = try container.decodeIfPresent(Bool.self, forKey: .canLinkSale) ?? false
        self.reasonIfBlocked = try container.decodeIfPresent(String.self, forKey: .reasonIfBlocked)
    }
}

