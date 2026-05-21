//
//  AdminAccessHomeView.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import SwiftUI

struct AdminAccessHomeView: View {
    @ObservedObject var sessionStore: AuthSessionStore
    let repository: any AdminAccessRepository
    let onLogout: () -> Void

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
                    Button(role: .destructive, action: onLogout) {
                        Label("Cerrar sesión", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }

                Section("Acceso administrativo") {
                    if permissions.canAny([PermissionCatalog.credentialsUsersView, PermissionCatalog.credentialsUsersCreate]) {
                        NavigationLink {
                            AdminUsersView(viewModel: AdminUsersViewModel(repository: repository))
                        } label: {
                            AdminAccessHomeRow(
                                title: "Usuarios",
                                subtitle: "Listar, crear temporales, bloquear, resetear y revocar sesiones",
                                systemImage: "person.2.fill"
                            )
                        }
                    }

                    if permissions.can(PermissionCatalog.credentialsUsersInvite) {
                        NavigationLink {
                            AdminInvitationsView(viewModel: AdminInvitationsViewModel(repository: repository))
                        } label: {
                            AdminAccessHomeRow(
                                title: "Invitaciones",
                                subtitle: "Crear, reenviar y revocar invitaciones pendientes",
                                systemImage: "envelope.badge.person.crop.fill"
                            )
                        }
                    }

                    if permissions.canAny([PermissionCatalog.credentialsRolesView, PermissionCatalog.credentialsRolesManage]) {
                        NavigationLink {
                            AdminRolesView(viewModel: AdminRolesViewModel(repository: repository))
                        } label: {
                            AdminAccessHomeRow(
                                title: "Roles",
                                subtitle: "Ver roles del negocio, crear roles custom y ajustar permisos",
                                systemImage: "person.badge.key.fill"
                            )
                        }
                    }

                    if permissions.can(PermissionCatalog.credentialsRolesView) {
                        NavigationLink {
                            AdminPermissionsView(viewModel: AdminPermissionsViewModel(repository: repository))
                        } label: {
                            AdminAccessHomeRow(
                                title: "Permisos",
                                subtitle: "Catálogo efectivo publicado por backend",
                                systemImage: "checkmark.shield.fill"
                            )
                        }
                    }
                }

                Section("Seguridad") {
                    Text("Toda mutación crítica exige motivo y vuelve a ser validada por el backend. La app solo muestra acciones permitidas por permisos efectivos.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .overlay {
                if !permissions.canAny([
                    PermissionCatalog.credentialsUsersView,
                    PermissionCatalog.credentialsUsersCreate,
                    PermissionCatalog.credentialsUsersInvite,
                    PermissionCatalog.credentialsRolesView,
                    PermissionCatalog.credentialsRolesManage
                ]) {
                    EmptyStateView(
                        systemImage: "lock.fill",
                        title: "Sin permisos administrativos",
                        message: "Tu usuario no tiene permisos efectivos para administrar usuarios, roles o permisos."
                    )
                }
            }
            .navigationTitle("Admin")
        }
    }
}

private struct AdminAccessHomeRow: View {
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
