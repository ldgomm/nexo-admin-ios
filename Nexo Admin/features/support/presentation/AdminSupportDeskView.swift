//
//  AdminSupportDeskView.swift
//  Nexo Admin
//
//  Created by José Ruiz on 1/7/26.
//

import SwiftUI

struct AdminSupportDeskView: View {
    @StateObject private var viewModel: AdminSupportDeskViewModel

    @MainActor
    init() {
        _viewModel = StateObject(wrappedValue: AdminSupportDeskViewModel())
    }

    @MainActor
    init(viewModel: AdminSupportDeskViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            List {
                filtersSection
                ticketsSection
                detailSection
            }
            .navigationTitle("Tickets de soporte")
            .task { await viewModel.loadTickets() }
            .overlay {
                if viewModel.isLoading {
                    ProgressView("Cargando soporte…")
                }
            }
        }
    }

    private var filtersSection: some View {
        Section("Soporte interno operativo") {
            TextField("Estado", text: Binding(
                get: { viewModel.statusFilter ?? "" },
                set: { viewModel.statusFilter = $0.isEmpty ? nil : $0 }
            ))
            TextField("Prioridad", text: Binding(
                get: { viewModel.priorityFilter ?? "" },
                set: { viewModel.priorityFilter = $0.isEmpty ? nil : $0 }
            ))
            TextField("Organización", text: Binding(
                get: { viewModel.organizationFilter ?? "" },
                set: { viewModel.organizationFilter = $0.isEmpty ? nil : $0 }
            ))
            Button("Aplicar filtros") {
                Task { await viewModel.loadTickets() }
            }
        }
    }

    private var ticketsSection: some View {
        Section("Admin Support Desk") {
            if viewModel.tickets.isEmpty {
                Text("No hay tickets para los filtros actuales.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(viewModel.tickets) { ticket in
                    Button {
                        Task { await viewModel.selectTicket(ticket) }
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(ticket.subject).font(.headline)
                            Text("\(ticket.priority) · \(ticket.status) · \(ticket.requesterLabel)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var detailSection: some View {
        if let ticket = viewModel.selectedTicket {
            Section("Detalle") {
                Text(ticket.subject).font(.headline)
                Text("Estado: \(ticket.status)")
                Text("Prioridad: \(ticket.priority)")
            }

            Section("Contexto sanitizado") {
                if ticket.contextRefs.isEmpty {
                    Text("Sin contexto adjunto.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(ticket.contextRefs) { context in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(context.label).font(.subheadline.weight(.semibold))
                            Text(context.sanitizedDisplayValue)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("Redacción: \(context.redactionStatus)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Section("Responder") {
                TextField("Respuesta para Business", text: $viewModel.replyBody, axis: .vertical)
                Button("Responder ticket") {
                    Task { await viewModel.replyToTicket() }
                }
            }

            Section("Nota interna") {
                TextField("Nota interna de soporte", text: $viewModel.internalNoteBody, axis: .vertical)
                Button("Agregar nota interna") {
                    Task { await viewModel.addInternalNote() }
                }
            }

            Section("Resolver / Cerrar") {
                Button("Resolver") {
                    Task { await viewModel.resolveTicket() }
                }
                Button("Cerrar", role: .destructive) {
                    Task { await viewModel.closeTicket() }
                }
            }
        } else if let error = viewModel.errorMessage {
            Section("Error") {
                Text(error).foregroundStyle(.red)
            }
        }
    }
}

#Preview {
    AdminSupportDeskView()
}
