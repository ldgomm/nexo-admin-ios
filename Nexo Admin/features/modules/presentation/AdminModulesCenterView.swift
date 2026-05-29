//
//  AdminModulesCenterView.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import SwiftUI

struct AdminModulesCenterView: View {
    @ObservedObject var sessionStore: AuthSessionStore
    let foundationRepository: any AdminFoundationRepository

    var body: some View {
        NavigationStack {
            List {
                Section("Readiness para Business App") {
                    NavigationLink {
                        AdminBusinessAppReadinessView(
                            viewModel: AdminBusinessAppReadinessViewModel(
                                repository: foundationRepository,
                                permissions: sessionStore.effectivePermissions
                            )
                        )
                    } label: {
                        AdminModulesCenterRow(
                            title: "Business App readiness",
                            subtitle: "Idempotencia, módulos, catalogRevision, taxRevision y outbox",
                            systemImage: "iphone.gen2.badge.play"
                        )
                    }
                }

                Section("Module System") {
                    NavigationLink {
                        AdminFoundationHomeView(
                            viewModel: AdminFoundationViewModel(
                                repository: foundationRepository,
                                permissions: sessionStore.effectivePermissions
                            )
                        )
                    } label: {
                        AdminModulesCenterRow(
                            title: "Módulos y foundations",
                            subtitle: "Core, foundations internas, módulos opcionales, bloqueos y dependencias",
                            systemImage: "puzzlepiece.extension"
                        )
                    }
                }

                Section("Regla v2.4") {
                    Text("Las reservas, citas, mesas, vehículos, eventos y alquileres no son core visible. Se activan por módulo, compatibilidad de actividad, plan y permisos. El backend siempre valida.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Módulos")
        }
    }
}

private struct AdminModulesCenterRow: View {
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
