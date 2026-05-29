//
//  AdminBusinessProfileView.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import SwiftUI

struct AdminBusinessProfileView: View {
    @ObservedObject var viewModel: AdminBusinessViewModel
    let permissions: Set<String>
    @State private var editing = false

    var body: some View {
        List {
            if let business = viewModel.business {
                Section("Identificación") {
                    LabeledContent("Nombre comercial", value: business.commercialName)
                    LabeledContent("Razón social", value: business.legalName)
                    LabeledContent("RUC", value: business.taxId)
                    LabeledContent("País", value: business.countryCode)
                    LabeledContent("Estado", value: business.status.title)
                }
                Section("Operación") {
                    LabeledContent("Moneda", value: business.defaultCurrency ?? "No configurada")
                    LabeledContent("Zona horaria", value: business.timezone ?? "No configurada")
                    LabeledContent("Versión", value: "\(business.version)")
                }
                Section {
                    Text("Cambiar datos fiscales puede afectar emisión documental. Edita solo lo permitido y deja que el backend valide reglas críticas.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                EmptyStateView(systemImage: "building.columns", title: "Sin datos", message: "Carga el overview del negocio para ver esta sección.")
            }
        }
        .navigationTitle("Datos del negocio")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if PermissionSet(permissions).can(PermissionCatalog.organizationUpdate) {
                    Button("Editar") { editing = true }
                }
            }
        }
        .sheet(isPresented: $editing) {
            if let business = viewModel.business {
                NavigationStack {
                    EditAdminBusinessProfileView(viewModel: viewModel, business: business)
                }
            }
        }
    }
}

struct EditAdminBusinessProfileView: View {
    @ObservedObject var viewModel: AdminBusinessViewModel
    let business: AdminBusinessProfile

    @Environment(\.dismiss) private var dismiss
    @State private var countryCode: String
    @State private var taxId: String
    @State private var legalName: String
    @State private var commercialName: String
    @State private var defaultCurrency: String
    @State private var timezone: String
    @State private var reason: String = "Actualización de datos operativos del negocio"

    init(viewModel: AdminBusinessViewModel, business: AdminBusinessProfile) {
        self.viewModel = viewModel
        self.business = business
        _countryCode = State(initialValue: business.countryCode)
        _taxId = State(initialValue: business.taxId)
        _legalName = State(initialValue: business.legalName)
        _commercialName = State(initialValue: business.commercialName)
        _defaultCurrency = State(initialValue: business.defaultCurrency ?? "USD")
        _timezone = State(initialValue: business.timezone ?? "America/Guayaquil")
    }

    var body: some View {
        Form {
            Section("Datos fiscales") {
                TextField("País", text: $countryCode)
                    .textInputAutocapitalization(.characters)
                TextField("RUC", text: $taxId)
                    .keyboardType(.numberPad)
                TextField("Razón social", text: $legalName)
                TextField("Nombre comercial", text: $commercialName)
            }
            Section("Operación") {
                TextField("Moneda", text: $defaultCurrency)
                    .textInputAutocapitalization(.characters)
                TextField("Zona horaria", text: $timezone)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
            AdminBusinessReasonField(reason: $reason)
            Section {
                AdminBusinessSaveButton(title: "Guardar cambios", isSaving: viewModel.isSaving) {
                    Task {
                        let ok = await viewModel.updateBusiness(
                            UpdateAdminBusinessProfileInput(
                                countryCode: countryCode,
                                taxId: taxId,
                                legalName: legalName,
                                commercialName: commercialName,
                                defaultCurrency: defaultCurrency,
                                timezone: timezone,
                                reason: reason
                            )
                        )
                        if ok { dismiss() }
                    }
                }
            }
        }
        .navigationTitle("Editar negocio")
        .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { dismiss() } } }
    }
}
