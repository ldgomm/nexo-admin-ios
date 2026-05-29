//
//  AdminProfileView.swift
//  Nexo Admin
//
//  Created by José Ruiz on 20/5/26.
//

import SwiftUI

struct AdminProfileView: View {
    @ObservedObject var sessionStore: AuthSessionStore
    let onChangeOrganization: (() -> Void)?
    let onLogout: () -> Void

    init(
        sessionStore: AuthSessionStore,
        onChangeOrganization: (() -> Void)? = nil,
        onLogout: @escaping () -> Void
    ) {
        self.sessionStore = sessionStore
        self.onChangeOrganization = onChangeOrganization
        self.onLogout = onLogout
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Usuario") {
                    LabeledContent("Nombre", value: sessionStore.currentUser?.displayName ?? "—")
                    LabeledContent("Correo", value: sessionStore.currentUser?.email ?? "—")
                    LabeledContent("Estado", value: sessionStore.currentUser?.status ?? "—")
                }

                Section("Organización activa") {
                    LabeledContent("Nombre", value: sessionStore.activeOrganization?.commercialName ?? sessionStore.activeOrganization?.legalName ?? "—")
                    LabeledContent("RUC", value: sessionStore.activeOrganization?.taxId ?? "—")
                    LabeledContent("Estado", value: sessionStore.activeOrganization?.status ?? "—")

                    if let onChangeOrganization {
                        Button(action: onChangeOrganization) {
                            Label("Cambiar organización", systemImage: "building.2.crop.circle")
                        }
                    }
                }

                Section("Organizaciones disponibles") {
                    if sessionStore.organizations.isEmpty {
                        Text("Sin organizaciones cargadas.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(sessionStore.organizations) { choice in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(choice.title)
                                    .font(.subheadline.weight(.semibold))
                                Text(choice.subtitle)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                Section("Roles") {
                    if sessionStore.roles.isEmpty {
                        Text("Sin roles cargados.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(sessionStore.roles) { role in
                            VStack(alignment: .leading) {
                                Text(role.name)
                                    .font(.headline)
                                Text(role.code)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                Section {
                    Button(role: .destructive, action: onLogout) {
                        Text("Cerrar sesión")
                    }
                }
            }
            .navigationTitle("Admin")
        }
    }
}
