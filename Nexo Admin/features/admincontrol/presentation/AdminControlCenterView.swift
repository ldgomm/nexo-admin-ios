//
//  AdminControlCenterView.swift
//  Nexo Admin
//
//  Created by José Ruiz on 2/6/26.
//

import Combine
import SwiftUI

struct AdminControlCenterView: View {
    @ObservedObject var sessionStore: AuthSessionStore
    let adminAccessRepository: any AdminAccessRepository
    let adminOperationsRepository: any AdminOperationsRepository
    let adminPublicProjectionRepository: any AdminPublicProjectionRepository
    let adminSupportRepository: any AdminSupportRepository
    let adminRoleTemplateRepository: any AdminRoleTemplateRepository
    let onChangeOrganization: () -> Void
    let onLogout: () -> Void

    init(
        sessionStore: AuthSessionStore,
        adminAccessRepository: any AdminAccessRepository,
        adminOperationsRepository: any AdminOperationsRepository,
        adminPublicProjectionRepository: any AdminPublicProjectionRepository,
        adminSupportRepository: any AdminSupportRepository,
        adminRoleTemplateRepository: any AdminRoleTemplateRepository,
        onChangeOrganization: @escaping () -> Void = {},
        onLogout: @escaping () -> Void
    ) {
        self.sessionStore = sessionStore
        self.adminAccessRepository = adminAccessRepository
        self.adminOperationsRepository = adminOperationsRepository
        self.adminPublicProjectionRepository = adminPublicProjectionRepository
        self.adminSupportRepository = adminSupportRepository
        self.adminRoleTemplateRepository = adminRoleTemplateRepository
        self.onChangeOrganization = onChangeOrganization
        self.onLogout = onLogout
    }

