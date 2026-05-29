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
        print("RESTORE: start")
        sessionStore.markRestoring()

        do {
            print("RESTORE: reading tokens")
            guard let tokens = try tokenStore.readTokens() else {
                print("RESTORE: no tokens -> unauthenticated")
                sessionStore.markUnauthenticated()
                return
            }

            print("RESTORE: has tokens, mustChangePassword=\(tokens.mustChangePassword)")

            if tokens.mustChangePassword {
                print("RESTORE: needs password change")
                let context = try? await repository.loadMe(organizationId: nil)
                sessionStore.markNeedsPasswordChange(user: context?.user)
                return
            }

            print("RESTORE: loading me")
            try await loadMeAndResolveNavigation(
                preferredOrganizationId: organizationSelectionStore.selectedOrganizationId,
                source: .sessionRestore
            )
            print("RESTORE: done")
        } catch {
            print("RESTORE: failed \(error)")
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

        try await loadMeAndResolveNavigation(
            preferredOrganizationId: organizationSelectionStore.selectedOrganizationId,
            source: .login
        )
    }

    func selectOrganization(_ organizationId: String) async throws {
        let cleanId = organizationId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanId.isEmpty else {
            throw AppError.validation("Selecciona una organización válida.")
        }

        organizationSelectionStore.selectOrganization(id: cleanId)
        let context = try await repository.loadMe(organizationId: cleanId)

        guard context.activeOrganization?.id == cleanId else {
            organizationSelectionStore.clearSelectedOrganization()
            sessionStore.markNeedsOrganization(context: selectionOnlyContext(from: context))
            throw AppError.validation("No se pudo activar la organización seleccionada.")
        }

        sessionStore.markAuthenticated(context: context)
    }

    func requestOrganizationSelection() async {
        sessionStore.markRestoring()

        do {
            organizationSelectionStore.clearSelectedOrganization()
            let context = try await repository.loadMe(organizationId: nil)
            sessionStore.markNeedsOrganization(context: selectionOnlyContext(from: context))
        } catch {
            sessionStore.markFailed(error.userFriendlyMessage)
        }
    }

    func refreshActiveOrganizationContext() async {
        guard let organizationId = organizationSelectionStore.selectedOrganizationId else {
            await requestOrganizationSelection()
            return
        }

        do {
            let context = try await repository.loadMe(organizationId: organizationId)
            if context.activeOrganization?.id == organizationId {
                sessionStore.markAuthenticated(context: context)
            } else {
                organizationSelectionStore.clearSelectedOrganization()
                sessionStore.markNeedsOrganization(context: selectionOnlyContext(from: context))
            }
        } catch {
            sessionStore.markFailed(error.userFriendlyMessage)
        }
    }

    func logout() async {
        let sessionId = try? tokenStore.readTokens()?.sessionId
        _ = try? await repository.logout(sessionId: sessionId, reason: "Admin iOS logout")
        try? tokenStore.clearTokens()
        organizationSelectionStore.clearSelectedOrganization()
        sessionStore.markUnauthenticated()
    }

    private func loadMeAndResolveNavigation(
        preferredOrganizationId: String?,
        source: NavigationResolutionSource
    ) async throws {
        let preferredId = preferredOrganizationId?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        let initialContext = try await repository.loadMe(organizationId: preferredId)

        if let preferredId {
            if initialContext.activeOrganization?.id == preferredId {
                sessionStore.markAuthenticated(context: initialContext)
                return
            }

            if initialContext.memberships.contains(where: { $0.id == preferredId }) {
                let selectedContext = try await repository.loadMe(organizationId: preferredId)
                if selectedContext.activeOrganization?.id == preferredId {
                    sessionStore.markAuthenticated(context: selectedContext)
                    return
                }
            }

            organizationSelectionStore.clearSelectedOrganization()
            sessionStore.markNeedsOrganization(context: selectionOnlyContext(from: initialContext))
            return
        }

        if initialContext.memberships.isEmpty {
            organizationSelectionStore.clearSelectedOrganization()
            sessionStore.markNeedsOrganization(context: selectionOnlyContext(from: initialContext))
            return
        }

        if initialContext.memberships.count == 1, let onlyOrganization = initialContext.memberships.first {
            try await selectOrganization(onlyOrganization.id)
            return
        }

        organizationSelectionStore.clearSelectedOrganization()
        sessionStore.markNeedsOrganization(context: selectionOnlyContext(from: initialContext))
    }

    private func selectionOnlyContext(from context: MeContext) -> MeContext {
        MeContext(
            user: context.user,
            currentSession: context.currentSession,
            memberships: context.memberships,
            activeOrganization: nil,
            activeMembership: nil,
            roles: [],
            effectivePermissions: []
        )
    }
}

private enum NavigationResolutionSource {
    case login
    case sessionRestore
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
