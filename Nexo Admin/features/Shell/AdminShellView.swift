//
//  AdminShellView.swift
//  Nexo Admin
//
//  Created by José Ruiz on 2/6/26.
//

import SwiftUI

private enum AdminShellTab: CaseIterable, Hashable {
    case dashboard
    case business
    case fiscalSri
    case modules
    case admin

    var title: String {
        switch self {
        case .dashboard: return "Inicio"
        case .business: return "Negocio"
        case .fiscalSri: return "Fiscal/SRI"
        case .modules: return "Módulos"
        case .admin: return "Admin"
        }
    }

    
    var systemImage: String {
        switch self {
        case .dashboard: return "chart.bar.doc.horizontal"
        case .business: return "building.2"
        case .fiscalSri: return "doc.text.magnifyingglass"
        case .modules: return "puzzlepiece.extension"
        case .admin: return "person.crop.circle"
        }
    }
}

struct AdminShellView: View {
    @ObservedObject var sessionStore: AuthSessionStore
    @State private var selectedTab: AdminShellTab = .dashboard

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
    let adminRoleTemplateRepository: any AdminRoleTemplateRepository
    let onChangeOrganization: () -> Void
    let onLogout: () -> Void

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView(
                viewModel: DashboardViewModel(
                    getSummary: GetDashboardSummaryUseCase(repository: dashboardRepository),
                    sessionStore: sessionStore
                ),
                onQuickAction: handleDashboardQuickAction
            )
            .tabItem {
                Label(AdminShellTab.dashboard.title, systemImage: AdminShellTab.dashboard.systemImage)
            }
            .tag(AdminShellTab.dashboard)

            AdminBusinessHomeView(
                sessionStore: sessionStore,
                repository: adminBusinessRepository,
                catalogRepository: adminCatalogRepository,
                foundationRepository: adminFoundationRepository
            )
            .tabItem {
                Label(AdminShellTab.business.title, systemImage: AdminShellTab.business.systemImage)
            }
            .tag(AdminShellTab.business)

            FiscalSriShellView(
                sessionStore: sessionStore,
                taxSriRepository: adminTaxSriRepository,
                electronicDocumentRepository: adminElectronicDocumentRepository
            )
            .tabItem {
                Label(AdminShellTab.fiscalSri.title, systemImage: AdminShellTab.fiscalSri.systemImage)
            }
            .tag(AdminShellTab.fiscalSri)

            AdminModulesCenterView(
                sessionStore: sessionStore,
                foundationRepository: adminFoundationRepository
            )
            .tabItem {
                Label(AdminShellTab.modules.title, systemImage: AdminShellTab.modules.systemImage)
            }
            .tag(AdminShellTab.modules)

            AdminControlCenterView(
                sessionStore: sessionStore,
                adminAccessRepository: adminAccessRepository,
                adminOperationsRepository: adminOperationsRepository,
                adminPublicProjectionRepository: adminPublicProjectionRepository,
                adminSupportRepository: adminSupportRepository,
                adminRoleTemplateRepository: adminRoleTemplateRepository,
                onChangeOrganization: onChangeOrganization,
                onLogout: onLogout
            )
            .tabItem {
                Label(AdminShellTab.admin.title, systemImage: AdminShellTab.admin.systemImage)
            }
            .tag(AdminShellTab.admin)
        }
    }

    private func handleDashboardQuickAction(_ destination: DashboardQuickActionDestination) {
        switch destination {
        case .business, .branches, .emissionPoints, .catalog, .catalogRequests:
            selectedTab = .business

        case .tax, .signature, .sri, .documents:
            selectedTab = .fiscalSri

        case .users, .roles, .cash, .audit, .support:
            selectedTab = .admin
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
