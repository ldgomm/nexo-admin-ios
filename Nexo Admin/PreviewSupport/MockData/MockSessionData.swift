//
//  MockSessionData.swift
//  Nexo Admin
//
//  Created by José Ruiz on 20/5/26.
//

import Foundation

enum MockSessionData {
    static let user = AdminUser(
        id: "usr_owner",
        email: "admin@nexo.local",
        displayName: "Administrador",
        status: "ACTIVE",
        phone: nil
    )

    static let session = CurrentSession(
        id: "ses_1",
        userId: "usr_owner",
        status: "ACTIVE",
        createdAt: "2026-05-20T00:00:00Z",
        expiresAt: "2026-05-21T00:00:00Z",
        lastSeenAt: nil
    )

    static let organization = AdminOrganization(
        id: "org_1",
        countryCode: "EC",
        taxId: "1790000000001",
        legalName: "Nexo Demo S.A.S.",
        commercialName: "Nexo Demo",
        status: "ACTIVE",
        ownerUserId: "usr_owner"
    )

    static let membership = AdminMembership(
        id: "mem_1",
        organizationId: "org_1",
        userId: "usr_owner",
        roleIds: ["role_owner"],
        status: "ACTIVE"
    )

    static let role = AdminRole(
        id: "role_owner",
        code: "owner",
        scope: "ORGANIZATION",
        type: "SYSTEM",
        name: "Propietario",
        permissionKeys: [PermissionCatalog.all],
        systemRole: true,
        critical: true
    )

    static let me = MeContext(
        user: user,
        currentSession: session,
        memberships: [OrganizationChoice(organization: organization, membership: membership, roles: [role])],
        activeOrganization: organization,
        activeMembership: membership,
        roles: [role],
        effectivePermissions: [PermissionCatalog.all]
    )
}
