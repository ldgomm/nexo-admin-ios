//
//  AuthSessionStore.swift
//  Nexo Admin
//
//  Created by José Ruiz on 20/5/26.
//

import Combine
import Foundation

@MainActor
enum AuthSessionPhase: Equatable {
    case restoring
    case unauthenticated
    case needsPasswordChange
    case needsOrganization
    case authenticated
    case failed(String)
}

@MainActor
final class AuthSessionStore: ObservableObject {
    @Published private(set) var phase: AuthSessionPhase = .restoring
    @Published private(set) var currentUser: AdminUser?
    @Published private(set) var currentSession: CurrentSession?
    @Published private(set) var organizations: [OrganizationChoice] = []
    @Published private(set) var activeOrganization: AdminOrganization?
    @Published private(set) var activeMembership: AdminMembership?
    @Published private(set) var roles: [AdminRole] = []
    @Published private(set) var effectivePermissions: Set<String> = []

    private let tokenStore: AuthTokenStorage
    private let organizationSelectionStore: OrganizationSelectionStoring

    init(
        tokenStore: AuthTokenStorage,
        organizationSelectionStore: OrganizationSelectionStoring
    ) {
        self.tokenStore = tokenStore
        self.organizationSelectionStore = organizationSelectionStore
    }

    var selectedOrganizationId: String? {
        organizationSelectionStore.selectedOrganizationId
    }

    func markRestoring() {
        phase = .restoring
    }

    func markUnauthenticated() {
        currentUser = nil
        currentSession = nil
        organizations = []
        activeOrganization = nil
        activeMembership = nil
        roles = []
        effectivePermissions = []
        phase = .unauthenticated
    }

    func markNeedsPasswordChange(user: AdminUser? = nil) {
        currentUser = user
        phase = .needsPasswordChange
    }

    func markNeedsOrganization(context: MeContext) {
        apply(context: context)
        phase = .needsOrganization
    }

    func markAuthenticated(context: MeContext) {
        apply(context: context)
        phase = .authenticated
    }

    func markFailed(_ message: String) {
        phase = .failed(message)
    }

    func selectOrganizationLocally(id: String?) {
        organizationSelectionStore.selectOrganization(id: id)
    }

    func clearLocalSession() {
        try? tokenStore.clearTokens()
        organizationSelectionStore.clearSelectedOrganization()
        markUnauthenticated()
    }

    private func apply(context: MeContext) {
        currentUser = context.user
        currentSession = context.currentSession
        organizations = context.memberships
        activeOrganization = context.activeOrganization
        activeMembership = context.activeMembership
        roles = context.roles
        effectivePermissions = context.effectivePermissions
    }
}
