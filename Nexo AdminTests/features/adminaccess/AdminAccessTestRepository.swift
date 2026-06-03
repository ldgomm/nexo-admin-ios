//
//  AdminAccessTestRepository.swift
//  Nexo Admin
//
//  Created by José Ruiz on 2/6/26.
//

import Foundation
@testable import Nexo_Admin

final class AdminAccessTestRepository: AdminAccessRepository, @unchecked Sendable {
    private var users: [AdminAccessUser] = [
        AdminAccessUser(
            id: "usr_owner",
            email: "owner@nexo.test",
            displayName: "Dueño Demo",
            phone: nil,
            status: "active",
            membershipId: "mem_owner",
            membershipStatus: "active",
            roleIds: ["role_owner"],
            roleNames: ["Propietario"],
            effectivePermissions: [PermissionCatalog.all],
            activeSessionCount: 1,
            invitedBy: nil,
            acceptedAt: nil,
            blockedAt: nil,
            blockedReason: nil,
            createdAt: "2026-05-21T00:00:00Z",
            updatedAt: "2026-05-21T00:00:00Z",
            version: 1
        ),
        AdminAccessUser(
            id: "usr_cashier",
            email: "cashier@nexo.test",
            displayName: "Cajero Demo",
            phone: nil,
            status: "active",
            membershipId: "mem_cashier",
            membershipStatus: "active",
            roleIds: ["role_cashier"],
            roleNames: ["Cajero"],
            effectivePermissions: [
                PermissionCatalog.salesView,
                PermissionCatalog.paymentsView,
                PermissionCatalog.cashSessionViewCurrent,
                PermissionCatalog.cashSessionOpen,
                PermissionCatalog.cashSessionClose
            ],
            activeSessionCount: 0,
            invitedBy: "usr_owner",
            acceptedAt: nil,
            blockedAt: nil,
            blockedReason: nil,
            createdAt: "2026-05-21T00:00:00Z",
            updatedAt: "2026-05-21T00:00:00Z",
            version: 1
        )
    ]

    private var roles: [AdminAccessRole] = [
        AdminAccessRole(
            id: "role_owner",
            code: "owner",
            organizationId: nil,
            scope: "organization",
            type: "system",
            name: "Propietario",
            description: "Acceso completo protegido por backend",
            permissionKeys: [PermissionCatalog.all],
            systemRole: true,
            critical: true,
            editable: false,
            status: "active",
            schemaVersion: 1
        ),
        AdminAccessRole(
            id: "role_cashier",
            code: "cashier",
            organizationId: "org_1",
            scope: "organization",
            type: "custom",
            name: "Cajero",
            description: "Cajero local",
            permissionKeys: [
                PermissionCatalog.salesView,
                PermissionCatalog.paymentsView,
                PermissionCatalog.cashSessionViewCurrent,
                PermissionCatalog.cashSessionOpen,
                PermissionCatalog.cashSessionClose
            ],
            systemRole: false,
            critical: false,
            editable: true,
            status: "active",
            schemaVersion: 1
        )
    ]

    private let permissions: [AdminAccessPermission] = AdminAccessTestRepository.makePermissions()

