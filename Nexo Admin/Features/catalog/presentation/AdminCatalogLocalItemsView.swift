//
//  AdminCatalogLocalItemsView.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import SwiftUI

struct AdminCatalogLocalItemsView: View {
    @ObservedObject var sessionStore: AuthSessionStore
    @ObservedObject var viewModel: AdminCatalogViewModel

    var body: some View {
        List {
            Section {
                TextField("Buscar por nombre, SKU o código", text: $viewModel.localSearch.query)
                    .textInputAutocapitalization(.never)
                    .onSubmit { Task { await viewModel.searchLocal() } }
                TextField("Identificador exacto opcional", text: $viewModel.localSearch.identifier)
                    .textInputAutocapitalization(.characters)
                    .onSubmit { Task { await viewModel.searchLocal() } }
                Picker("Estado", selection: $viewModel.localSearch.statuses) {
                    Text("Todos").tag("")
                    Text("Activo").tag("ACTIVE")
                    Text("Pausado").tag("PAUSED")
                    Text("Removido").tag("REMOVED_FROM_ACCOUNT")
                }
                Button {
                    Task { await viewModel.searchLocal() }
                } label: {
                    Label("Buscar", systemImage: "magnifyingglass")
                }
            }

            if viewModel.localItems.isEmpty {
                EmptyStateView(systemImage: "square.grid.2x2", title: "Sin resultados", message: "Busca por nombre, SKU, código interno o copia desde el catálogo maestro.")
                    .listRowSeparator(.hidden)
            } else {
                Section("Ítems") {
                    ForEach(viewModel.localItems) { item in
                        NavigationLink {
                            AdminCatalogLocalItemDetailView(sessionStore: sessionStore, viewModel: viewModel, item: item)
                        } label: {
                            AdminCatalogItemRow(item: item)
                        }
                    }
                }
            }
        }
        .navigationTitle("Catálogo local")
        .refreshable { await viewModel.searchLocal() }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task { await viewModel.searchLocal() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
            }
        }
    }
}

struct AdminCatalogLocalItemDetailView: View {
    @ObservedObject var sessionStore: AuthSessionStore
    @ObservedObject var viewModel: AdminCatalogViewModel
    let item: AdminCatalogLocalItem

    @State private var localName: String = ""
    @State private var priceAmount: String = ""
    @State private var currency: String = "USD"
    @State private var taxProfileCode: String = ""
    @State private var reason: String = ""
    @State private var actionReason: String = ""
    @State private var action: LocalItemAction?

    private var current: AdminCatalogLocalItem { viewModel.selectedItem ?? item }

