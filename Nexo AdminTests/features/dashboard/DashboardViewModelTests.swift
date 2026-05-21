//
//  DashboardViewModelTests.swift
//  Nexo Admin
//
//  Created by José Ruiz on 20/5/26.
//

import XCTest
@testable import Nexo_Admin

@MainActor
final class DashboardViewModelTests: XCTestCase {
    func testLoadPublishesLoadedStateWhenRepositoryReturnsSummary() async {
        let tokenStore = InMemoryAuthTokenStore()
        let organizationStore = InMemoryOrganizationSelectionStore()
        let sessionStore = AuthSessionStore(
            tokenStore: tokenStore,
            organizationSelectionStore: organizationStore
        )
        sessionStore.markAuthenticated(context: DashboardTestData.context(permissions: [PermissionCatalog.all]))

        let repository = FakeDashboardRepository(result: .success(DashboardTestData.summary()))
        let viewModel = DashboardViewModel(
            getSummary: GetDashboardSummaryUseCase(repository: repository),
            sessionStore: sessionStore
        )

        await viewModel.load()

        guard case .loaded(let summary) = viewModel.state else {
            return XCTFail("Expected loaded state")
        }
        XCTAssertEqual(summary.sales.salesCount, 8)
        XCTAssertEqual(viewModel.visibleQuickActions.count, DashboardQuickActionsFactory.actions.count)
    }

    func testRefreshPublishesFailedStateWhenRepositoryFails() async {
        let sessionStore = AuthSessionStore(
            tokenStore: InMemoryAuthTokenStore(),
            organizationSelectionStore: InMemoryOrganizationSelectionStore()
        )
        sessionStore.markAuthenticated(context: DashboardTestData.context(permissions: []))

        let repository = FakeDashboardRepository(result: .failure(AppError.server("Dashboard no disponible")))
        let viewModel = DashboardViewModel(
            getSummary: GetDashboardSummaryUseCase(repository: repository),
            sessionStore: sessionStore
        )

        await viewModel.refresh()

        XCTAssertEqual(viewModel.state, .failed("Dashboard no disponible"))
    }

    func testQuickActionsRespectEffectivePermissions() async {
        let sessionStore = AuthSessionStore(
            tokenStore: InMemoryAuthTokenStore(),
            organizationSelectionStore: InMemoryOrganizationSelectionStore()
        )
        sessionStore.markAuthenticated(
            context: DashboardTestData.context(permissions: [PermissionCatalog.catalogLocalView])
        )

        let repository = FakeDashboardRepository(result: .success(DashboardTestData.summary()))
        let viewModel = DashboardViewModel(
            getSummary: GetDashboardSummaryUseCase(repository: repository),
            sessionStore: sessionStore
        )

        await viewModel.load()

        XCTAssertEqual(viewModel.visibleQuickActions.map(\.id), ["catalog"])
    }
}

private final class FakeDashboardRepository: DashboardRepository, @unchecked Sendable {
    let result: Result<DashboardSummary, Error>

    init(result: Result<DashboardSummary, Error>) {
        self.result = result
    }

    func summary(period: DashboardPeriod) async throws -> DashboardSummary {
        try result.get()
    }
}

private enum DashboardTestData {
    static func summary() -> DashboardSummary {
        DashboardSummary(
            generatedAt: "2026-05-21T00:00:00Z",
            sales: DashboardSalesSummary(
                grossTotal: DashboardMoney(amount: 120, currency: "USD"),
                netTotal: DashboardMoney(amount: 110, currency: "USD"),
                collectedTotal: DashboardMoney(amount: 90, currency: "USD"),
                receivableTotal: DashboardMoney(amount: 20, currency: "USD"),
                salesCount: 8,
                canceledCount: 1,
                pendingCount: 2,
                averageTicket: DashboardMoney(amount: 13.75, currency: "USD")
            ),
            cash: .empty,
            documents: .empty,
            signature: .empty,
            alerts: [
                DashboardAlert(
                    id: "alert_1",
                    title: "Firma por vencer",
                    message: "La firma vence pronto.",
                    severity: .warning,
                    category: .signature,
                    createdAt: nil,
                    actionTitle: "Revisar",
                    destination: .signature
                )
            ],
            quickActions: DashboardQuickActionsFactory.actions
        )
    }

    static func context(permissions: Set<String>) -> MeContext {
        let user = AdminUser(
            id: "usr_1",
            email: "admin@nexo.test",
            displayName: "Admin",
            status: "active",
            phone: nil
        )
        let session = CurrentSession(
            id: "ses_1",
            userId: "usr_1",
            status: "active",
            createdAt: "2026-05-21T00:00:00Z",
            expiresAt: "2026-05-22T00:00:00Z",
            lastSeenAt: nil
        )
        let organization = AdminOrganization(
            id: "org_1",
            countryCode: "EC",
            taxId: "1790000000001",
            legalName: "Nexo Test",
            commercialName: "Nexo Test",
            status: "active",
            ownerUserId: "usr_1"
        )
        let membership = AdminMembership(
            id: "mem_1",
            organizationId: "org_1",
            userId: "usr_1",
            roleIds: ["role_owner"],
            status: "active"
        )
        return MeContext(
            user: user,
            currentSession: session,
            memberships: [],
            activeOrganization: organization,
            activeMembership: membership,
            roles: [],
            effectivePermissions: permissions
        )
    }
}

private final class InMemoryAuthTokenStore: AuthTokenStorage, @unchecked Sendable {
    private var tokens: SessionTokens?

    func saveTokens(_ tokens: SessionTokens) throws { self.tokens = tokens }
    func readTokens() throws -> SessionTokens? { tokens }
    func clearTokens() throws { tokens = nil }
}

private final class InMemoryOrganizationSelectionStore: OrganizationSelectionStoring, @unchecked Sendable {
    var selectedOrganizationId: String?

    func selectOrganization(id: String?) { selectedOrganizationId = id }
    func clearSelectedOrganization() { selectedOrganizationId = nil }
}