    private var permissions: PermissionSet { PermissionSet(sessionStore.effectivePermissions) }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    adminHero
                    accountActions
                    accessSection
                    operationsSection
                    supportSection
                }
                .padding(16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Admin")
        }
    }

    private var adminHero: some View {
        NexoAdminUXHeroCard(
            eyebrow: "Centro de control",
            title: sessionStore.currentUser?.displayName ?? "Admin",
            subtitle: "\(sessionStore.currentUser?.email ?? "—") · \(organizationName)",
            systemImage: "person.badge.key.fill",
            badgeTitle: "\(sessionStore.effectivePermissions.count) permisos",
            badgeSystemImage: "key.fill"
        )
    }

    private var accountActions: some View {
        NexoAdminUXCard {
            NexoAdminUXSectionHeader(
                "Sesión y organización",
                subtitle: "Acciones visibles, directas y sin mezclarlas con configuración técnica.",
                systemImage: "person.crop.circle"
            )

            HStack(spacing: 10) {
                Button(action: onChangeOrganization) {
                    Label("Cambiar organización", systemImage: "building.2.crop.circle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Button(role: .destructive, action: onLogout) {
                    Label("Salir", systemImage: "rectangle.portrait.and.arrow.right")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
    }

    private var accessSection: some View {
        NexoAdminUXCard {
            NexoAdminUXSectionHeader(
                "Acceso y seguridad",
                subtitle: "Usuarios, roles y plantillas humanas. Los permisos técnicos siguen existiendo, pero no deben ser el lenguaje del usuario.",
                systemImage: "lock.shield"
            )

            VStack(spacing: 10) {
                NexoAdminUXNavigationTile(
                    title: "Centro de seguridad",
                    subtitle: "Sesiones activas, usuarios bloqueados y dispositivos excedidos",
                    systemImage: "shield.lefthalf.filled.badge.checkmark"
                ) {
                    AdminSecurityCenterView(repository: adminAccessRepository)
                }

                NexoAdminUXNavigationTile(
                    title: "Usuarios, roles y permisos",
                    subtitle: "Cuentas, invitaciones, resets, bloqueos y permisos efectivos",
                    systemImage: "person.badge.key.fill"
                ) {
                    AdminAccessHomeView(
                        sessionStore: sessionStore,
                        repository: adminAccessRepository,
                        onLogout: onLogout
                    )
                }

                NexoAdminUXNavigationTile(
                    title: "Plantillas de roles",
                    subtitle: "Crear roles locales por vertical para la organización activa",
                    systemImage: "person.3.sequence.fill"
                ) {
                    AdminRoleTemplateProvisioningView(
                        viewModel: AdminRoleTemplateProvisioningViewModel(
                            repository: adminRoleTemplateRepository
                        )
                    )
                }
            }
        }
    }

    @ViewBuilder
    private var operationsSection: some View {
        if canViewOperations || canViewPublicProjection {
            NexoAdminUXCard {
                NexoAdminUXSectionHeader(
                    "Operación y publicación",
                    subtitle: "Diagnóstico administrativo sin reemplazar la Business App.",
                    systemImage: "chart.xyaxis.line"
                )

                VStack(spacing: 10) {
                    if canViewOperations {
                        NexoAdminUXNavigationTile(
                            title: "Reportes, caja y auditoría",
                            subtitle: "Consulta administrativa; no reemplaza venta, cobro ni cierre desde Business",
                            systemImage: "chart.xyaxis.line"
                        ) {
                            AdminOperationsView(
                                viewModel: AdminOperationsViewModel(
                                    repository: adminOperationsRepository,
                                    permissions: sessionStore.effectivePermissions
                                )
                            )
                        }
                    }

                    if canViewPublicProjection {
                        NexoAdminUXNavigationTile(
                            title: "Public Projection",
                            subtitle: "Storefront futuro, privado por defecto y publicación controlada",
                            systemImage: "globe.badge.chevron.backward"
                        ) {
                            AdminPublicProjectionView(
                                viewModel: AdminPublicProjectionViewModel(
                                    repository: adminPublicProjectionRepository,
                                    permissions: sessionStore.effectivePermissions
                                )
                            )
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var supportSection: some View {
        NexoAdminUXCard {
            NexoAdminUXSectionHeader(
                "Soporte y salida a piloto",
                subtitle: "Health, versión, dispositivos y checklist TestFlight en una zona clara.",
                systemImage: "stethoscope"
            )

            VStack(spacing: 10) {
                if canViewSupport {
                    NexoAdminUXNavigationTile(
                        title: "Diagnóstico y dispositivos",
                        subtitle: "Health, versión API, device registry y trazabilidad móvil",
                        systemImage: "stethoscope"
                    ) {
                        AdminSupportDiagnosticsView(
                            viewModel: AdminSupportDiagnosticsViewModel(
                                repository: adminSupportRepository,
                                permissions: sessionStore.effectivePermissions,
                                buildInfoProvider: { BuildInfo.current() }
                            )
                        )
                    }
                }

                NexoAdminUXNavigationTile(
                    title: "Hardening y TestFlight",
                    subtitle: "Checklist local del corte interno antes de vender o pilotear",
                    systemImage: "checkmark.seal.fill"
                ) {
                    ReleaseReadinessView(
                        viewModel: ReleaseReadinessViewModel(sessionStore: sessionStore)
                    )
                }
            }
        }
    }

    private var organizationName: String {
        sessionStore.activeOrganization?.commercialName
        ?? sessionStore.activeOrganization?.legalName
        ?? "Organización activa"
    }

    private var canViewOperations: Bool {
        permissions.canAny([
            PermissionCatalog.reportsDashboardView,
            PermissionCatalog.reportsSalesView,
            PermissionCatalog.cashView,
            PermissionCatalog.auditView
        ])
    }

    private var canViewPublicProjection: Bool {
        permissions.canAny([
            PermissionCatalog.publicProjectionView,
            PermissionCatalog.publicProjectionManage,
            PermissionCatalog.publicStorefrontView,
            PermissionCatalog.publicStorefrontManage
        ])
    }

    private var canViewSupport: Bool {
        permissions.canAny([
            PermissionCatalog.supportView,
            PermissionCatalog.supportDiagnosticsView,
            PermissionCatalog.healthView,
            PermissionCatalog.observabilityView,
            PermissionCatalog.devicesView
        ])
    }
}


private struct AdminSecurityCenterView: View {
    @StateObject private var viewModel: AdminSecurityCenterViewModel

    init(repository: any AdminAccessRepository) {
        _viewModel = StateObject(wrappedValue: AdminSecurityCenterViewModel(repository: repository))
    }

    var body: some View {
        List {
            switch viewModel.state {
            case .idle, .loading:
                Section { ProgressView("Cargando seguridad…") }
            case .empty(let message):
                Section { EmptyStateView(systemImage: "shield", title: "Sin datos", message: message) }
            case .failed(let message):
                Section { ErrorStateView(title: "No se pudo cargar seguridad", message: message, retry: { Task { await viewModel.refresh() } }) }
            case .loaded(let users):
                Section("Resumen") {
                    LabeledContent("Usuarios", value: "\(users.count)")
                    LabeledContent("Bloqueados", value: "\(viewModel.blockedUsers.count)")
                    LabeledContent("Sesiones activas", value: "\(viewModel.totalActiveSessions)")
                    LabeledContent("Sobre límite", value: "\(viewModel.usersOverSessionLimit.count)")
                }

                if !viewModel.usersOverSessionLimit.isEmpty {
                    Section("Usuarios sobre límite") {
                        ForEach(viewModel.usersOverSessionLimit) { user in
                            NavigationLink {
                                AdminUserDetailView(viewModel: AdminUserDetailViewModel(userId: user.id, repository: viewModel.repository))
                            } label: {
                                AdminSecurityUserRow(user: user, warning: "\(user.activeSessionCount) sesiones")
                            }
                        }
                    }
                }

                if !viewModel.blockedUsers.isEmpty {
                    Section("Usuarios bloqueados") {
                        ForEach(viewModel.blockedUsers) { user in
                            NavigationLink {
                                AdminUserDetailView(viewModel: AdminUserDetailViewModel(userId: user.id, repository: viewModel.repository))
                            } label: {
                                AdminSecurityUserRow(user: user, warning: user.blockedReason ?? "Bloqueado")
                            }
                        }
                    }
                }

                Section("Todos los usuarios") {
                    ForEach(users) { user in
                        NavigationLink {
                            AdminUserDetailView(viewModel: AdminUserDetailViewModel(userId: user.id, repository: viewModel.repository))
                        } label: {
                            AdminSecurityUserRow(user: user, warning: user.activeSessionCount > 0 ? "\(user.activeSessionCount) sesiones" : user.statusLabel)
                        }
                    }
                }
            }
        }
        .navigationTitle("Seguridad")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { Task { await viewModel.refresh() } } label: { Image(systemName: "arrow.clockwise") }
            }
        }
        .task { await viewModel.load() }
        .refreshable { await viewModel.refresh() }
    }
}

@MainActor
private final class AdminSecurityCenterViewModel: ObservableObject {
    @Published private(set) var state: LoadableViewState<[AdminAccessUser]> = .idle

    let repository: any AdminAccessRepository
    private let listUsers: ListAdminUsersUseCase

    init(repository: any AdminAccessRepository) {
        self.repository = repository
        self.listUsers = ListAdminUsersUseCase(repository: repository)
    }

    var users: [AdminAccessUser] {
        guard case .loaded(let users) = state else { return [] }
        return users
    }

    var blockedUsers: [AdminAccessUser] {
        users.filter(\.isBlocked)
    }

    var usersOverSessionLimit: [AdminAccessUser] {
        users.filter { $0.activeSessionCount > 3 }
    }

    var totalActiveSessions: Int {
        users.reduce(0) { $0 + $1.activeSessionCount }
    }

    func load() async {
        if case .loaded = state { return }
        await refresh()
    }

    func refresh() async {
        state = .loading
        do {
            let loadedUsers = try await listUsers.execute(query: nil, status: nil, limit: 200)
            state = loadedUsers.isEmpty ? .empty("No hay usuarios para auditar.") : .loaded(loadedUsers)
        } catch {
            state = .failed(error.userFriendlyMessage)
        }
    }
}

private struct AdminSecurityUserRow: View {
    let user: AdminAccessUser
    let warning: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(user.displayName)
                    .font(.headline)
                Spacer()
                AdminAccessStatusBadge(text: warning, systemImage: user.activeSessionCount > 3 ? "exclamationmark.triangle.fill" : nil)
            }
            Text(user.email)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(user.statusLabel)
                .font(.caption)
                .foregroundStyle(user.isBlocked ? .red : .secondary)
        }
        .padding(.vertical, 4)
    }
}
