//
//  AdminControlCenterView.swift
//  Nexo Admin
//
//  Created by José Ruiz on 2/6/26.
//

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
