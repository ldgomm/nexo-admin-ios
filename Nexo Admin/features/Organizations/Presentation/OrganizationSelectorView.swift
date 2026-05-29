//
//  OrganizationSelectorView.swift
//  Nexo Admin
//
//  Created by José Ruiz on 20/5/26.
//

import SwiftUI

struct OrganizationSelectorView: View {
    @StateObject var viewModel: OrganizationSelectorViewModel

    var body: some View {
        NavigationStack {
            List {
                heroSection

                if viewModel.hasOrganizations {
                    searchSection
                    organizationsSection
                } else {
                    noOrganizationsSection
                }

                if let infoMessage = viewModel.infoMessage {
                    Section {
                        Text(infoMessage)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                if let errorMessage = viewModel.errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
                }

                actionsSection
            }
            .navigationTitle("Organización")
            .overlay {
                if viewModel.isLoading {
                    ProgressView("Cargando permisos…")
                        .padding(18)
                        .background(.thinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
            }
            .onAppear { viewModel.refreshLocalData() }
        }
    }

    private var heroSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: "building.2.crop.circle.fill")
                    .font(.system(size: 42, weight: .semibold))
                    .foregroundStyle(Color.accentColor)

                Text("Selecciona el negocio que vas a administrar")
                    .font(.title2.bold())

                Text("Tu sesión es única. El negocio activo se envía al backend mediante X-Organization-Id y cada permiso se resuelve por organización.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 8)
        }
    }

    private var searchSection: some View {
        Section {
            HTextField(
                title: "Buscar por nombre o RUC",
                text: $viewModel.searchText,
                keyboardType: .default,
                textContentType: nil,
                autocapitalization: .never
            )
        }
    }

    private var organizationsSection: some View {
        Section {
            if viewModel.filteredOrganizations.isEmpty {
                EmptyStateView(
                    systemImage: "magnifyingglass",
                    title: "Sin resultados",
                    message: "Prueba con otro nombre, RUC o estado."
                )
            } else {
                ForEach(viewModel.filteredOrganizations) { organization in
                    Button {
                        Task { await viewModel.select(organization) }
                    } label: {
                        OrganizationSelectorRow(
                            organization: organization,
                            isActive: organization.id == viewModel.activeOrganizationId
                        )
                    }
                    .disabled(viewModel.isLoading)
                    .buttonStyle(.plain)
                }
            }
        } header: {
            Text("Mis organizaciones")
        } footer: {
            Text("Al elegir una organización se recargan roles, permisos, módulos, SRI, catálogo, caja y reportes para ese contexto.")
        }
    }

    private var noOrganizationsSection: some View {
        Section {
            EmptyStateView(
                systemImage: "building.2.crop.circle",
                title: "No tienes organizaciones",
                message: "Crea una organización o pide una invitación para poder continuar."
            )
        }
    }

    private var actionsSection: some View {
        Section {
            Button {
                viewModel.createOrganizationTapped()
            } label: {
                Label("Crear nueva organización", systemImage: "plus.circle.fill")
            }

            Button(role: .destructive) {
                Task { await viewModel.logout() }
            } label: {
                Label("Cerrar sesión", systemImage: "rectangle.portrait.and.arrow.right")
            }
        }
    }
}

private struct OrganizationSelectorRow: View {
    let organization: OrganizationChoice
    let isActive: Bool

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: isActive ? "checkmark.circle.fill" : "building.2.fill")
                .font(.title3)
                .foregroundStyle(isActive ? Color.accentColor : Color.secondary)
                .frame(width: 34, height: 34)

            VStack(alignment: .leading, spacing: 4) {
                Text(organization.title)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(organization.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if !organization.roles.isEmpty {
                    Text(organization.roles.map(\.name).joined(separator: ", "))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 6)
    }
}
