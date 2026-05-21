//
//  PermissionCatalog.swift
//  Nexo Admin
//
//  Created by José Ruiz on 20/5/26.
//

import Foundation

enum PermissionCatalog {
    static let all = "*"

    static let credentialsUsersView = "credentials.users.view"
    static let credentialsUsersCreate = "credentials.users.create"
    static let credentialsUsersInvite = "credentials.users.invite"
    static let credentialsUsersBlock = "credentials.users.block"
    static let credentialsUsersUnblock = "credentials.users.unblock"
    static let credentialsUsersResetPassword = "credentials.users.reset_password"
    static let credentialsRolesView = "credentials.roles.view"
    static let credentialsRolesManage = "credentials.roles.manage"

    static let organizationView = "organization.view"
    static let organizationUpdate = "organization.update"
    static let activitiesView = "activities.view"
    static let branchesView = "branches.view"
    static let emissionPointsView = "settings.emission_points.view"

    static let catalogLocalView = "catalog.local.view"
    static let catalogLocalManage = "catalog.local.manage"

    static let taxSettingsView = "tax.settings.view"
    static let taxManage = "tax.manage"

    static let auditView = "audit.view"
}

struct PermissionSet: Equatable, Sendable {
    let values: Set<String>

    func can(_ permission: String) -> Bool {
        values.contains(PermissionCatalog.all) || values.contains(permission)
    }

    func canAny(_ permissions: Set<String>) -> Bool {
        values.contains(PermissionCatalog.all) || !values.isDisjoint(with: permissions)
    }
}
