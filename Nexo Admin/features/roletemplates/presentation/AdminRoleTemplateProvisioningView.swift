//
//  AdminRoleTemplateProvisioningView.swift
//  Nexo Admin
//
//  Created by José Ruiz on 2/6/26.
//

import SwiftUI

struct AdminRoleTemplateProvisioningView: View {
    @State var viewModel: AdminRoleTemplateProvisioningViewModel

    var body: some View {
        List {
            messageSection
            content
        }
        .navigationTitle("Plantillas de roles")
        .task { await viewModel.load() }
        .refreshable { await viewModel.load() }
        .alert(
            "Error",
            isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )
        ) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    @ViewBuilder
    private var messageSection: some View {
        if let infoMessage = viewModel.infoMessage {
            Section {
                Label(infoMessage, systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            Section { ProgressView("Cargando plantillas…") }
        case .failed(let message):
            Section { Text(message).foregroundStyle(.red) }
        case .loaded:
            Section("Motivo") {
                TextField("Motivo", text: $viewModel.reason, axis: .vertical)
                    .lineLimit(2...4)
            }
            Section {
                ForEach(viewModel.templates) { template in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(template.name).font(.headline)
                                Text("\(template.vertical) · rango \(template.rank)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button("Crear") {
                                Task { await viewModel.createRole(from: template) }
                            }
                            .buttonStyle(.bordered)
                            .disabled(viewModel.isMutating)
                        }
                        Text(template.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            } header: {
                Text("Plantillas")
            } footer: {
                Text("Esta pantalla usa la organización activa seleccionada en Admin. Para reprovisionamiento masivo conviene crear un endpoint admin específico por organización.")
            }
        }
    }
}
