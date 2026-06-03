//
//  AdminAccessModels.swift
//  Nexo Admin
//
//  Created by José Ruiz on 2/6/26.
//

import Foundation

struct AdminAccessUser: Identifiable, Equatable, Sendable {
    let id: String
    let email: String
    let displayName: String
    let phone: String?
    let status: String
    let membershipId: String
    let membershipStatus: String
    let roleIds: Set<String>
    let roleNames: [String]
    let effectivePermissions: Set<String>
    let activeSessionCount: Int
    let invitedBy: String?
    let acceptedAt: String?
    let blockedAt: String?
    let blockedReason: String?
    let createdAt: String
    let updatedAt: String
    let version: Int?

    var isBlocked: Bool {
        status.normalizedStatus == "blocked" || membershipStatus.normalizedStatus == "suspended" || blockedAt != nil
    }

    var isActive: Bool {
        status.normalizedStatus == "active" && membershipStatus.normalizedStatus == "active"
    }

    var statusLabel: String {
        if isBlocked { return "Bloqueado" }
        if isActive { return "Activo" }
        if membershipStatus.normalizedStatus == "pending" { return "Pendiente" }
        return status.readableStatus
    }

    var roleSummary: String {
        roleNames.isEmpty ? "Sin roles" : roleNames.joined(separator: ", ")
    }
}

struct AdminAccessRole: Identifiable, Equatable, Sendable {
    let id: String
    let code: String
    let organizationId: String?
    let scope: String
    let type: String
    let name: String
    let description: String
    let permissionKeys: Set<String>
    let systemRole: Bool
    let critical: Bool
    let editable: Bool
    let status: String
    let schemaVersion: Int

    var isActive: Bool { status.normalizedStatus == "active" }
    var isCustom: Bool { type.normalizedStatus == "custom" }
    var canBeEditedFromApp: Bool { isCustom && editable && !critical && !systemRole }
    var permissionCountLabel: String { "\(permissionKeys.count) permisos" }
}

struct AdminAccessPermission: Identifiable, Equatable, Sendable {
    var id: String { code }

    let code: String
    let name: String
    let description: String
    let category: String
    let scope: String
    let riskLevel: String
    let status: String
    let systemManaged: Bool
    let requiresAudit: Bool
    let requiresReason: Bool
    let requiresStepUp: Bool
    let featureFlag: String?

    var categoryLabel: String { category.readableStatus }
    var riskLabel: String { riskLevel.readableStatus }
}

struct AdminAccessInvitation: Identifiable, Equatable, Sendable {
    let id: String
    let organizationId: String
    let email: String
    let invitedByUserId: String
    let roleIds: Set<String>
    let roleNames: [String]
    let status: String
    let createdAt: String
    let expiresAt: String
    let acceptedAt: String?
    let revokedAt: String?
    let acceptedUserId: String?
    let version: Int

    var isPending: Bool { status.normalizedStatus == "pending" }
    var statusLabel: String { status.readableStatus }
    var roleSummary: String { roleNames.isEmpty ? "Sin roles" : roleNames.joined(separator: ", ") }
}

struct AdminTemporaryUserResult: Equatable, Sendable {
    let user: AdminAccessUser
    let credentialId: String
    let membershipId: String
    let temporaryPassword: String
    let mustChangePassword: Bool
    let createdAt: String
}

struct AdminInvitationCreatedResult: Equatable, Sendable {
    let invitation: AdminAccessInvitation
    let user: AdminAccessUser
    let membershipId: String
    let rawInvitationToken: String
    let invitationUrl: String?
    let createdAt: String
}

struct AdminInvitationResendResult: Equatable, Sendable {
    let invitation: AdminAccessInvitation
    let rawInvitationToken: String
    let invitationUrl: String?
}

struct AdminResetPasswordResult: Equatable, Sendable {
    let userId: String
    let credentialId: String
    let temporaryPassword: String
    let mustChangePassword: Bool
    let revokedSessions: Int
    let revokedRefreshTokens: Int
    let changedAt: String
}

