//
//  AdminCatalogRequestsView.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import SwiftUI

struct AdminCatalogRequestsView: View {
    @ObservedObject var sessionStore: AuthSessionStore
    @ObservedObject var viewModel: AdminCatalogViewModel
    @State private var showingCreate = false

    var body: some View {
        List {
            Section {
                TextField("Buscar solicitudes", text: $viewModel.requestSearch.query)
                    .textInputAutocapitalization(.never)
                    .onSubmit { Task { await viewModel.reloadRequests() } }
                Picker("Estado", selection: $viewModel.requestSearch.statuses) {
                    Text("Todos").tag("")
                    Text("Pendiente").tag("PENDING")
                    Text("Más información").tag("NEEDS_MORE_INFO")
                    Text("Aprobada").tag("APPROVED_AS_TEMPLATE")
                    Text("Rechazada").tag("REJECTED")
                }
                Button {
                    Task { await viewModel.reloadRequests() }
                } label: {
                    Label("Actualizar", systemImage: "arrow.clockwise")
                }
            }

            if viewModel.requests.isEmpty {
                EmptyStateView(systemImage: "tray", title: "Sin solicitudes", message: "Crea una solicitud cuando no encuentres un producto o servicio en el catálogo maestro.")
                    .listRowSeparator(.hidden)
            } else {
                Section("Solicitudes") {
                    ForEach(viewModel.requests) { request in
                        NavigationLink {
                            AdminCatalogRequestDetailView(viewModel: viewModel, request: request)
                        } label: {
                            AdminCatalogRequestRow(request: request)
                        }
                    }
                }
            }
        }
        .navigationTitle("Solicitudes")
        .refreshable { await viewModel.reloadRequests() }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                PermissionGate(permissions: sessionStore.effectivePermissions, required: [PermissionCatalog.catalogLocalRequestNewItem]) {
                    Button { showingCreate = true } label: { Image(systemName: "plus") }
                }
            }
        }
        .sheet(isPresented: $showingCreate) {
            NavigationStack {
                AdminCatalogCreateRequestView(viewModel: viewModel) {
                    showingCreate = false
                }
            }
        }
    }
}

struct AdminCatalogRequestDetailView: View {
    @ObservedObject var viewModel: AdminCatalogViewModel
    let request: AdminCatalogRequest

    private var current: AdminCatalogRequest { viewModel.selectedRequest ?? request }

    var body: some View {
        Form {
            Section("Solicitud") {
                HStack {
                    Text(current.requestedName)
                    Spacer()
                    AdminCatalogStatusBadge(status: current.status)
                }
                LabeledContent("Tipo", value: current.requestedType.readableSnakeCase)
                LabeledContent("Solicitado por", value: current.requestedByUserId)
                LabeledContent("Creado", value: current.createdAt)
                LabeledContent("Actualizado", value: current.updatedAt)
            }

            Section("Detalle") {
                Text(current.description ?? "Sin descripción")
                    .foregroundStyle(current.description == nil ? .secondary : .primary)
                if let tax = current.suggestedTaxProfileCode {
                    LabeledContent("Tax sugerido", value: tax)
                }
                if let category = current.suggestedCategoryId {
                    LabeledContent("Categoría sugerida", value: category)
                }
                if let linked = current.linkedTemplateId {
                    LabeledContent("Template vinculado", value: linked)
                }
            }

            if !current.identifiers.isEmpty {
                Section("Identificadores") {
                    ForEach(current.identifiers) { identifier in
                        LabeledContent(identifier.type.readableSnakeCase, value: identifier.value)
                    }
                }
            }

            if current.reviewReason != nil || current.adminMessage != nil || current.reviewedAt != nil {
                Section("Revisión") {
                    if let reviewedAt = current.reviewedAt {
                        LabeledContent("Fecha", value: reviewedAt)
                    }
                    if let reason = current.reviewReason {
                        LabeledContent("Motivo", value: reason)
                    }
                    if let message = current.adminMessage {
                        Text(message)
                    }
                }
            }
        }
        .navigationTitle("Solicitud")
        .task { await viewModel.selectRequest(request) }
    }
}

struct AdminCatalogCreateRequestView: View {
    @ObservedObject var viewModel: AdminCatalogViewModel
    let onClose: () -> Void

    @State private var requestedName = ""
    @State private var requestedType = "PRODUCT"
    @State private var description = ""
    @State private var suggestedCategoryId = ""
    @State private var suggestedTaxProfileCode = ""
    @State private var identifierType = "SKU"
    @State private var identifierValue = ""

    var body: some View {
        Form {
            Section("Nuevo producto o servicio") {
                TextField("Nombre solicitado", text: $requestedName)
                Picker("Tipo", selection: $requestedType) {
                    Text("Producto").tag("PRODUCT")
                    Text("Servicio").tag("SERVICE")
                }
                TextField("Descripción", text: $description, axis: .vertical)
                    .lineLimit(3...6)
            }

            Section("Sugerencias opcionales") {
                TextField("Categoría sugerida", text: $suggestedCategoryId)
                    .textInputAutocapitalization(.never)
                TextField("Tax profile sugerido", text: $suggestedTaxProfileCode)
                    .textInputAutocapitalization(.never)
            }

            Section("Identificador opcional") {
                Picker("Tipo", selection: $identifierType) {
                    Text("SKU").tag("SKU")
                    Text("Código interno").tag("INTERNAL_CODE")
                    Text("EAN-13").tag("EAN13")
                    Text("UPC").tag("UPC")
                }
                TextField("Valor", text: $identifierValue)
                    .textInputAutocapitalization(.characters)
            }

            Section {
                AdminCatalogSaveButton(title: "Crear solicitud", isSaving: viewModel.isSaving) {
                    Task { await create() }
                }
            }
        }
        .navigationTitle("Nueva solicitud")
        .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancelar", action: onClose) } }
    }

    private func create() async {
        let identifiers: [AdminCatalogIdentifier]
        if let value = identifierValue.trimmedOrNil {
            identifiers = [AdminCatalogIdentifier(type: identifierType, value: value, isPrimary: true)]
        } else {
            identifiers = []
        }
        let input = CreateAdminCatalogRequestInput(
            requestedName: requestedName,
            requestedType: requestedType,
            description: description.trimmedOrNil,
            suggestedCategoryId: suggestedCategoryId.trimmedOrNil,
            suggestedTaxProfileCode: suggestedTaxProfileCode.trimmedOrNil,
            identifiers: identifiers
        )
        let ok = await viewModel.createRequest(input)
        if ok { onClose() }
    }
}
