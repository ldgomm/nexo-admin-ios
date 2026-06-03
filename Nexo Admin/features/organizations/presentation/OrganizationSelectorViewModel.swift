//
//  OrganizationSelectorViewModel.swift
//  Nexo Admin
//
//  Created by José Ruiz on 20/5/26.
//

import Combine
import Foundation

@MainActor
final class OrganizationSelectorViewModel: ObservableObject {
    @Published private(set) var organizations: [OrganizationChoice]
    @Published private(set) var isLoading = false
    @Published var searchText = ""
    @Published var errorMessage: String?
    @Published var infoMessage: String?

    private let sessionStore: AuthSessionStore
    private let authCoordinator: AuthSessionCoordinator

    init(sessionStore: AuthSessionStore, authCoordinator: AuthSessionCoordinator) {
        self.sessionStore = sessionStore
        self.authCoordinator = authCoordinator
        self.organizations = sessionStore.organizations
    }

    var filteredOrganizations: [OrganizationChoice] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let sorted = organizations.sorted {
            $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
        }

        guard !query.isEmpty else { return sorted }

        return sorted.filter { choice in
            choice.title.lowercased().contains(query) ||
            choice.organization.legalName.lowercased().contains(query) ||
            choice.organization.taxId.lowercased().contains(query) ||
            choice.membership.status.lowercased().contains(query)
        }
    }

    var hasOrganizations: Bool {
        !organizations.isEmpty
    }

    var canCreateOrganization: Bool {
        let permissions = PermissionSet(sessionStore.effectivePermissions)
        return permissions.can(PermissionCatalog.all) ||
            permissions.can("organizations.create") ||
            permissions.can("platform.organizations.create")
    }

    var activeOrganizationId: String? {
        sessionStore.activeOrganization?.id ?? sessionStore.selectedOrganizationId
    }

    func refreshLocalData() {
        organizations = sessionStore.organizations
    }

    func select(_ organization: OrganizationChoice) async {
        isLoading = true
        errorMessage = nil
        infoMessage = nil
        defer { isLoading = false }

        do {
            try await authCoordinator.selectOrganization(organization.id)
        } catch {
            errorMessage = error.userFriendlyMessage
        }
    }

    func createOrganizationTapped() {
        infoMessage = "La pantalla de creación queda lista para conectar cuando el backend exponga el endpoint de organizaciones. Por ahora crea la organización desde el seed/script o desde el panel backend."
    }

    func logout() async {
        await authCoordinator.logout()
    }
}
