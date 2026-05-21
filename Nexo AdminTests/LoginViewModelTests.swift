import XCTest
@testable import Nexo_Admin

@MainActor
final class LoginViewModelTests: XCTestCase {
    func testCanSubmitRequiresEmailAndPassword() {
        let viewModel = LoginViewModel(authCoordinator: makeCoordinator())
        XCTAssertFalse(viewModel.canSubmit)

        viewModel.email = "admin@nexo.local"
        XCTAssertFalse(viewModel.canSubmit)

        viewModel.password = "Secret123!"
        XCTAssertTrue(viewModel.canSubmit)
    }

    func testLoginShowsValidationErrorFromCoordinator() async {
        let tokenStore = InMemoryAuthTokenStore()
        let orgStore = InMemoryOrganizationSelectionStore()
        let sessionStore = AuthSessionStore(tokenStore: tokenStore, organizationSelectionStore: orgStore)
        let repository = MockAuthRepository(loginResult: .failure(AppError.invalidCredentials))
        let coordinator = AuthSessionCoordinator(
            repository: repository,
            sessionStore: sessionStore,
            tokenStore: tokenStore,
            organizationSelectionStore: orgStore
        )
        let viewModel = LoginViewModel(authCoordinator: coordinator)
        viewModel.email = "admin@nexo.local"
        viewModel.password = "bad"

        await viewModel.login()

        XCTAssertEqual(viewModel.errorMessage, AppError.invalidCredentials.localizedDescription)
    }

    private func makeCoordinator() -> AuthSessionCoordinator {
        let tokenStore = InMemoryAuthTokenStore()
        let orgStore = InMemoryOrganizationSelectionStore()
        let sessionStore = AuthSessionStore(tokenStore: tokenStore, organizationSelectionStore: orgStore)
        return AuthSessionCoordinator(
            repository: MockAuthRepository(),
            sessionStore: sessionStore,
            tokenStore: tokenStore,
            organizationSelectionStore: orgStore
        )
    }
}
