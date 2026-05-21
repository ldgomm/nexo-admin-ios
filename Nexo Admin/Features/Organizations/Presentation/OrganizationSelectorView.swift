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
                Section {
                    ForEach(viewModel.organizations) { organization in
                        Button {
                            Task { await viewModel.select(organization) }
                        } label: {
                            OrganizationRow(organization: organization)
                        }
                        .disabled(viewModel.isLoading)
                    }
                } header: {
                    Text("Selecciona una organización")
                } footer: {
                    Text("La organización activa se enviará al backend usando el header X-Organization-Id.")
                }

                if let errorMessage = viewModel.errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
                }

                Section {
                    Button(role: .destructive) {
                        Task { await viewModel.logout() }
                    } label: {
                        Text("Cerrar sesión")
                    }
                }
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
}

private struct OrganizationRow: View {
    let organization: OrganizationChoice

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "building.2.fill")
                .font(.title3)
                .foregroundStyle(Color.accentColor)
                .frame(width: 34, height: 34)

            VStack(alignment: .leading, spacing: 4) {
                Text(organization.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(organization.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 6)
    }
}
