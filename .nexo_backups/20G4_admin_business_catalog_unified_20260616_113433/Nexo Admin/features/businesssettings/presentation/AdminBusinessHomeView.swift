//
//  AdminBusinessHomeView.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import SwiftUI

struct AdminBusinessHomeView: View {
    @ObservedObject var sessionStore: AuthSessionStore
    @StateObject private var viewModel: AdminBusinessViewModel
    let foundationRepository: any AdminFoundationRepository
    
    init(sessionStore: AuthSessionStore, repository: any AdminBusinessRepository, foundationRepository: any AdminFoundationRepository) {
        self.sessionStore = sessionStore
        _viewModel = StateObject(wrappedValue: AdminBusinessViewModel(repository: repository))
        self.foundationRepository = foundationRepository
    }
    
    var body: some View {
        NavigationStack {
            PermissionGate(
                permissions: sessionStore.effectivePermissions,
                required: [
                    PermissionCatalog.organizationView,
                    PermissionCatalog.activitiesView,
                    PermissionCatalog.branchesView,
                    PermissionCatalog.settingsBranchesView,
                    PermissionCatalog.emissionPointsView,
                    PermissionCatalog.settingsEmissionPointsView,
                    PermissionCatalog.modulesView,
                    PermissionCatalog.modulesManage
                ]
            ) {
                content
                    .navigationTitle("Negocio")
                    .toolbar { ToolbarItem(placement: .topBarTrailing) { refreshButton } }
                    .task { if viewModel.overview == nil { await viewModel.load() } }
                    .refreshable { await viewModel.refresh() }
            } fallback: {
                EmptyStateView(
                    systemImage: "lock.fill",
                    title: "Sin permiso",
                    message: "Tu usuario no tiene permisos para ver la configuración del negocio. El backend también valida cada acción."
                )
                .navigationTitle("Negocio")
            }
        }
        .alert("Error", isPresented: errorBinding) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .alert("Listo", isPresented: successBinding) {
            Button("OK") { viewModel.successMessage = nil }
        } message: {
            Text(viewModel.successMessage ?? "")
        }
    }
    
    private var content: some View {
        Group {
            if viewModel.isLoading && viewModel.overview == nil {
                VStack(spacing: 14) {
                    ProgressView()
                    Text("Cargando configuración…")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let overview = viewModel.overview {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        AdminBusinessOverviewCard(overview: overview)
                        metricGrid(overview.counts)
                        nextActions(overview.nextActions)
                        navigationCards
                    }
                    .padding()
                }
            } else {
                EmptyStateView(
                    systemImage: "building.2.crop.circle",
                    title: "Sin datos de negocio",
                    message: "No se pudo cargar la configuración. Revisa conexión, sesión y organización activa."
                )
            }
        }
    }
    
