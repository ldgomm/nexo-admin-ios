//
//  AdminEmissionPointsView.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import SwiftUI

struct AdminEmissionPointsView: View {
    @ObservedObject var viewModel: AdminBusinessViewModel
    let permissions: Set<String>
    @State private var showCreate = false

    var body: some View {
        List {
            if viewModel.emissionPoints.isEmpty {
                EmptyStateView(systemImage: "number.square", title: "Sin puntos de emisión", message: "Configura establecimiento y punto de emisión antes de emitir documentos electrónicos.")
            } else {
                ForEach(viewModel.emissionPoints) { point in
                    NavigationLink {
                        AdminEmissionPointDetailView(viewModel: viewModel, permissions: permissions, point: point)
                    } label: {
                        AdminEmissionPointRow(point: point, branches: viewModel.branches)
                    }
                }
            }
        }
        .navigationTitle("Puntos de emisión")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if PermissionSet(permissions).can(PermissionCatalog.emissionPointsManage) {
                    Button { showCreate = true } label: { Image(systemName: "plus") }
                }
            }
        }
        .sheet(isPresented: $showCreate) {
            NavigationStack { EditAdminEmissionPointView(viewModel: viewModel, point: nil) }
        }
    }
}

private struct AdminEmissionPointRow: View {
    let point: AdminEmissionPoint
    let branches: [AdminBusinessBranch]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(point.displayName)
                        .font(.headline)
                    Text(point.fullCode)
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                Spacer()
                AdminBusinessStatusBadge(title: point.status.title, systemImage: "circle.fill", emphasis: point.status != .active)
            }
            Label(point.branchName(in: branches), systemImage: "building.2")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct AdminEmissionPointDetailView: View {
    @ObservedObject var viewModel: AdminBusinessViewModel
    let permissions: Set<String>
    let point: AdminEmissionPoint
    @State private var editing = false
    @State private var statusReason = "Actualización de estado de punto de emisión"
    @State private var showStatusDialog = false

    var body: some View {
        List {
            Section("Punto de emisión") {
                LabeledContent("Nombre", value: point.displayName)
                LabeledContent("Código completo", value: point.fullCode)
                LabeledContent("Establecimiento", value: point.establishmentCode)
                LabeledContent("Punto", value: point.emissionPointCode)
                LabeledContent("Estado", value: point.status.title)
            }
            Section("Sucursal") {
                LabeledContent("Sucursal", value: point.branchName(in: viewModel.branches))
                LabeledContent("Branch id", value: point.branchId)
            }
            Section {
                Text("Los códigos SRI se normalizan en backend a tres dígitos. Evita cambiar puntos activos en producción sin revisar secuencias/documentos.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if PermissionSet(permissions).can(PermissionCatalog.emissionPointsManage) {
                Section("Acciones") {
                    Button("Editar") { editing = true }
                    Button(point.status == .active ? "Desactivar" : "Activar") { showStatusDialog = true }
                        .foregroundStyle(point.status == .active ? .orange : .green)
                }
            }
        }
        .navigationTitle(point.displayName)
        .sheet(isPresented: $editing) { NavigationStack { EditAdminEmissionPointView(viewModel: viewModel, point: point) } }
        .sheet(isPresented: $showStatusDialog) {
            AdminBusinessActionReasonDialog(
                title: point.status == .active ? "Desactivar punto" : "Activar punto",
                message: "Esta acción afecta emisión documental y secuencias asociadas. El backend valida las reglas críticas.",
                reason: $statusReason,
                isSaving: viewModel.isSaving,
                confirmTitle: point.status == .active ? "Desactivar" : "Activar"
            ) {
                Task {
                    let ok = point.status == .active
                        ? await viewModel.deactivateEmissionPoint(point, reason: statusReason)
                        : await viewModel.activateEmissionPoint(point, reason: statusReason)
                    if ok { showStatusDialog = false }
                }
            }
            .presentationDetents([.medium])
        }
    }
}

struct EditAdminEmissionPointView: View {
    @ObservedObject var viewModel: AdminBusinessViewModel
    let point: AdminEmissionPoint?
    @Environment(\.dismiss) private var dismiss

    @State private var branchId: String
    @State private var establishmentCode: String
    @State private var emissionPointCode: String
    @State private var displayName: String
    @State private var status: String
    @State private var reason = "Configuración de punto de emisión"

    private let statuses = ["active", "inactive"]

    init(viewModel: AdminBusinessViewModel, point: AdminEmissionPoint?) {
        self.viewModel = viewModel
        self.point = point
        _branchId = State(initialValue: point?.branchId ?? viewModel.branches.first?.id ?? "")
        _establishmentCode = State(initialValue: point?.establishmentCode ?? "001")
        _emissionPointCode = State(initialValue: point?.emissionPointCode ?? "001")
        _displayName = State(initialValue: point?.displayName ?? "Caja 1")
        _status = State(initialValue: point?.status.rawValue == "unknown" ? "active" : point?.status.rawValue ?? "active")
    }

    var body: some View {
        Form {
            Section("Sucursal") {
                if viewModel.branches.isEmpty {
                    Text("Primero crea una sucursal activa.")
                        .foregroundStyle(.secondary)
                } else {
                    Picker("Sucursal", selection: $branchId) {
                        ForEach(viewModel.branches) { branch in
                            Text(branch.name).tag(branch.id)
                        }
                    }
                }
            }
            Section("Códigos SRI") {
                TextField("Establecimiento", text: $establishmentCode)
                    .keyboardType(.numberPad)
                TextField("Punto de emisión", text: $emissionPointCode)
                    .keyboardType(.numberPad)
                TextField("Nombre visible", text: $displayName)
                Picker("Estado", selection: $status) { ForEach(statuses, id: \.self) { Text($0.readableSnakeCase).tag($0) } }
                Text("Puedes ingresar 1, 01 o 001. El backend lo normaliza a tres dígitos.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            AdminBusinessReasonField(reason: $reason)
            Section {
                AdminBusinessSaveButton(title: point == nil ? "Crear punto" : "Guardar punto", isSaving: viewModel.isSaving) {
                    Task {
                        let ok = await viewModel.saveEmissionPoint(
                            SaveAdminEmissionPointInput(
                                id: point?.id,
                                branchId: branchId,
                                establishmentCode: establishmentCode,
                                emissionPointCode: emissionPointCode,
                                displayName: displayName,
                                status: status,
                                reason: reason
                            )
                        )
                        if ok { dismiss() }
                    }
                }
                .disabled(viewModel.branches.isEmpty)
            }
        }
        .navigationTitle(point == nil ? "Nuevo punto" : "Editar punto")
        .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { dismiss() } } }
    }
}
