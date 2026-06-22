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
    let businessPackagesRepository: any AdminBusinessPackagesRepository

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


                Section("Business Package System") {
                    NavigationLink {
                        AdminBusinessPackagesDiagnosticsView(
                            viewModel: AdminBusinessPackagesDiagnosticsViewModel(
                                repository: businessPackagesRepository,
                                permissions: sessionStore.effectivePermissions
                            )
                        )
                    } label: {
                        AdminModulesCenterRow(
                            title: "Paquetes del negocio",
                            subtitle: "Capabilities, verticales recomendados y regulados",
                            systemImage: "square.3.layers.3d.down.right"
                        )
                    }
                }

                Section("Regla v2.4 / 20K") {
                    Text("Los módulos siguen siendo la seguridad técnica. Los paquetes del negocio son diagnóstico read-only para planificar capabilities y verticales; todavía no activan nada.")
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
