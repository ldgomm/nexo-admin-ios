import XCTest
@testable import Nexo_Admin

@MainActor
final class AuthSessionCoordinatorTests: XCTestCase {
    func testLoginStoresTokensAndAuthenticatesWhenOrganizationIsActive() async throws {
        let tokenStore = InMemoryAuthTokenStore()
        let orgStore = InMemoryOrganizationSelectionStore(selectedOrganizationId: "org_1")
        let sessionStore = AuthSessionStore(tokenStore: tokenStore, organizationSelectionStore: orgStore)
        let repository = MockAuthRepository()
        let coordinator = AuthSessionCoordinator(
            repository: repository,
            sessionStore: sessionStore,
            tokenStore: tokenStore,
            organizationSelectionStore: orgStore
        )

        try await coordinator.login(email: "admin@nexo.local", password: "Secret123!")

        XCTAssertEqual(sessionStore.phase, .authenticated)
        XCTAssertEqual(sessionStore.currentUser?.id, "usr_owner")
        XCTAssertEqual(sessionStore.activeOrganization?.id, "org_1")
        XCTAssertNotNil(try tokenStore.readTokens())
    }

    func testLogoutClearsTokensAndOrganization() async throws {
        let tokenStore = InMemoryAuthTokenStore(tokens: SessionTokens(
            accessToken: "a",
            accessTokenExpiresAt: "soon",
            refreshToken: "r",
            refreshTokenExpiresAt: "later",
            sessionId: "s",
            userId: "u",
            mustChangePassword: false
        ))
        let orgStore = InMemoryOrganizationSelectionStore(selectedOrganizationId: "org_1")
        let sessionStore = AuthSessionStore(tokenStore: tokenStore, organizationSelectionStore: orgStore)
        let coordinator = AuthSessionCoordinator(
            repository: MockAuthRepository(),
            sessionStore: sessionStore,
            tokenStore: tokenStore,
            organizationSelectionStore: orgStore
        )

        await coordinator.logout()

        XCTAssertEqual(sessionStore.phase, .unauthenticated)
        XCTAssertNil(try tokenStore.readTokens())
        XCTAssertNil(orgStore.selectedOrganizationId)
    }
}