    var body: some View {
        Form {
            Section("Resumen") {
                HStack {
                    Text(current.localName)
                    Spacer()
                    AdminCatalogStatusBadge(status: current.status)
                }
                LabeledContent("Precio", value: current.localPrice.formatted)
                LabeledContent("Tipo", value: current.type.readableSnakeCase)
                LabeledContent("Tax profile", value: current.taxProfileId)
                LabeledContent("Plantilla", value: current.templateId)
                if let identifier = current.primaryIdentifier {
                    LabeledContent("Identificador", value: identifier)
                }
            }

            PermissionGate(
                permissions: sessionStore.effectivePermissions,
                required: [
                    PermissionCatalog.catalogLocalUpdateLocalCopy,
                    PermissionCatalog.catalogLocalChangePrice,
                    PermissionCatalog.catalogLocalChangeTaxProfile
                ]
            ) {
                Section("Actualizar copia local") {
                    TextField("Nombre local", text: $localName)
                    AdminCatalogMoneyField(title: "Precio", amount: $priceAmount, currency: $currency)
                    TextField("Tax profile", text: $taxProfileCode)
                        .textInputAutocapitalization(.never)
                    AdminCatalogReasonSection(reason: $reason)
                    AdminCatalogSaveButton(title: "Guardar cambios", isSaving: viewModel.isSaving) {
                        Task { await save() }
                    }
                }
            }

            Section("Acciones") {
                PermissionGate(permissions: sessionStore.effectivePermissions, required: [PermissionCatalog.catalogLocalUpdateLocalCopy]) {
                    Button("Activar ítem") { action = .activate }
                        .disabled(current.isActive || current.isRemoved)
                }
                PermissionGate(permissions: sessionStore.effectivePermissions, required: [PermissionCatalog.catalogLocalDisableLocalCopy]) {
                    Button("Desactivar ítem", role: .destructive) { action = .deactivate }
                        .disabled(!current.isActive || current.isRemoved)
                    Button("Remover copia local", role: .destructive) { action = .remove }
                        .disabled(current.isRemoved)
                }
            }

            Section("Historial de precios") {
                if viewModel.priceHistory.isEmpty {
                    Text("Sin historial cargado o sin cambios de precio recientes.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(viewModel.priceHistory) { entry in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(entry.oldPrice.formatted)
                                Image(systemName: "arrow.right")
                                Text(entry.newPrice.formatted)
                                    .fontWeight(.semibold)
                            }
                            Text(entry.reason)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(entry.changedAt)
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Detalle")
        .task {
            seedForm(from: current)
            await viewModel.selectItem(item, organizationId: sessionStore.activeOrganization?.id)
            seedForm(from: current)
        }
        .sheet(item: $action) { action in
            NavigationStack {
                Form {
                    Section(action.title) {
                        Text(action.message)
                            .foregroundStyle(.secondary)
                        TextField("Motivo", text: $actionReason, axis: .vertical)
                            .lineLimit(2...4)
                    }
                    Section {
                        AdminCatalogSaveButton(title: action.confirmTitle, isSaving: viewModel.isSaving) {
                            Task { await perform(action) }
                        }
                    }
                }
                .navigationTitle(action.title)
                .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { self.action = nil } } }
            }
            .presentationDetents([.medium])
        }
    }

    private func seedForm(from item: AdminCatalogLocalItem) {
        localName = item.localName
        priceAmount = NSDecimalNumber(decimal: item.localPrice.amount).stringValue
        currency = item.localPrice.currency
        taxProfileCode = item.taxProfileId
    }

    private func save() async {
        let price = Decimal(string: priceAmount).map { AdminCatalogMoney(amount: $0, currency: currency.trimmedOrNil ?? "USD") }
        let input = SaveAdminCatalogLocalItemInput(
            id: current.id,
            localName: localName == current.localName ? nil : localName,
            localPrice: priceAmount == NSDecimalNumber(decimal: current.localPrice.amount).stringValue ? nil : price,
            taxProfileCode: taxProfileCode == current.taxProfileId ? nil : taxProfileCode,
            identifiers: nil,
            status: nil,
            reason: reason
        )
        let ok = await viewModel.updateItem(input)
        if ok { reason = "" }
    }

    private func perform(_ action: LocalItemAction) async {
        let ok: Bool
        switch action {
        case .activate:
            ok = await viewModel.activateItem(current, reason: actionReason)
        case .deactivate:
            ok = await viewModel.deactivateItem(current, reason: actionReason)
        case .remove:
            ok = await viewModel.removeItem(current, reason: actionReason)
        }
        if ok {
            actionReason = ""
            self.action = nil
        }
    }
}

private enum LocalItemAction: String, Identifiable {
    case activate
    case deactivate
    case remove

    var id: String { rawValue }
    var title: String {
        switch self {
        case .activate: "Activar ítem"
        case .deactivate: "Desactivar ítem"
        case .remove: "Remover copia local"
        }
    }
    var message: String {
        switch self {
        case .activate: "El ítem volverá a estar disponible para operación."
        case .deactivate: "El ítem quedará pausado sin borrar su historial."
        case .remove: "La copia local se marcará como removida. No se hará borrado destructivo."
        }
    }
    var confirmTitle: String {
        switch self {
        case .activate: "Activar"
        case .deactivate: "Desactivar"
        case .remove: "Remover"
        }
    }
}
