//
//  DashboardPlaceholderView.swift
//  Nexo Admin
//
//  Created by José Ruiz on 20/5/26.
//

import SwiftUI

struct DashboardPlaceholderView: View {
    @ObservedObject var sessionStore: AuthSessionStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: NexoTheme.cardSpacing) {
                    welcomeCard
                    readinessCard
                    modulesCard
                    securityCard
                }
                .padding(NexoTheme.screenPadding)
            }
            .navigationTitle("Inicio")
        }
    }

    private var welcomeCard: some View {
        HCard {
            Text("Hola, \(sessionStore.currentUser?.displayName ?? "admin")")
                .font(.title2.bold())
            Text(sessionStore.activeOrganization?.commercialName ?? sessionStore.activeOrganization?.legalName ?? "Organización activa")
                .font(.headline)
                .foregroundStyle(Color.accentColor)
            Text("Sesión, organización y permisos efectivos están cargados. Este dashboard será reemplazado por métricas reales en 13iOS-B.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var readinessCard: some View {
        HCard {
            Label("Base técnica lista", systemImage: "checkmark.seal.fill")
                .font(.headline)
                .foregroundStyle(.green)
            VStack(alignment: .leading, spacing: 6) {
                Text("• Login conectado a Auth API")
                Text("• Tokens protegidos en Keychain")
                Text("• Organización activa por X-Organization-Id")
                Text("• Permisos efectivos disponibles para gating UI")
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
    }

    private var modulesCard: some View {
        HCard {
            Text("Permisos efectivos")
                .font(.headline)
            if sessionStore.effectivePermissions.isEmpty {
                Text("No se recibieron permisos para esta organización.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(Array(sessionStore.effectivePermissions).sorted().prefix(8), id: \.self) { permission in
                    Label(permission, systemImage: "checkmark.circle")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if sessionStore.effectivePermissions.count > 8 {
                    Text("+ \(sessionStore.effectivePermissions.count - 8) permisos más")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
        }
    }

    private var securityCard: some View {
        HCard {
            Label("Regla de arquitectura", systemImage: "shield.lefthalf.filled")
                .font(.headline)
            Text("La app administra y consulta. El backend valida, audita, firma XML, emite al SRI, persiste y decide reglas críticas.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}
