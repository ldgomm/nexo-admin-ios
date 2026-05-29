//
//  AdminBranchesView.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import SwiftUI

struct AdminBranchesView: View {
    @ObservedObject var viewModel: AdminBusinessViewModel
    let permissions: Set<String>
    @State private var showCreate = false

    var body: some View {
        List {
            if viewModel.branches.isEmpty {
                EmptyStateView(systemImage: "mappin.and.ellipse", title: "Sin sucursales", message: "Crea una sucursal activa antes de configurar puntos de emisión o caja.")
            } else {
                ForEach(viewModel.branches) { branch in
                    NavigationLink {
                        AdminBranchDetailView(viewModel: viewModel, permissions: permissions, branch: branch)
                    } label: {
                        AdminBranchRow(branch: branch)
                    }
                }
            }
        }
        .navigationTitle("Sucursales")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if PermissionSet(permissions).canAny([PermissionCatalog.branchesCreate, PermissionCatalog.settingsBranchesManage]) {
                    Button { showCreate = true } label: { Image(systemName: "plus") }
                }
            }
        }
        .sheet(isPresented: $showCreate) {
            NavigationStack { EditAdminBranchView(viewModel: viewModel, branch: nil) }
        }
    }
}

private struct AdminBranchRow: View {
    let branch: AdminBusinessBranch

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(branch.name)
                        .font(.headline)
                    Text("\(branch.displayCode) • \(branch.readableType)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                AdminBusinessStatusBadge(title: branch.status.title, systemImage: "circle.fill", emphasis: branch.status != .active)
            }
            Text(branch.location?.shortAddress ?? "Sin ubicación configurada")
                .font(.caption)
                .foregroundStyle(.secondary)
            if let hours = branch.businessHoursId?.trimmedOrNil {
                Label("Horario: \(hours)", systemImage: "clock")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct AdminBranchDetailView: View {
    @ObservedObject var viewModel: AdminBusinessViewModel
    let permissions: Set<String>
    let branch: AdminBusinessBranch
    @State private var editing = false
    @State private var statusReason = "Actualización de estado de sucursal"
    @State private var showStatusDialog = false

    var body: some View {
        List {
            Section("Sucursal") {
                LabeledContent("Nombre", value: branch.name)
                LabeledContent("Código", value: branch.displayCode)
                LabeledContent("Tipo", value: branch.readableType)
                LabeledContent("Estado", value: branch.status.title)
            }
            Section("Ubicación") {
                LabeledContent("Dirección", value: branch.location?.shortAddress ?? "Sin ubicación")
                if let province = branch.location?.province { LabeledContent("Provincia", value: province) }
                if let country = branch.location?.countryCode { LabeledContent("País", value: country) }
                if let coordinates = branch.location?.coordinatesText { LabeledContent("Coordenadas", value: coordinates) }
                if let privacy = branch.location?.privacyMode { LabeledContent("Privacidad", value: privacy.readableSnakeCase) }
            }
            Section("Horarios básicos") {
                LabeledContent("Horario asociado", value: branch.businessHoursId ?? "No configurado")
                Text("Este sprint permite asociar un identificador de horario al branch. El CRUD avanzado de horarios queda para cuando el backend exponga Business Hours API.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if PermissionSet(permissions).canAny([PermissionCatalog.branchesUpdate, PermissionCatalog.settingsBranchesManage]) {
                Section("Acciones") {
                    Button("Editar") { editing = true }
                    Button(branch.status == .active ? "Desactivar" : "Activar") { showStatusDialog = true }
                        .foregroundStyle(branch.status == .active ? .orange : .green)
                }
            }
        }
        .navigationTitle(branch.name)
        .sheet(isPresented: $editing) { NavigationStack { EditAdminBranchView(viewModel: viewModel, branch: branch) } }
        .sheet(isPresented: $showStatusDialog) {
            AdminBusinessActionReasonDialog(
                title: branch.status == .active ? "Desactivar sucursal" : "Activar sucursal",
                message: "El backend rechazará la acción si deja a la organización sin sucursales activas o con puntos de emisión activos inconsistentes.",
                reason: $statusReason,
                isSaving: viewModel.isSaving,
                confirmTitle: branch.status == .active ? "Desactivar" : "Activar"
            ) {
                Task {
                    let ok = branch.status == .active
                        ? await viewModel.deactivateBranch(branch, reason: statusReason)
                        : await viewModel.activateBranch(branch, reason: statusReason)
                    if ok { showStatusDialog = false }
                }
            }
            .presentationDetents([.medium])
        }
    }
}

struct EditAdminBranchView: View {
    @ObservedObject var viewModel: AdminBusinessViewModel
    let branch: AdminBusinessBranch?
    @Environment(\.dismiss) private var dismiss

    @State private var code: String
    @State private var name: String
    @State private var type: String
    @State private var status: String
    @State private var countryCode: String
    @State private var province: String
    @State private var city: String
    @State private var sector: String
    @State private var addressLine: String
    @State private var latitude: String
    @State private var longitude: String
    @State private var privacyMode: String
    @State private var businessHoursId: String
    @State private var clearLocation: Bool = false
    @State private var clearBusinessHoursId: Bool = false
    @State private var reason = "Configuración de sucursal"

    private let branchTypes = ["main", "branch", "warehouse", "mobile", "virtual"]
    private let statuses = ["active", "inactive"]
    private let privacyModes = ["private", "approximate_public", "exact_public", "hidden"]

    init(viewModel: AdminBusinessViewModel, branch: AdminBusinessBranch?) {
        self.viewModel = viewModel
        self.branch = branch
        _code = State(initialValue: branch?.code ?? "")
        _name = State(initialValue: branch?.name ?? "")
        _type = State(initialValue: branch?.type ?? "branch")
        _status = State(initialValue: branch?.status.rawValue == "unknown" ? "active" : branch?.status.rawValue ?? "active")
        _countryCode = State(initialValue: branch?.location?.countryCode ?? "EC")
        _province = State(initialValue: branch?.location?.province ?? "")
        _city = State(initialValue: branch?.location?.city ?? "")
        _sector = State(initialValue: branch?.location?.sector ?? "")
        _addressLine = State(initialValue: branch?.location?.addressLine ?? "")
        _latitude = State(initialValue: branch?.location?.latitude.map { String($0) } ?? "")
        _longitude = State(initialValue: branch?.location?.longitude.map { String($0) } ?? "")
        _privacyMode = State(initialValue: branch?.location?.privacyMode ?? "private")
        _businessHoursId = State(initialValue: branch?.businessHoursId ?? "")
    }

    var body: some View {
        Form {
            Section("Sucursal") {
                TextField("Código", text: $code)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                TextField("Nombre", text: $name)
                Picker("Tipo", selection: $type) { ForEach(branchTypes, id: \.self) { Text($0.readableSnakeCase).tag($0) } }
                Picker("Estado", selection: $status) { ForEach(statuses, id: \.self) { Text($0.readableSnakeCase).tag($0) } }
            }
            Section("Ubicación simple") {
                Toggle("Quitar ubicación", isOn: $clearLocation)
                TextField("País", text: $countryCode)
                    .textInputAutocapitalization(.characters)
                TextField("Provincia", text: $province)
                TextField("Ciudad", text: $city)
                TextField("Sector", text: $sector)
                TextField("Dirección", text: $addressLine, axis: .vertical)
                    .lineLimit(2...4)
                TextField("Latitud", text: $latitude)
                    .keyboardType(.decimalPad)
                TextField("Longitud", text: $longitude)
                    .keyboardType(.decimalPad)
                Picker("Privacidad", selection: $privacyMode) { ForEach(privacyModes, id: \.self) { Text($0.readableSnakeCase).tag($0) } }
            }
            Section("Horarios básicos") {
                Toggle("Quitar horario asociado", isOn: $clearBusinessHoursId)
                TextField("Business hours id", text: $businessHoursId)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                Text("Cuando exista Business Hours API, este campo debe reemplazarse por un editor semanal real. Por ahora evita inventar lógica local.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            AdminBusinessReasonField(reason: $reason)
            Section {
                AdminBusinessSaveButton(title: branch == nil ? "Crear sucursal" : "Guardar sucursal", isSaving: viewModel.isSaving) {
                    Task {
                        let location = clearLocation ? nil : AdminBranchLocation(
                            countryCode: countryCode,
                            province: province,
                            city: city,
                            sector: sector,
                            addressLine: addressLine,
                            latitude: Double(latitude.replacingOccurrences(of: ",", with: ".")),
                            longitude: Double(longitude.replacingOccurrences(of: ",", with: ".")),
                            privacyMode: privacyMode
                        )
                        let ok = await viewModel.saveBranch(
                            SaveAdminBranchInput(
                                id: branch?.id,
                                code: code,
                                name: name,
                                type: type,
                                status: status,
                                location: location,
                                businessHoursId: businessHoursId,
                                clearLocation: clearLocation,
                                clearBusinessHoursId: clearBusinessHoursId,
                                reason: reason
                            )
                        )
                        if ok { dismiss() }
                    }
                }
            }
        }
        .navigationTitle(branch == nil ? "Nueva sucursal" : "Editar sucursal")
        .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { dismiss() } } }
    }
}