    private func metricGrid(_ counts: AdminBusinessFoundationCounts) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            AdminBusinessMetricCard(
                title: "Actividades",
                value: "\(counts.activeActivities)/\(counts.totalActivities)",
                subtitle: "Activas configuradas",
                systemImage: "square.stack.3d.up"
            )
            AdminBusinessMetricCard(
                title: "Sucursales",
                value: "\(counts.activeBranches)/\(counts.totalBranches)",
                subtitle: "Puntos operativos activos",
                systemImage: "mappin.and.ellipse"
            )
            AdminBusinessMetricCard(
                title: "Emisión",
                value: "\(counts.activeEmissionPoints)/\(counts.totalEmissionPoints)",
                subtitle: "Puntos SRI activos",
                systemImage: "number.square"
            )
            AdminBusinessMetricCard(
                title: "Readiness",
                value: "\(counts.readyChecks)/\(counts.readinessChecks)",
                subtitle: "Checks listos",
                systemImage: "checklist.checked"
            )
        }
    }
    
    private func nextActions(_ actions: [AdminBusinessNextAction]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            AdminBusinessSectionHeader(
                title: "Siguientes acciones",
                subtitle: actions.isEmpty ? "La base del negocio está lista para operar." : "Corrige estos puntos antes de operar ventas, caja o emisión documental.",
                systemImage: actions.isEmpty ? "checkmark.seal" : "exclamationmark.triangle"
            )
            if actions.isEmpty {
                Text("Sin pendientes críticos.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
            } else {
                ForEach(actions) { action in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: action.required ? "exclamationmark.circle.fill" : "info.circle.fill")
                        VStack(alignment: .leading, spacing: 4) {
                            Text(action.action)
                                .font(.subheadline.weight(.semibold))
                            Text(action.code.readableSnakeCase)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        AdminBusinessStatusBadge(title: action.status.title, systemImage: "circle.fill", emphasis: action.required)
                    }
                    .padding(12)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
                }
            }
        }
    }
    
    private var navigationCards: some View {
        VStack(spacing: 10) {
            NavigationLink {
                AdminBusinessProfileView(viewModel: viewModel, permissions: sessionStore.effectivePermissions)
            } label: {
                AdminBusinessNavigationRow(title: "Datos del negocio", subtitle: "Razón social, nombre comercial, moneda y zona horaria", systemImage: "building.columns")
            }
            NavigationLink {
                AdminActivitiesView(viewModel: viewModel, permissions: sessionStore.effectivePermissions)
            } label: {
                AdminBusinessNavigationRow(title: "Actividades", subtitle: "Restaurant, retail, servicios, turismo o mixto", systemImage: "square.stack.3d.up")
            }
            NavigationLink {
                AdminBranchesView(viewModel: viewModel, permissions: sessionStore.effectivePermissions)
            } label: {
                AdminBusinessNavigationRow(title: "Sucursales y ubicación", subtitle: "Dirección simple, privacidad y horario asociado", systemImage: "mappin.and.ellipse")
            }
            NavigationLink {
                AdminEmissionPointsView(viewModel: viewModel, permissions: sessionStore.effectivePermissions)
            } label: {
                AdminBusinessNavigationRow(title: "Puntos de emisión", subtitle: "Establecimiento, punto de emisión y estado", systemImage: "number.square")
            }
            NavigationLink {
                AdminBusinessReadinessView(viewModel: viewModel)
            } label: {
                AdminBusinessNavigationRow(title: "Readiness operativo", subtitle: "Checklist para operar ventas, caja y documentos", systemImage: "checklist.checked")
            }
            NavigationLink {
                AdminFoundationHomeView(
                    viewModel: AdminFoundationViewModel(
                        repository: foundationRepository,
                        permissions: sessionStore.effectivePermissions
                    )
                )
            } label: {
                AdminBusinessNavigationRow(
                    title: "Módulos y foundation v2.4",
                    subtitle: "Business Context, módulos activos, catalog revision, realtime y readiness",
                    systemImage: "puzzlepiece.extension"
                )
            }
        }
        .buttonStyle(.plain)
    }
    
    private var refreshButton: some View {
        Button { Task { await viewModel.refresh() } } label: {
            if viewModel.isLoading { ProgressView().controlSize(.small) } else { Image(systemName: "arrow.clockwise") }
        }
    }
    
    private var errorBinding: Binding<Bool> {
        Binding(get: { viewModel.errorMessage != nil }, set: { if !$0 { viewModel.errorMessage = nil } })
    }
    
    private var successBinding: Binding<Bool> {
        Binding(get: { viewModel.successMessage != nil }, set: { if !$0 { viewModel.successMessage = nil } })
    }
}

private struct AdminBusinessOverviewCard: View {
    let overview: AdminBusinessOverview
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(overview.business.displayName)
                        .font(.title2.bold())
                    Text(overview.business.fiscalSummary)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                AdminBusinessStatusBadge(
                    title: overview.ready ? "Operable" : overview.overallStatus.title,
                    systemImage: overview.ready ? "checkmark.seal.fill" : "exclamationmark.triangle.fill",
                    emphasis: !overview.ready
                )
            }
            Divider()
            HStack {
                Label(overview.business.status.title, systemImage: "circle.fill")
                Spacer()
                Text(overview.business.timezone ?? "Sin zona horaria")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

private struct AdminBusinessNavigationRow: View {
    let title: String
    let subtitle: String
    let systemImage: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.title3.weight(.semibold))
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}
