//
//  MockAdminAccessData.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import Foundation

enum MockAdminAccessData {
    static let capabilityGroups: [AdminHumanCapabilityGroup] = [
        AdminHumanCapabilityGroup(
            code: "sales",
            title: "Ventas",
            description: "Permite consultar y operar ventas según permisos.",
            humanBullets: ["Ver historial de ventas", "Operar ventas permitidas"],
            permissionKeys: [PermissionCatalog.salesView],
            requiredModules: ["core.sales"],
            sensitive: false,
            rank: 100
        ),
        AdminHumanCapabilityGroup(
            code: "cash",
            title: "Caja",
            description: "Agrupa consulta, apertura y cierre de caja.",
            humanBullets: ["Ver caja", "Abrir caja", "Cerrar caja"],
            permissionKeys: [PermissionCatalog.cashView, PermissionCatalog.cashSessionViewCurrent, PermissionCatalog.cashSessionOpen, PermissionCatalog.cashSessionClose],
            requiredModules: ["core.cash"],
            sensitive: true,
            rank: 110
        ),
        AdminHumanCapabilityGroup(
            code: "team",
            title: "Equipo",
            description: "Permite administrar usuarios, roles y sesiones.",
            humanBullets: ["Ver equipo", "Gestionar roles", "Revocar sesiones"],
            permissionKeys: [PermissionCatalog.credentialsUsersView, PermissionCatalog.credentialsRolesView, PermissionCatalog.credentialsRolesManage, PermissionCatalog.credentialsSessionsRevoke],
            requiredModules: ["core.users_roles_permissions"],
            sensitive: true,
            rank: 300
        )
    ]

    static let permissions: [AdminAccessPermission] = [
        AdminAccessPermission(
            code: PermissionCatalog.credentialsUsersView,
            name: "Ver usuarios",
            description: "Permite listar y consultar usuarios de la organización.",
            category: "credentials",
            scope: "organization",
            riskLevel: "medium",
            status: "active",
            systemManaged: true,
            requiresAudit: false,
            requiresReason: false,
            requiresStepUp: false,
            featureFlag: nil
        ),
        AdminAccessPermission(
            code: PermissionCatalog.credentialsUsersCreate,
            name: "Crear usuarios",
            description: "Permite crear usuarios temporales y actualizar roles.",
            category: "credentials",
            scope: "organization",
            riskLevel: "high",
            status: "active",
            systemManaged: true,
            requiresAudit: true,
            requiresReason: true,
            requiresStepUp: false,
            featureFlag: nil
        ),
        AdminAccessPermission(
            code: PermissionCatalog.credentialsUsersBlock,
            name: "Bloquear usuarios",
            description: "Permite bloquear acceso de usuarios.",
            category: "credentials",
            scope: "organization",
            riskLevel: "critical",
            status: "active",
            systemManaged: true,
            requiresAudit: true,
            requiresReason: true,
            requiresStepUp: false,
            featureFlag: nil
        ),
        AdminAccessPermission(
            code: PermissionCatalog.credentialsRolesView,
            name: "Ver roles",
            description: "Permite listar roles y permisos disponibles.",
            category: "roles",
            scope: "organization",
            riskLevel: "medium",
            status: "active",
            systemManaged: true,
            requiresAudit: false,
            requiresReason: false,
            requiresStepUp: false,
            featureFlag: nil
        ),
        AdminAccessPermission(
            code: PermissionCatalog.credentialsRolesManage,
            name: "Gestionar roles",
            description: "Permite crear, editar, activar y desactivar roles custom.",
            category: "roles",
            scope: "organization",
            riskLevel: "critical",
            status: "active",
            systemManaged: true,
            requiresAudit: true,
            requiresReason: true,
            requiresStepUp: false,
            featureFlag: nil
        )
    ]

    static let roles: [AdminAccessRole] = [
        AdminAccessRole(
            id: "role_owner",
            code: "owner",
            organizationId: nil,
            scope: "organization",
            type: "system",
            name: "Propietario",
            description: "Acceso administrativo completo del negocio.",
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
            description: "Puede ver ventas, caja y clientes básicos.",
            permissionKeys: [PermissionCatalog.salesView, PermissionCatalog.cashView, PermissionCatalog.customersView],
            systemRole: false,
            critical: false,
            editable: true,
            status: "active",
            schemaVersion: 2
        )
    ]

    static let users: [AdminAccessUser] = [
        AdminAccessUser(
            id: "usr_owner",
            email: "owner@nexo.test",
            displayName: "Dueño Nexo",
            phone: "0999999999",
            status: "active",
            membershipId: "mem_owner",
            membershipStatus: "active",
            roleIds: ["role_owner"],
            roleNames: ["Propietario"],
            effectivePermissions: [PermissionCatalog.all],
            activeSessionCount: 1,
            invitedBy: nil,
            acceptedAt: "2026-05-21T08:00:00Z",
            blockedAt: nil,
            blockedReason: nil,
            createdAt: "2026-05-21T08:00:00Z",
            updatedAt: "2026-05-21T08:00:00Z",
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
            effectivePermissions: [PermissionCatalog.salesView, PermissionCatalog.cashView],
            activeSessionCount: 0,
            invitedBy: "usr_owner",
            acceptedAt: "2026-05-21T09:00:00Z",
            blockedAt: nil,
            blockedReason: nil,
            createdAt: "2026-05-21T09:00:00Z",
            updatedAt: "2026-05-21T09:00:00Z",
            version: 1
        )
    ]

    static let invitations: [AdminAccessInvitation] = [
        AdminAccessInvitation(
            id: "inv_1",
            organizationId: "org_1",
            email: "nuevo@nexo.test",
            invitedByUserId: "usr_owner",
            roleIds: ["role_cashier"],
            roleNames: ["Cajero"],
            status: "pending",
            createdAt: "2026-05-21T10:00:00Z",
            expiresAt: "2026-05-28T10:00:00Z",
            acceptedAt: nil,
            revokedAt: nil,
            acceptedUserId: nil,
            version: 1
        )
    ]
}
