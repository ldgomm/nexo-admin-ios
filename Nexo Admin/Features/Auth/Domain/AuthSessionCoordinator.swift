//
//  AuthSessionCoordinator.swift
//  Nexo Admin
//
//  Created by José Ruiz on 20/5/26.
//

import Foundation

@MainActor
final class AuthSessionCoordinator {
    private let repository: AuthRepository
    private let sessionStore: AuthSessionStore
    private let tokenStore: AuthTokenStorage
    private let organizationSelectionStore: OrganizationSelectionStoring

    init(
        repository: AuthRepository,
        sessionStore: AuthSessionStore,
        tokenStore: AuthTokenStorage,
        organizationSelectionStore: OrganizationSelectionStoring
    ) {
        self.repository = repository
        self.sessionStore = sessionStore
        self.tokenStore = tokenStore
        self.organizationSelectionStore = organizationSelectionStore
    }

    func restoreSession() async {
        sessionStore.markRestoring()

        do {
            guard let tokens = try tokenStore.readTokens() else {
                sessionStore.markUnauthenticated()
                return
            }

            if tokens.mustChangePassword {
                sessionStore.markNeedsPasswordChange()
                return
            }

            try await loadMeAndResolveNavigation(preferredOrganizationId: organizationSelectionStore.selectedOrganizationId)
        } catch {
            sessionStore.markFailed(error.userFriendlyMessage)
        }
    }

    func login(email: String, password: String) async throws {
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !cleanEmail.isEmpty else { throw AppError.validation("Ingresa tu correo.") }
        guard !password.isEmpty else { throw AppError.validation("Ingresa tu contraseña.") }

        let tokens = try await repository.login(email: cleanEmail, password: password)
        try tokenStore.saveTokens(tokens)

        if tokens.mustChangePassword {
            let context = try? await repository.loadMe(organizationId: nil)
            sessionStore.markNeedsPasswordChange(user: context?.user)
            return
        }

        try await loadMeAndResolveNavigation(preferredOrganizationId: organizationSelectionStore.selectedOrganizationId)
    }

    func selectOrganization(_ organizationId: String) async throws {
        organizationSelectionStore.selectOrganization(id: organizationId)
        let context = try await repository.loadMe(organizationId: organizationId)
        sessionStore.markAuthenticated(context: context)
    }

    func logout() async {
        let sessionId = try? tokenStore.readTokens()?.sessionId
        _ = try? await repository.logout(sessionId: sessionId, reason: "Admin iOS logout")
        try? tokenStore.clearTokens()
        organizationSelectionStore.clearSelectedOrganization()
        sessionStore.markUnauthenticated()
    }

    private func loadMeAndResolveNavigation(preferredOrganizationId: String?) async throws {
        let initialContext = try await repository.loadMe(organizationId: preferredOrganizationId)

        if initialContext.activeOrganization != nil {
            sessionStore.markAuthenticated(context: initialContext)
            return
        }

        if let onlyOrganization = initialContext.memberships.onlyElement {
            try await selectOrganization(onlyOrganization.id)
            return
        }

        sessionStore.markNeedsOrganization(context: initialContext)
    }
}

private extension Array {
    var onlyElement: Element? {
        count == 1 ? first : nil
    }
}
