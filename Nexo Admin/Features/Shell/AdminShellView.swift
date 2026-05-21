//
//  AdminShellView.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import SwiftUI

struct AdminShellView: View {
    @ObservedObject var sessionStore: AuthSessionStore
    let dashboardRepository: any DashboardRepository
    let adminAccessRepository: any AdminAccessRepository
    let adminBusinessRepository: any AdminBusinessRepository
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

            CatalogPlaceholderView(sessionStore: sessionStore)
                .tabItem { Label("Catálogo", systemImage: "square.grid.2x2") }
                .tag(AdminShellTab.catalog)

            FiscalPlaceholderView(sessionStore: sessionStore)
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

private struct CatalogPlaceholderView: View {
    @ObservedObject var sessionStore: AuthSessionStore

    var body: some View {
        PlaceholderModuleView(
            title: "Catálogo",
            systemImage: "square.grid.2x2.fill",
            message: "Catálogo local, búsqueda, copia desde maestro, solicitudes e historial de precios entran después de configuración del negocio.",
            permissions: sessionStore.effectivePermissions,
            required: [
                PermissionCatalog.catalogLocalView,
                PermissionCatalog.catalogLocalCopyFromMaster,
                PermissionCatalog.catalogLocalUpdateLocalCopy,
                PermissionCatalog.catalogLocalRequestNewItem
            ]
        )
    }
}

private struct FiscalPlaceholderView: View {
    @ObservedObject var sessionStore: AuthSessionStore

    var body: some View {
        PlaceholderModuleView(
            title: "Fiscal/SRI",
            systemImage: "doc.text.fill",
            message: "Configuración tributaria, firma electrónica, readiness SRI, comprobantes, RIDE/XML y errores SRI deben venir desde backend.",
            permissions: sessionStore.effectivePermissions,
            required: [
                PermissionCatalog.taxSettingsView,
                PermissionCatalog.reportsTaxView,
                PermissionCatalog.signatureViewAudit,
                PermissionCatalog.documentsView,
                PermissionCatalog.documentsElectronicInvoiceView,
                PermissionCatalog.documentsElectronicInvoiceViewErrors
            ]
        )
    }
}

private struct PlaceholderModuleView: View {
    let title: String
    let systemImage: String
    let message: String
    let permissions: Set<String>
    let required: Set<String>

    var body: some View {
        NavigationStack {
            PermissionGate(permissions: permissions, required: required) {
                EmptyStateView(systemImage: systemImage, title: title, message: message)
                    .navigationTitle(title)
            } fallback: {
                EmptyStateView(
                    systemImage: "lock.fill",
                    title: "Sin permiso",
                    message: "Tu usuario no tiene permisos efectivos para este módulo. El backend también validará cada acción."
                )
                .navigationTitle(title)
            }
        }
    }
}
