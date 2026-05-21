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
    @Published var errorMessage: String?

    private let sessionStore: AuthSessionStore
    private let authCoordinator: AuthSessionCoordinator

    init(sessionStore: AuthSessionStore, authCoordinator: AuthSessionCoordinator) {
        self.sessionStore = sessionStore
        self.authCoordinator = authCoordinator
        self.organizations = sessionStore.organizations
    }

    func refreshLocalData() {
        organizations = sessionStore.organizations
    }

    func select(_ organization: OrganizationChoice) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            try await authCoordinator.selectOrganization(organization.id)
        } catch {
            errorMessage = error.userFriendlyMessage
        }
    }

    func logout() async {
        await authCoordinator.logout()
    }
}
