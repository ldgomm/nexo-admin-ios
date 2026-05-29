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
    let adminOperationsRepository: any AdminOperationsRepository
    let adminFoundationRepository: any AdminFoundationRepository
    let adminPublicProjectionRepository: any AdminPublicProjectionRepository
    let adminSupportRepository: any AdminSupportRepository

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
        adminOperationsRepository: any AdminOperationsRepository,
        adminFoundationRepository: any AdminFoundationRepository,
        adminPublicProjectionRepository: any AdminPublicProjectionRepository,
        adminSupportRepository: any AdminSupportRepository,
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
        self.adminOperationsRepository = adminOperationsRepository
        self.adminFoundationRepository = adminFoundationRepository
        self.adminPublicProjectionRepository = adminPublicProjectionRepository
        self.adminSupportRepository = adminSupportRepository
        self.sessionStore = sessionStore
        self.authCoordinator = authCoordinator
    }

    static func live(environment: AppEnvironment = .debug) -> AppContainer {
        let keychain = KeychainStore(service: "com.nexo.admin.ios")
        let tokenStore = KeychainAuthTokenStore(keychain: keychain)
        let organizationStore = UserDefaultsOrganizationSelectionStore()
        let deviceIdentityStore = UserDefaultsDeviceIdentityStore()
        let buildInfo = BuildInfo.current()
        let deviceInfoProvider = DefaultDeviceInfoProvider(
            buildInfo: buildInfo,
            deviceIdentityStore: deviceIdentityStore
        )

        let refreshCoordinator = TokenRefreshCoordinator(
            environment: environment,
            tokenStore: tokenStore
        )

        let client = DefaultAPIClient(
            environment: environment,
            tokenStore: tokenStore,
            organizationSelectionStore: organizationStore,
            tokenRefreshCoordinator: refreshCoordinator,
            deviceInfoProvider: deviceInfoProvider
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

        let adminOperationsAPI = RemoteAdminOperationsAPI(apiClient: client)
        let adminOperationsRepository = RemoteAdminOperationsRepository(api: adminOperationsAPI)

        let adminFoundationAPI = RemoteAdminFoundationAPI(apiClient: client)
        let adminFoundationRepository = AdminFoundationRemoteRepository(api: adminFoundationAPI)

        let publicProjectionAPI = RemoteAdminPublicProjectionAPI(apiClient: client)
        let publicProjectionRepository = RemoteAdminPublicProjectionRepository(api: publicProjectionAPI)

        let supportAPI = RemoteAdminSupportAPI(apiClient: client)
        let supportRepository = RemoteAdminSupportRepository(api: supportAPI)

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
            adminOperationsRepository: adminOperationsRepository,
            adminFoundationRepository: adminFoundationRepository,
            adminPublicProjectionRepository: publicProjectionRepository,
            adminSupportRepository: supportRepository,
            sessionStore: sessionStore,
            authCoordinator: coordinator
        )
    }
}
