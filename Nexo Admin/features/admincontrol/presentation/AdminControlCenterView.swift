//
//  AdminControlCenterView.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import SwiftUI

struct AdminControlCenterView: View {
    @ObservedObject var sessionStore: AuthSessionStore
    let adminAccessRepository: any AdminAccessRepository
    let adminOperationsRepository: any AdminOperationsRepository
    let adminPublicProjectionRepository: any AdminPublicProjectionRepository
    let adminSupportRepository: any AdminSupportRepository
    let onChangeOrganization: () -> Void
    let onLogout: () -> Void

    init(
        sessionStore: AuthSessionStore,
        adminAccessRepository: any AdminAccessRepository,
        adminOperationsRepository: any AdminOperationsRepository,
        adminPublicProjectionRepository: any AdminPublicProjectionRepository,
        adminSupportRepository: any AdminSupportRepository,
        onChangeOrganization: @escaping () -> Void = {},
        onLogout: @escaping () -> Void
    ) {
        self.sessionStore = sessionStore
        self.adminAccessRepository = adminAccessRepository
        self.adminOperationsRepository = adminOperationsRepository
        self.adminPublicProjectionRepository = adminPublicProjectionRepository
        self.adminSupportRepository = adminSupportRepository
        self.onChangeOrganization = onChangeOrganization
        self.onLogout = onLogout
    }

    private var permissions: PermissionSet { PermissionSet(sessionStore.effectivePermissions) }

    var body: some View {
        NavigationStack {
            List {
                Section("Usuario") {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(sessionStore.currentUser?.displayName ?? "Admin")
                            .font(.headline)
                        Text(sessionStore.currentUser?.email ?? "—")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(sessionStore.activeOrganization?.commercialName ?? sessionStore.activeOrganization?.legalName ?? "Organización activa")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Button(action: onChangeOrganization) {
                        Label("Cambiar organización", systemImage: "building.2.crop.circle")
                    }

                    Button(role: .destructive, action: onLogout) {
                        Label("Cerrar sesión", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }

                Section("Acceso y seguridad") {
                    NavigationLink {
                        AdminAccessHomeView(
                            sessionStore: sessionStore,
                            repository: adminAccessRepository,
                            onLogout: onLogout
                        )
                    } label: {
                        AdminControlRow(
                            title: "Usuarios, roles y permisos",
                            subtitle: "Cuentas, invitaciones, resets, bloqueos y permisos efectivos",
                            systemImage: "person.badge.key.fill"
                        )
                    }
                }

                Section("Operación y auditoría") {
                    if permissions.canAny([PermissionCatalog.reportsDashboardView, PermissionCatalog.reportsSalesView, PermissionCatalog.cashView, PermissionCatalog.auditView]) {
                        NavigationLink {
                            AdminOperationsView(
                                viewModel: AdminOperationsViewModel(
                                    repository: adminOperationsRepository,
                                    permissions: sessionStore.effectivePermissions
                                )
                            )
                        } label: {
                            AdminControlRow(
                                title: "Reportes, caja y auditoría",
                                subtitle: "Consulta administrativa; no reemplaza la Business App",
                                systemImage: "chart.xyaxis.line"
                            )
                        }
                    }

                    if permissions.canAny([PermissionCatalog.publicProjectionView, PermissionCatalog.publicProjectionManage, PermissionCatalog.publicStorefrontView, PermissionCatalog.publicStorefrontManage]) {
                        NavigationLink {
                            AdminPublicProjectionView(
                                viewModel: AdminPublicProjectionViewModel(
                                    repository: adminPublicProjectionRepository,
                                    permissions: sessionStore.effectivePermissions
                                )
                            )
                        } label: {
                            AdminControlRow(
                                title: "Public Projection",
                                subtitle: "Storefront futuro, privado por defecto y publicación controlada",
                                systemImage: "globe.badge.chevron.backward"
                            )
                        }
                    }
                }

                Section("Soporte") {
                    if permissions.canAny([PermissionCatalog.supportView, PermissionCatalog.supportDiagnosticsView, PermissionCatalog.healthView, PermissionCatalog.observabilityView, PermissionCatalog.devicesView]) {
                        NavigationLink {
                            AdminSupportDiagnosticsView(
                                viewModel: AdminSupportDiagnosticsViewModel(
                                    repository: adminSupportRepository,
                                    permissions: sessionStore.effectivePermissions,
                                    buildInfoProvider: { BuildInfo.current() }
                                )
                            )
                        } label: {
                            AdminControlRow(
                                title: "Diagnóstico y dispositivos",
                                subtitle: "Health, versión API, device registry y trazabilidad móvil",
                                systemImage: "stethoscope"
                            )
                        }
                    }

                    NavigationLink {
                        ReleaseReadinessView(
                            viewModel: ReleaseReadinessViewModel(sessionStore: sessionStore)
                        )
                    } label: {
                        AdminControlRow(
                            title: "Hardening y TestFlight",
                            subtitle: "Checklist local del corte interno",
                            systemImage: "checkmark.seal.fill"
                        )
                    }
                }
            }
            .navigationTitle("Admin")
        }
    }
}

private struct AdminControlRow: View {
    let title: String
    let subtitle: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.title3.weight(.semibold))
                .frame(width: 34)
                .foregroundStyle(Color.accentColor)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
