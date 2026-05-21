//
//  AdminCatalogMasterSearchView.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import SwiftUI

struct AdminCatalogMasterSearchView: View {
    @ObservedObject var sessionStore: AuthSessionStore
    @ObservedObject var viewModel: AdminCatalogViewModel

    var body: some View {
        List {
            Section {
                TextField("Buscar plantilla maestra", text: $viewModel.masterSearch.query)
                    .textInputAutocapitalization(.never)
                    .onSubmit { Task { await viewModel.searchMaster() } }
                TextField("Identificador opcional", text: $viewModel.masterSearch.identifier)
                    .textInputAutocapitalization(.characters)
                    .onSubmit { Task { await viewModel.searchMaster() } }
                Picker("Tipo", selection: $viewModel.masterSearch.type) {
                    Text("Todos").tag("")
                    Text("Producto").tag("PRODUCT")
                    Text("Servicio").tag("SERVICE")
                }
                Button {
                    Task { await viewModel.searchMaster() }
                } label: {
                    Label("Buscar en maestro", systemImage: "magnifyingglass")
                }
            }

            if viewModel.isSearchingMaster {
                ProgressView("Buscando…")
            } else if viewModel.masterTemplates.isEmpty {
                EmptyStateView(systemImage: "doc.on.doc", title: "Busca una plantilla", message: "El negocio copia desde catálogo maestro y edita solo su versión local.")
                    .listRowSeparator(.hidden)
            } else {
                Section("Plantillas") {
                    ForEach(viewModel.masterTemplates) { template in
                        NavigationLink {
                            AdminCatalogMasterTemplateDetailView(sessionStore: sessionStore, viewModel: viewModel, template: template)
                        } label: {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(template.canonicalName)
                                        .font(.headline)
                                    Spacer()
                                    AdminCatalogStatusBadge(status: template.status)
                                }
                                HStack {
                                    Text(template.type.readableSnakeCase)
                                    if let identifier = template.primaryIdentifier {
                                        Text("• \(identifier)")
                                    }
                                }
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
        }
        .navigationTitle("Catálogo maestro")
        .refreshable { await viewModel.searchMaster() }
    }
}

struct AdminCatalogMasterTemplateDetailView: View {
    @ObservedObject var sessionStore: AuthSessionStore
    @ObservedObject var viewModel: AdminCatalogViewModel
    let template: AdminCatalogMasterTemplate

    @State private var activityId = ""
    @State private var branchId = ""
    @State private var priceAmount = ""
    @State private var currency = "USD"
    @State private var taxProfileCode = "iva_current_full"
    @State private var reason = "Copiar plantilla al catálogo local"

    private var current: AdminCatalogMasterTemplate { viewModel.selectedTemplate ?? template }

    var body: some View {
        Form {
            Section("Plantilla") {
                HStack {
                    Text(current.canonicalName)
                    Spacer()
                    AdminCatalogStatusBadge(status: current.status)
                }
                LabeledContent("Tipo", value: current.type.readableSnakeCase)
                LabeledContent("Global ID", value: current.globalCatalogId)
                if let family = current.productFamilyId {
                    LabeledContent("Familia", value: family)
                }
                if let identifier = current.primaryIdentifier {
                    LabeledContent("Identificador", value: identifier)
                }
            }

            if !current.attributes.isEmpty {
                Section("Atributos") {
                    ForEach(current.attributes.keys.sorted(), id: \.self) { key in
                        LabeledContent(key.readableSnakeCase, value: current.attributes[key] ?? "")
                    }
                }
            }

            PermissionGate(permissions: sessionStore.effectivePermissions, required: [PermissionCatalog.catalogLocalCopyFromMaster]) {
                Section("Copiar al negocio") {
                    TextField("Actividad ID", text: $activityId)
                        .textInputAutocapitalization(.never)
                    TextField("Sucursal ID opcional", text: $branchId)
                        .textInputAutocapitalization(.never)
                    AdminCatalogMoneyField(title: "Precio local", amount: $priceAmount, currency: $currency)
                    TextField("Tax profile", text: $taxProfileCode)
                        .textInputAutocapitalization(.never)
                    AdminCatalogReasonSection(reason: $reason)
                    AdminCatalogSaveButton(title: "Copiar plantilla", isSaving: viewModel.isSaving) {
                        Task { await copy() }
                    }
                }
            } fallback: {
                Section("Copiar al negocio") {
                    Text("No tienes permiso para copiar desde catálogo maestro.")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Plantilla")
        .task { await viewModel.selectTemplate(template) }
    }

    private func copy() async {
        let amount = Decimal(string: priceAmount) ?? 0
        let input = CopyAdminCatalogTemplateInput(
            templateId: current.id,
            branchId: branchId.trimmedOrNil,
            activityId: activityId,
            localPrice: AdminCatalogMoney(amount: amount, currency: currency.trimmedOrNil ?? "USD"),
            taxProfileCode: taxProfileCode,
            reason: reason
        )
        let ok = await viewModel.copyTemplate(input)
        if ok {
            priceAmount = ""
            reason = "Copiar plantilla al catálogo local"
        }
    }
}
