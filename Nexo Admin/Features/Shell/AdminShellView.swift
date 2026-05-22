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
    let adminCatalogRepository: any AdminCatalogRepository
    let adminTaxSriRepository: any AdminTaxSriRepository
    let adminElectronicDocumentRepository: any AdminElectronicDocumentRepository
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

            AdminBusinessHomeView(
                sessionStore: sessionStore,
                repository: adminBusinessRepository
            )
            .tabItem { Label("Negocio", systemImage: "building.2") }

            AdminCatalogHomeView(
                sessionStore: sessionStore,
                repository: adminCatalogRepository
            )
            .tabItem { Label("Catálogo", systemImage: "square.grid.2x2") }

            FiscalSriShellView(
                sessionStore: sessionStore,
                taxSriRepository: adminTaxSriRepository,
                electronicDocumentRepository: adminElectronicDocumentRepository
            )
            .tabItem { Label("Fiscal/SRI", systemImage: "doc.text.magnifyingglass") }

            AdminAccessHomeView(
                sessionStore: sessionStore,
                repository: adminAccessRepository,
                onLogout: onLogout
            )
            .tabItem { Label("Admin", systemImage: "person.crop.circle") }
        }
    }
}

private struct FiscalSriShellView: View {
    @ObservedObject var sessionStore: AuthSessionStore
    let taxSriRepository: any AdminTaxSriRepository
    let electronicDocumentRepository: any AdminElectronicDocumentRepository

    var body: some View {
        NavigationStack {
            List {
                NavigationLink {
                    AdminTaxSriHomeView(
                        sessionStore: sessionStore,
                        repository: taxSriRepository
                    )
                } label: {
                    Label("Tributario, firma y SRI", systemImage: "checklist.checked")
                }

                NavigationLink {
                    AdminElectronicDocumentsView(
                        viewModel: AdminElectronicDocumentsViewModel(
                            repository: electronicDocumentRepository,
                            permissions: sessionStore.effectivePermissions
                        )
                    )
                } label: {
                    Label("Comprobantes electrónicos", systemImage: "doc.text.magnifyingglass")
                }
            }
            .navigationTitle("Fiscal/SRI")
        }
    }
}
