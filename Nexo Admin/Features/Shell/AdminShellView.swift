//
//  AdminShellView.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import SwiftUI

private enum AdminShellTab: CaseIterable, Hashable {
    case dashboard
    case business
    case catalog
    case fiscalSri
    case reports
    case admin
    
    var title: String {
        switch self {
        case .dashboard: return "Inicio"
        case .business: return "Negocio"
        case .catalog: return "Catálogo"
        case .fiscalSri: return "Fiscal/SRI"
        case .reports: return "Reportes"
        case .admin: return "Admin"
        }
    }
    
    var systemImage: String {
        switch self {
        case .dashboard: return "chart.bar.doc.horizontal"
        case .business: return "building.2"
        case .catalog: return "square.grid.2x2"
        case .fiscalSri: return "doc.text.magnifyingglass"
        case .reports: return "chart.xyaxis.line"
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
    let onLogout: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            selectedContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            Divider()
            
            bottomBar
        }
    }
    
    private var selectedContent: AnyView {
        switch selectedTab {
        case .dashboard:
            return AnyView(
                DashboardView(
                    viewModel: DashboardViewModel(
                        getSummary: GetDashboardSummaryUseCase(repository: dashboardRepository),
                        sessionStore: sessionStore
                    )
                )
            )
            
        case .business:
            return AnyView(
                AdminBusinessHomeView(
                    sessionStore: sessionStore,
                    repository: adminBusinessRepository
                )
            )
            
        case .catalog:
            return AnyView(
                AdminCatalogHomeView(
                    sessionStore: sessionStore,
                    repository: adminCatalogRepository
                )
            )
            
        case .fiscalSri:
            return AnyView(
                FiscalSriShellView(
                    sessionStore: sessionStore,
                    taxSriRepository: adminTaxSriRepository,
                    electronicDocumentRepository: adminElectronicDocumentRepository
                )
            )
            
        case .reports:
            return AnyView(
                AdminOperationsView(
                    viewModel: AdminOperationsViewModel(
                        repository: adminOperationsRepository,
                        permissions: sessionStore.effectivePermissions
                    )
                )
            )
            
        case .admin:
            return AnyView(
                AdminAccessHomeView(
                    sessionStore: sessionStore,
                    repository: adminAccessRepository,
                    onLogout: onLogout
                )
            )
        }
    }
    
    private var bottomBar: some View {
        HStack(spacing: 0) {
            ForEach(AdminShellTab.allCases, id: \.self) { tab in
                Button {
                    selectedTab = tab
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.systemImage)
                            .font(.system(size: 18, weight: selectedTab == tab ? .semibold : .regular))
                        
                        Text(tab.title)
                            .font(.caption2)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .foregroundStyle(selectedTab == tab ? Color.accentColor : Color.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .background(.bar)
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