struct AdminUserSessionRevocationResult: Equatable, Sendable {
    let userId: String
    let revokedSessions: Int
    let revokedRefreshTokens: Int
    let revokedAt: String
    let reason: String
}

struct CreateTemporaryAdminUserInput: Equatable, Sendable {
    var email = ""
    var displayName = ""
    var phone = ""
    var roleIds: Set<String> = []
    var temporaryPassword = ""
    var reason = "Crear usuario temporal desde Nexo Admin iOS"
}

struct UpdateAdminUserInput: Equatable, Sendable {
    var displayName = ""
    var phone = ""
    var clearPhone = false
    var roleIds: Set<String> = []
    var reason = "Actualizar usuario desde Nexo Admin iOS"
}

struct CreateAdminInvitationInput: Equatable, Sendable {
    var email = ""
    var displayName = ""
    var roleIds: Set<String> = []
    var reason = "Crear invitación desde Nexo Admin iOS"
}

struct CreateAdminRoleInput: Equatable, Sendable {
    var code = ""
    var name = ""
    var description = ""
    var permissionKeys: Set<String> = []
    var reason = "Crear rol desde Nexo Admin iOS"
}

struct UpdateAdminRoleInput: Equatable, Sendable {
    var name = ""
    var description = ""
    var permissionKeys: Set<String> = []
    var reason = "Actualizar rol desde Nexo Admin iOS"
}

struct AdminAccessActionDraft: Equatable, Sendable {
    var reason = ""
}

extension AdminAccessRole {
    var isOrganizationScoped: Bool { scope.normalizedStatus == "organization" }

    var isAssignableFromAdmin: Bool {
        isActive &&
        isOrganizationScoped &&
        type.normalizedStatus != "platform" &&
        !critical
    }

    var isProtectedFromMutation: Bool { systemRole || critical || !editable || !isCustom }

    var editRestrictionMessage: String? {
        if systemRole { return "Este rol pertenece al sistema. Puedes asignarlo si está activo, pero no editarlo desde la organización." }
        if critical { return "Este rol es crítico. El backend protege su edición para no dejar la organización sin administradores." }
        if !editable { return "Este rol no está marcado como editable por el backend." }
        if !isCustom { return "Solo los roles custom de organización se editan desde Nexo Admin." }
        return nil
    }
}

extension AdminAccessPermission {
    var isActive: Bool { status.normalizedStatus == "active" }
    var isWildcard: Bool { code == PermissionCatalog.all }
    var isBusinessFacing: Bool {
        let prefixes = [
            "sales.",
            "payments.",
            "receivables.",
            "cash.",
            "documents.",
            "customers.",
            "catalog.",
            "activities.",
            "branches.",
            "reports.",
            "tax.",
            "sri.",
            "electronic_signature.",
            "signature.",
            "settings.",
            "modules.",
            "organization."
        ]
        return prefixes.contains { code.hasPrefix($0) }
    }

    var isCredentialPermission: Bool { code.hasPrefix("credentials.") }
    var isHighRisk: Bool {
        let risk = riskLevel.normalizedStatus
        return risk == "high" || risk == "critical" || requiresStepUp
    }
}

extension Array where Element == AdminAccessRole {
    var assignableFromAdmin: [AdminAccessRole] {
        filter(\.isAssignableFromAdmin).sortedByName
    }
}

extension Array where Element == AdminAccessPermission {
    var activeWithoutWildcard: [AdminAccessPermission] {
        filter { $0.isActive && !$0.isWildcard }
    }

    func existingCodes(from candidateCodes: Set<String>) -> Set<String> {
        let available = Set(map(\.code))
        return candidateCodes.intersection(available)
    }
}

extension String {
    var normalizedStatus: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: "-", with: "_")
    }

    var readableStatus: String {
        let normalized = normalizedStatus
        if normalized.isEmpty { return "—" }
        return normalized
            .split(separator: "_")
            .map { part in part.prefix(1).uppercased() + part.dropFirst().lowercased() }
            .joined(separator: " ")
    }
}
