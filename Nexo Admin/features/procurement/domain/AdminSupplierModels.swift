//
//  AdminSupplierModels.swift
//  Nexo Admin
//
//  Created by José Ruiz on 29/7/26.
//
//  27R.N.2 — Supplier master domain and authorization boundary.
//

import Foundation

enum AdminSupplierStatus: String, CaseIterable, Identifiable, Sendable {
    case active = "ACTIVE"
    case inactive = "INACTIVE"
    case blocked = "BLOCKED"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .active: return "Activo"
        case .inactive: return "Inactivo"
        case .blocked: return "Bloqueado"
        }
    }

    var systemImage: String {
        switch self {
        case .active: return "checkmark.circle.fill"
        case .inactive: return "pause.circle.fill"
        case .blocked: return "xmark.octagon.fill"
        }
    }
}

enum AdminSupplierStatusFilter: String, CaseIterable, Identifiable, Sendable {
    case all = "ALL"
    case active = "ACTIVE"
    case inactive = "INACTIVE"
    case blocked = "BLOCKED"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: return "Todos"
        case .active: return "Activos"
        case .inactive: return "Inactivos"
        case .blocked: return "Bloqueados"
        }
    }

    var apiValue: String? { self == .all ? nil : rawValue }
}

enum AdminSupplierIdentificationType: String, CaseIterable, Identifiable, Sendable {
    case ruc = "RUC"
    case cedula = "CEDULA"
    case passport = "PASSPORT"
    case foreignTaxId = "FOREIGN_TAX_ID"
    case other = "OTHER"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .ruc: return "RUC"
        case .cedula: return "Cédula"
        case .passport: return "Pasaporte"
        case .foreignTaxId: return "Identificación fiscal extranjera"
        case .other: return "Otra"
        }
    }
}

enum AdminSupplierPaymentTermsMode: String, CaseIterable, Identifiable, Sendable {
    case immediate = "IMMEDIATE"
    case netDays = "NET_DAYS"
    case custom = "CUSTOM"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .immediate: return "Pago inmediato"
        case .netDays: return "Crédito en días"
        case .custom: return "Condición personalizada"
        }
    }
}

struct AdminSupplierContact: Identifiable, Equatable, Sendable {
    let id: String
    let name: String
    let role: String?
    let email: String?
    let phone: String?
    let isPrimary: Bool
    let notes: String?
}

struct AdminSupplierPaymentTerms: Equatable, Sendable {
    let mode: AdminSupplierPaymentTermsMode
    let netDays: Int?
    let label: String?
    let notes: String?

    var title: String {
        switch mode {
        case .immediate:
            return "Pago inmediato"
        case .netDays:
            return "Crédito a \(netDays ?? 0) días"
        case .custom:
            return label ?? "Condición personalizada"
        }
    }
}

struct AdminSupplier: Identifiable, Equatable, Sendable {
    let id: String
    let legalName: String
    let tradeName: String?
    let identificationType: AdminSupplierIdentificationType?
    let identificationNumber: String?
    let email: String?
    let phone: String?
    let address: String?
    let categories: [String]
    let contacts: [AdminSupplierContact]?
    let paymentTerms: AdminSupplierPaymentTerms
    let defaultCurrency: String
    let status: AdminSupplierStatus
    let notes: String?
    let createdAt: String
    let createdBy: String
    let updatedAt: String
    let updatedBy: String
    let version: Int64

    var displayName: String { tradeName?.trimmedOrNil ?? legalName }
    var secondaryName: String? { displayName == legalName ? nil : legalName }
    var sensitiveFieldsAvailable: Bool { contacts != nil }
}

struct AdminSupplierPage: Equatable, Sendable {
    let suppliers: [AdminSupplier]
    let nextCursor: String?
    let hasMore: Bool
}

struct AdminSupplierMutationResult: Equatable, Sendable {
    let supplier: AdminSupplier
    let requestId: String?
    let idempotencyReplayed: Bool?
}

struct AdminSupplierListQuery: Equatable, Sendable {
    let query: String?
    let status: AdminSupplierStatusFilter
    let category: String?
    let limit: Int
    let cursor: String?
}

struct AdminSupplierContactInput: Identifiable, Equatable, Sendable {
    let localId: UUID
    var serverId: String?
    var name: String
    var role: String
    var email: String
    var phone: String
    var isPrimary: Bool
    var notes: String

    var id: UUID { localId }

    init(
        localId: UUID = UUID(),
        serverId: String? = nil,
        name: String = "",
        role: String = "",
        email: String = "",
        phone: String = "",
        isPrimary: Bool = false,
        notes: String = ""
    ) {
        self.localId = localId
        self.serverId = serverId
        self.name = name
        self.role = role
        self.email = email
        self.phone = phone
        self.isPrimary = isPrimary
        self.notes = notes
    }
}

struct AdminSupplierWriteInput: Equatable, Sendable {
    var legalName: String
    var tradeName: String
    var identificationType: AdminSupplierIdentificationType?
    var identificationNumber: String
    var email: String
    var phone: String
    var address: String
    var categories: [String]
    var contacts: [AdminSupplierContactInput]
    var paymentTermsMode: AdminSupplierPaymentTermsMode
    var netDays: Int?
    var paymentTermsLabel: String
    var paymentTermsNotes: String
    var notes: String
    var expectedVersion: Int64?
    let idempotencyKey: String
}

struct AdminSupplierStatusInput: Equatable, Sendable {
    let status: AdminSupplierStatus
    let reason: String
    let expectedVersion: Int64
    let idempotencyKey: String
}

enum AdminSupplierAccess {
    static func canView(_ permissions: Set<String>) -> Bool {
        PermissionSet(permissions).can(PermissionCatalog.suppliersView)
    }

    static func canViewSensitive(_ permissions: Set<String>) -> Bool {
        PermissionSet(permissions).can(PermissionCatalog.suppliersSensitiveView)
    }

    static func canCreate(_ permissions: Set<String>) -> Bool {
        PermissionSet(permissions).can(PermissionCatalog.suppliersCreate)
    }

    static func canUpdate(_ permissions: Set<String>) -> Bool {
        PermissionSet(permissions).can(PermissionCatalog.suppliersUpdate)
    }

    static func canManageStatus(_ permissions: Set<String>) -> Bool {
        PermissionSet(permissions).can(PermissionCatalog.suppliersStatusManage)
    }
}
