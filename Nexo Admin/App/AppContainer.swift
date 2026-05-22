//
//  AppContainer.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
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
    let adminAccessRepository: any AdminAccessRepository
    let adminBusinessRepository: any AdminBusinessRepository
    let adminCatalogRepository: any AdminCatalogRepository
    let adminTaxSriRepository: any AdminTaxSriRepository
    let adminElectronicDocumentRepository: any AdminElectronicDocumentRepository

    @Published var sessionStore: AuthSessionStore
    let authCoordinator: AuthSessionCoordinator

    private init(
        environment: AppEnvironment,
        tokenStore: AuthTokenStorage,
        organizationSelectionStore: OrganizationSelectionStoring,
        apiClient: APIClient,
        authRepository: any AuthRepository,
        dashboardRepository: any DashboardRepository,
        adminAccessRepository: any AdminAccessRepository,
        adminBusinessRepository: any AdminBusinessRepository,
        adminCatalogRepository: any AdminCatalogRepository,
        adminTaxSriRepository: any AdminTaxSriRepository,
        adminElectronicDocumentRepository: any AdminElectronicDocumentRepository,
        sessionStore: AuthSessionStore,
        authCoordinator: AuthSessionCoordinator
    ) {
        self.environment = environment
        self.tokenStore = tokenStore
        self.organizationSelectionStore = organizationSelectionStore
        self.apiClient = apiClient
        self.authRepository = authRepository
        self.dashboardRepository = dashboardRepository
        self.adminAccessRepository = adminAccessRepository
        self.adminBusinessRepository = adminBusinessRepository
        self.adminCatalogRepository = adminCatalogRepository
        self.adminTaxSriRepository = adminTaxSriRepository
        self.adminElectronicDocumentRepository = adminElectronicDocumentRepository
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

        let adminAccessAPI = RemoteAdminAccessAPI(apiClient: client)
        let adminAccessRepository = RemoteAdminAccessRepository(api: adminAccessAPI)

        let adminBusinessAPI = RemoteAdminBusinessAPI(apiClient: client)
        let adminBusinessRepository = RemoteAdminBusinessRepository(api: adminBusinessAPI)

        let adminCatalogAPI = RemoteAdminCatalogAPI(apiClient: client)
        let adminCatalogRepository = RemoteAdminCatalogRepository(api: adminCatalogAPI)

        let adminTaxSriAPI = RemoteAdminTaxSriAPI(apiClient: client)
        let adminTaxSriRepository = RemoteAdminTaxSriRepository(api: adminTaxSriAPI)

        let adminElectronicDocumentAPI = RemoteAdminElectronicDocumentAPI(apiClient: client)
        let adminElectronicDocumentRepository = RemoteAdminElectronicDocumentRepository(api: adminElectronicDocumentAPI)

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
            adminAccessRepository: adminAccessRepository,
            adminBusinessRepository: adminBusinessRepository,
            adminCatalogRepository: adminCatalogRepository,
            adminTaxSriRepository: adminTaxSriRepository,
            adminElectronicDocumentRepository: adminElectronicDocumentRepository,
            sessionStore: sessionStore,
            authCoordinator: coordinator
        )
    }
}
