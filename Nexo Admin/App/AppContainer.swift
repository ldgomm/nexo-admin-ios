//
//  AppContainer.swift
//  Nexo Admin
//
//  Created by José Ruiz on 20/5/26.
//

import Combine

@MainActor
final class AppContainer: ObservableObject {
    let environment: AppEnvironment

    let tokenStore: AuthTokenStorage
    let organizationSelectionStore: OrganizationSelectionStoring
    let apiClient: APIClient
    let authRepository: any AuthRepository
    let dashboardRepository: any DashboardRepository

    @Published var sessionStore: AuthSessionStore
    let authCoordinator: AuthSessionCoordinator

    private init(
        environment: AppEnvironment,
        tokenStore: AuthTokenStorage,
        organizationSelectionStore: OrganizationSelectionStoring,
        apiClient: APIClient,
        authRepository: any AuthRepository,
        dashboardRepository: any DashboardRepository,
        sessionStore: AuthSessionStore,
        authCoordinator: AuthSessionCoordinator
    ) {
        self.environment = environment
        self.tokenStore = tokenStore
        self.organizationSelectionStore = organizationSelectionStore
        self.apiClient = apiClient
        self.authRepository = authRepository
        self.dashboardRepository = dashboardRepository
        self.sessionStore = sessionStore
        self.authCoordinator = authCoordinator
    }

    static func live(environment: AppEnvironment = .debug) -> AppContainer {
        let keychain = KeychainStore(service: "com.nexo.admin.ios")
        let tokenStore = KeychainAuthTokenStore(keychain: keychain)
        let organizationStore = UserDefaultsOrganizationSelectionStore()

        let refreshCoordinator = TokenRefreshCoordinator(
            environment: environment,
            tokenStore: tokenStore
        )

        let client = DefaultAPIClient(
            environment: environment,
            tokenStore: tokenStore,
            organizationSelectionStore: organizationStore,
            tokenRefreshCoordinator: refreshCoordinator
        )

        let authAPI = RemoteAuthAPI(apiClient: client)
        let authRepository = RemoteAuthRepository(authAPI: authAPI)
        let dashboardAPI = RemoteDashboardAPI(apiClient: client)
        let dashboardRepository = RemoteDashboardRepository(api: dashboardAPI)

        let sessionStore = AuthSessionStore(
            tokenStore: tokenStore,
            organizationSelectionStore: organizationStore
        )
        let coordinator = AuthSessionCoordinator(
            repository: authRepository,
            sessionStore: sessionStore,
            tokenStore: tokenStore,
            organizationSelectionStore: organizationStore
        )

        return AppContainer(
            environment: environment,
            tokenStore: tokenStore,
            organizationSelectionStore: organizationStore,
            apiClient: client,
            authRepository: authRepository,
            dashboardRepository: dashboardRepository,
            sessionStore: sessionStore,
            authCoordinator: coordinator
        )
    }
}
