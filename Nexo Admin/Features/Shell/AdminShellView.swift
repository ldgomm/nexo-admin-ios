import SwiftUI

struct AdminShellView: View {
    @ObservedObject var sessionStore: AuthSessionStore
    let dashboardRepository: any DashboardRepository
    let adminAccessRepository: any AdminAccessRepository
    let adminBusinessRepository: any AdminBusinessRepository
    let adminCatalogRepository: any AdminCatalogRepository
    let adminTaxSriRepository: any AdminTaxSriRepository
    let onLogout: () -> Void

    @State private var selectedTab: AdminShellTab = .dashboard

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView(
                viewModel: DashboardViewModel(
                    getSummary: GetDashboardSummaryUseCase(repository: dashboardRepository),
                    sessionStore: sessionStore
                ),
                onQuickAction: navigate(to:)
            )
            .tabItem { Label("Inicio", systemImage: "chart.bar.doc.horizontal") }
            .tag(AdminShellTab.dashboard)

            AdminBusinessHomeView(
                sessionStore: sessionStore,
                repository: adminBusinessRepository
            )
            .tabItem { Label("Negocio", systemImage: "building.2") }
            .tag(AdminShellTab.business)

            AdminCatalogHomeView(
                sessionStore: sessionStore,
                repository: adminCatalogRepository
            )
            .tabItem { Label("Catálogo", systemImage: "square.grid.2x2") }
            .tag(AdminShellTab.catalog)

            AdminTaxSriHomeView(
                sessionStore: sessionStore,
                repository: adminTaxSriRepository
            )
                .tabItem { Label("Fiscal/SRI", systemImage: "doc.text.magnifyingglass") }
                .tag(AdminShellTab.fiscal)

            AdminAccessHomeView(
                sessionStore: sessionStore,
                repository: adminAccessRepository,
                onLogout: onLogout
            )
            .tabItem { Label("Admin", systemImage: "person.crop.circle") }
            .tag(AdminShellTab.admin)
        }
    }

    private func navigate(to destination: DashboardQuickActionDestination) {
        switch destination {
        case .business, .branches, .emissionPoints:
            selectedTab = .business
        case .catalog, .catalogRequests:
            selectedTab = .catalog
        case .tax, .signature, .sri, .documents:
            selectedTab = .fiscal
        case .users, .roles, .audit, .support:
            selectedTab = .admin
        case .cash:
            selectedTab = .dashboard
        }
    }
}

private enum AdminShellTab: Hashable {
    case dashboard
    case business
    case catalog
    case fiscal
    case admin
}
