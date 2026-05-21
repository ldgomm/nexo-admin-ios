//
//  AdminShellView.swift
//  Nexo Admin
//
//  Created by José Ruiz on 20/5/26.
//

import SwiftUI

struct AdminShellView: View {
    @ObservedObject var sessionStore: AuthSessionStore
    let dashboardRepository: any DashboardRepository
    let onLogout: () -> Void

    var body: some View {
        TabView {
            DashboardView(
                viewModel: DashboardViewModel(
                    getSummary: GetDashboardSummaryUseCase(repository: dashboardRepository),
                    sessionStore: sessionStore
                )
            )
            .tabItem { Label("Inicio", systemImage: "chart.bar.doc.horizontal") }

            BusinessPlaceholderView(sessionStore: sessionStore)
                .tabItem { Label("Negocio", systemImage: "building.2") }

            CatalogPlaceholderView(sessionStore: sessionStore)
                .tabItem { Label("Catálogo", systemImage: "square.grid.2x2") }

            FiscalPlaceholderView(sessionStore: sessionStore)
                .tabItem { Label("Fiscal/SRI", systemImage: "doc.text.magnifyingglass") }

            AdminProfileView(sessionStore: sessionStore, onLogout: onLogout)
                .tabItem { Label("Admin", systemImage: "person.crop.circle") }
        }
    }
}

private struct BusinessPlaceholderView: View {
    @ObservedObject var sessionStore: AuthSessionStore

    var body: some View {
        PlaceholderModuleView(
            title: "Negocio",
            systemImage: "building.2.fill",
            message: "Datos del negocio, actividades, sucursales, horarios y puntos de emisión entran en el sprint de configuración del negocio.",
            permissions: sessionStore.effectivePermissions,
            required: [PermissionCatalog.organizationView, PermissionCatalog.organizationUpdate, PermissionCatalog.activitiesView]
        )
    }
}

private struct CatalogPlaceholderView: View {
    @ObservedObject var sessionStore: AuthSessionStore

    var body: some View {
        PlaceholderModuleView(
            title: "Catálogo",
            systemImage: "square.grid.2x2.fill",
            message: "Catálogo local, búsqueda, copia desde maestro y solicitudes entran después de estabilizar dashboard + usuarios.",
            permissions: sessionStore.effectivePermissions,
            required: [PermissionCatalog.catalogLocalView, PermissionCatalog.catalogLocalManage]
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
            required: [PermissionCatalog.taxSettingsView, PermissionCatalog.taxManage]
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
