//
//  AdminProfileView.swift
//  Nexo Admin
//
//  Created by José Ruiz on 20/5/26.
//

import SwiftUI

struct AdminProfileView: View {
    @ObservedObject var sessionStore: AuthSessionStore
    let onLogout: () -> Void

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