    func listUsers(query: String?, status: String?, limit: Int) async throws -> [AdminAccessUser] {
        var result = users
        if let query, !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let normalized = query.lowercased()
            result = result.filter { $0.email.lowercased().contains(normalized) || $0.displayName.lowercased().contains(normalized) }
        }
        if let status, !status.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let normalized = status.normalizedStatus
            result = result.filter { $0.status.normalizedStatus == normalized || $0.membershipStatus.normalizedStatus == normalized }
        }
        return Array(result.prefix(limit))
    }

    func getUser(id: String) async throws -> AdminAccessUser { users.first { $0.id == id }! }

    func createTemporaryUser(_ input: CreateTemporaryAdminUserInput) async throws -> AdminTemporaryUserResult {
        let user = AdminAccessUser(
            id: "usr_new",
            email: input.email,
            displayName: input.displayName,
            phone: input.phone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : input.phone,
            status: "active",
            membershipId: "mem_new",
            membershipStatus: "active",
            roleIds: input.roleIds,
            roleNames: roles.filter { input.roleIds.contains($0.id) }.map(\.name),
            effectivePermissions: Set(roles.filter { input.roleIds.contains($0.id) }.flatMap(\.permissionKeys)),
            activeSessionCount: 0,
            invitedBy: nil,
            acceptedAt: nil,
            blockedAt: nil,
            blockedReason: nil,
            createdAt: "2026-05-21T00:00:00Z",
            updatedAt: "2026-05-21T00:00:00Z",
            version: 1
        )
        users.append(user)
        return AdminTemporaryUserResult(user: user, credentialId: "cred_new", membershipId: "mem_new", temporaryPassword: "Temp123!Demo", mustChangePassword: true, createdAt: user.createdAt)
    }

    func updateUser(id: String, input: UpdateAdminUserInput) async throws -> AdminAccessUser {
        let current = users.first { $0.id == id }!
        let next = AdminAccessUser(
            id: current.id,
            email: current.email,
            displayName: input.displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? current.displayName : input.displayName,
            phone: input.clearPhone ? nil : input.phone,
            status: current.status,
            membershipId: current.membershipId,
            membershipStatus: current.membershipStatus,
            roleIds: input.roleIds.isEmpty ? current.roleIds : input.roleIds,
            roleNames: roles.filter { (input.roleIds.isEmpty ? current.roleIds : input.roleIds).contains($0.id) }.map(\.name),
            effectivePermissions: Set(roles.filter { (input.roleIds.isEmpty ? current.roleIds : input.roleIds).contains($0.id) }.flatMap(\.permissionKeys)),
            activeSessionCount: current.activeSessionCount,
            invitedBy: current.invitedBy,
            acceptedAt: current.acceptedAt,
            blockedAt: current.blockedAt,
            blockedReason: current.blockedReason,
            createdAt: current.createdAt,
            updatedAt: "2026-05-21T00:10:00Z",
            version: (current.version ?? 1) + 1
        )
        if let index = users.firstIndex(where: { $0.id == id }) {
            users[index] = next
        }
        return next
    }

    func blockUser(id: String, reason: String) async throws -> AdminAccessUser { users.first { $0.id == id }! }
    func unblockUser(id: String, reason: String) async throws -> AdminAccessUser { users.first { $0.id == id }! }

    func resetPassword(userId: String, temporaryPassword: String?, revokeSessions: Bool, reason: String) async throws -> AdminResetPasswordResult {
        AdminResetPasswordResult(userId: userId, credentialId: "cred", temporaryPassword: "Reset123!Demo", mustChangePassword: true, revokedSessions: 1, revokedRefreshTokens: 1, changedAt: "2026-05-21T00:00:00Z")
    }

    func revokeSessions(userId: String, reason: String) async throws -> AdminUserSessionRevocationResult {
        AdminUserSessionRevocationResult(userId: userId, revokedSessions: 1, revokedRefreshTokens: 1, revokedAt: "2026-05-21T00:00:00Z", reason: reason)
    }

    func listInvitations(status: String?, limit: Int) async throws -> [AdminAccessInvitation] { [] }
    func getInvitation(id: String) async throws -> AdminAccessInvitation { throw AppError.notFound }
    func createInvitation(_ input: CreateAdminInvitationInput) async throws -> AdminInvitationCreatedResult { throw AppError.validation("not implemented") }
    func resendInvitation(id: String, reason: String) async throws -> AdminInvitationResendResult { throw AppError.validation("not implemented") }
    func revokeInvitation(id: String, reason: String) async throws -> AdminAccessInvitation { throw AppError.validation("not implemented") }

    func listRoles(includeSystemTemplates: Bool) async throws -> [AdminAccessRole] {
        includeSystemTemplates ? roles : roles.filter { !$0.systemRole }
    }

    func getRole(id: String) async throws -> AdminAccessRole { roles.first { $0.id == id }! }

    func createRole(_ input: CreateAdminRoleInput) async throws -> AdminAccessRole {
        let role = AdminAccessRole(
            id: "role_\(input.code)",
            code: input.code,
            organizationId: "org_1",
            scope: "organization",
            type: "custom",
            name: input.name,
            description: input.description,
            permissionKeys: input.permissionKeys,
            systemRole: false,
            critical: false,
            editable: true,
            status: "active",
            schemaVersion: 1
        )
        roles.append(role)
        return role
    }

    func updateRole(id: String, input: UpdateAdminRoleInput) async throws -> AdminAccessRole {
        let current = roles.first { $0.id == id }!
        let next = AdminAccessRole(
            id: current.id,
            code: current.code,
            organizationId: current.organizationId,
            scope: current.scope,
            type: current.type,
            name: input.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? current.name : input.name,
            description: input.description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? current.description : input.description,
            permissionKeys: input.permissionKeys.isEmpty ? current.permissionKeys : input.permissionKeys,
            systemRole: current.systemRole,
            critical: current.critical,
            editable: current.editable,
            status: current.status,
            schemaVersion: current.schemaVersion + 1
        )
        if let index = roles.firstIndex(where: { $0.id == id }) {
            roles[index] = next
        }
        return next
    }

    func activateRole(id: String, reason: String) async throws -> AdminAccessRole { roles.first { $0.id == id }! }
    func deactivateRole(id: String, reason: String) async throws -> AdminAccessRole { roles.first { $0.id == id }! }
    func listPermissions(includeReserved: Bool) async throws -> [AdminAccessPermission] { permissions }

    private static func makePermissions() -> [AdminAccessPermission] {
        let definitions: [(String, String, String, String, String, Bool, Bool, Bool)] = [
            (PermissionCatalog.credentialsUsersView, "Ver usuarios", "Lista usuarios de la organización", "credentials", "medium", false, false, false),
            (PermissionCatalog.credentialsUsersCreate, "Crear usuarios", "Crea o actualiza usuarios", "credentials", "high", true, true, false),
            (PermissionCatalog.credentialsUsersInvite, "Invitar usuarios", "Crea invitaciones", "credentials", "high", true, true, false),
            (PermissionCatalog.credentialsUsersBlock, "Bloquear usuarios", "Bloquea accesos", "credentials", "high", true, true, false),
            (PermissionCatalog.credentialsUsersResetPassword, "Resetear contraseñas", "Genera contraseña temporal", "credentials", "high", true, true, false),
            (PermissionCatalog.credentialsRolesView, "Ver roles", "Lista roles", "credentials", "medium", false, false, false),
            (PermissionCatalog.credentialsRolesManage, "Gestionar roles", "Edita roles", "credentials", "high", true, true, false),
            (PermissionCatalog.credentialsSessionsRevoke, "Revocar sesiones", "Cierra sesiones activas", "credentials", "high", true, true, false),
            (PermissionCatalog.organizationView, "Ver organización", "Consulta negocio", "organization", "low", false, false, false),
            (PermissionCatalog.modulesView, "Ver módulos", "Consulta módulos activos", "settings", "low", false, false, false),
            (PermissionCatalog.activitiesView, "Ver actividades", "Consulta actividades", "settings", "low", false, false, false),
            (PermissionCatalog.branchesView, "Ver sucursales", "Consulta sucursales", "settings", "low", false, false, false),
            (PermissionCatalog.catalogLocalView, "Ver catálogo local", "Consulta productos y servicios", "catalog", "low", false, false, false),
            (PermissionCatalog.catalogLocalUpdateLocalCopy, "Editar catálogo local", "Edita copias locales", "catalog", "medium", true, true, false),
            (PermissionCatalog.catalogLocalCopyFromMaster, "Copiar del catálogo maestro", "Copia ítems", "catalog", "medium", true, true, false),
            (PermissionCatalog.catalogLocalChangePrice, "Cambiar precios", "Actualiza precios locales", "catalog", "high", true, true, false),
            (PermissionCatalog.catalogLocalDisableLocalCopy, "Desactivar ítems", "Pausa ítems locales", "catalog", "medium", true, true, false),
            (PermissionCatalog.customersView, "Ver clientes", "Consulta clientes", "customers", "low", false, false, false),
            (PermissionCatalog.customersCreate, "Crear clientes", "Registra clientes", "customers", "low", false, false, false),
            (PermissionCatalog.customersUpdate, "Editar clientes", "Actualiza clientes", "customers", "medium", true, true, false),
            (PermissionCatalog.salesView, "Ver ventas", "Consulta ventas", "sales", "low", false, false, false),
            (PermissionCatalog.paymentsView, "Ver pagos", "Consulta pagos", "payments", "low", false, false, false),
            (PermissionCatalog.receivablesView, "Ver cuentas por cobrar", "Consulta pendientes", "receivables", "low", false, false, false),
            (PermissionCatalog.cashView, "Ver caja", "Consulta caja", "cash", "low", false, false, false),
            (PermissionCatalog.cashSessionViewCurrent, "Ver caja actual", "Consulta sesión actual", "cash", "low", false, false, false),
            (PermissionCatalog.cashSessionViewHistory, "Ver historial de caja", "Consulta cierres", "cash", "medium", false, false, false),
            (PermissionCatalog.cashSessionOpen, "Abrir caja", "Abre sesión de caja", "cash", "high", true, true, false),
            (PermissionCatalog.cashSessionClose, "Cerrar caja", "Cierra sesión de caja", "cash", "high", true, true, false),
            (PermissionCatalog.documentsView, "Ver documentos", "Consulta documentos", "documents", "low", false, false, false),
            (PermissionCatalog.documentsDownloadPDF, "Descargar PDF", "Descarga PDF", "documents", "low", false, false, false),
            (PermissionCatalog.documentsDownloadRide, "Descargar RIDE", "Descarga RIDE", "documents", "low", false, false, false),
            (PermissionCatalog.documentsDownloadXML, "Descargar XML", "Descarga XML", "documents", "medium", false, false, false),
            (PermissionCatalog.documentsResendEmail, "Reenviar correo", "Reenvía documento", "documents", "medium", true, true, false),
            (PermissionCatalog.taxSettingsView, "Ver impuestos", "Consulta settings tributarios", "tax", "medium", false, false, false),
            (PermissionCatalog.taxProfilesView, "Ver perfiles tributarios", "Consulta perfiles", "tax", "medium", false, false, false),
            (PermissionCatalog.reportsDashboardView, "Ver Hoy", "Consulta tablero diario", "reports", "low", false, false, false),
            (PermissionCatalog.reportsSalesView, "Ver reportes de ventas", "Consulta reportes", "reports", "low", false, false, false),
            (PermissionCatalog.reportsCashView, "Ver reportes de caja", "Consulta caja", "reports", "medium", false, false, false),
            (PermissionCatalog.reportsDocumentsView, "Ver reportes de documentos", "Consulta documentos", "reports", "medium", false, false, false)
        ]
        return definitions.map { code, name, description, category, risk, audit, reason, stepUp in
            AdminAccessPermission(
                code: code,
                name: name,
                description: description,
                category: category,
                scope: "organization",
                riskLevel: risk,
                status: "active",
                systemManaged: true,
                requiresAudit: audit,
                requiresReason: reason,
                requiresStepUp: stepUp,
                featureFlag: nil
            )
        }
    }
}
