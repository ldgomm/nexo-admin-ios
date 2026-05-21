//
//  AdminActivitiesView.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import SwiftUI

struct AdminActivitiesView: View {
    @ObservedObject var viewModel: AdminBusinessViewModel
    let permissions: Set<String>
    @State private var showCreate = false

    var body: some View {
        List {
            if viewModel.activities.isEmpty {
                EmptyStateView(systemImage: "square.stack.3d.up", title: "Sin actividades", message: "Configura al menos una actividad para operar ventas o reservas.")
            } else {
                ForEach(viewModel.activities) { activity in
                    NavigationLink {
                        AdminActivityDetailView(viewModel: viewModel, permissions: permissions, activity: activity)
                    } label: {
                        AdminActivityRow(activity: activity)
                    }
                }
            }
        }
        .navigationTitle("Actividades")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if PermissionSet(permissions).can(PermissionCatalog.activitiesCreate) {
                    Button { showCreate = true } label: { Image(systemName: "plus") }
                }
            }
        }
        .sheet(isPresented: $showCreate) {
            NavigationStack {
                EditAdminActivityView(viewModel: viewModel, activity: nil)
            }
        }
    }
}

private struct AdminActivityRow: View {
    let activity: AdminBusinessActivity

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(activity.name)
                    .font(.headline)
                Spacer()
                AdminBusinessStatusBadge(title: activity.status.title, systemImage: "circle.fill", emphasis: activity.status != .active)
            }
            Text("\(activity.readableType) • \(activity.readableWorkflow)")
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack(spacing: 8) {
                if activity.requiresScheduling { Label("Agenda", systemImage: "calendar") }
                if activity.tracksInventory { Label("Stock", systemImage: "shippingbox") }
                if activity.allowsReceivables { Label("Fiado", systemImage: "creditcard") }
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct AdminActivityDetailView: View {
    @ObservedObject var viewModel: AdminBusinessViewModel
    let permissions: Set<String>
    let activity: AdminBusinessActivity
    @State private var editing = false
    @State private var statusReason = "Actualización de estado de actividad"
    @State private var showStatusDialog = false

    var body: some View {
        List {
            Section("Actividad") {
                LabeledContent("Nombre", value: activity.name)
                LabeledContent("Código", value: activity.code ?? "No configurado")
                LabeledContent("Tipo", value: activity.readableType)
                LabeledContent("Flujo", value: activity.readableWorkflow)
                LabeledContent("Estado", value: activity.status.title)
                if let description = activity.description { Text(description).foregroundStyle(.secondary) }
            }
            Section("Reglas operativas") {
                LabeledContent("Requiere agenda", value: activity.requiresScheduling ? "Sí" : "No")
                LabeledContent("Controla inventario", value: activity.tracksInventory ? "Sí" : "No")
                LabeledContent("Permite cuentas por cobrar", value: activity.allowsReceivables ? "Sí" : "No")
                LabeledContent("Orden", value: "\(activity.sortOrder)")
            }
            if PermissionSet(permissions).can(PermissionCatalog.activitiesUpdate) {
                Section("Acciones") {
                    Button("Editar") { editing = true }
                    Button(activity.status == .active ? "Desactivar" : "Activar") { showStatusDialog = true }
                        .foregroundStyle(activity.status == .active ? .orange : .green)
                }
            }
        }
        .navigationTitle(activity.name)
        .sheet(isPresented: $editing) {
            NavigationStack { EditAdminActivityView(viewModel: viewModel, activity: activity) }
        }
        .sheet(isPresented: $showStatusDialog) {
            AdminBusinessActionReasonDialog(
                title: activity.status == .active ? "Desactivar actividad" : "Activar actividad",
                message: "Esta acción cambia la operación disponible para ventas o reservas.",
                reason: $statusReason,
                isSaving: viewModel.isSaving,
                confirmTitle: activity.status == .active ? "Desactivar" : "Activar"
            ) {
                Task {
                    let ok = activity.status == .active
                        ? await viewModel.deactivateActivity(activity, reason: statusReason)
                        : await viewModel.activateActivity(activity, reason: statusReason)
                    if ok { showStatusDialog = false }
                }
            }
            .presentationDetents([.medium])
        }
    }
}

struct EditAdminActivityView: View {
    @ObservedObject var viewModel: AdminBusinessViewModel
    let activity: AdminBusinessActivity?
    @Environment(\.dismiss) private var dismiss

    @State private var code: String
    @State private var name: String
    @State private var description: String
    @State private var activityType: String
    @State private var workflowMode: String
    @State private var status: String
    @State private var requiresScheduling: Bool
    @State private var tracksInventory: Bool
    @State private var allowsReceivables: Bool
    @State private var sortOrder: Int
    @State private var reason = "Configuración de actividad del negocio"

    private let activityTypes = ["restaurant", "retail", "services", "tourism", "rental", "mixed", "custom"]
    private let workflowModes = ["quick_sale", "order", "reservation", "service_order", "rental"]
    private let statuses = ["active", "draft", "paused"]

    init(viewModel: AdminBusinessViewModel, activity: AdminBusinessActivity?) {
        self.viewModel = viewModel
        self.activity = activity
        _code = State(initialValue: activity?.code ?? "")
        _name = State(initialValue: activity?.name ?? "")
        _description = State(initialValue: activity?.description ?? "")
        _activityType = State(initialValue: activity?.activityType ?? "retail")
        _workflowMode = State(initialValue: activity?.workflowMode ?? "quick_sale")
        _status = State(initialValue: activity?.status.rawValue == "unknown" ? "active" : activity?.status.rawValue ?? "active")
        _requiresScheduling = State(initialValue: activity?.requiresScheduling ?? false)
        _tracksInventory = State(initialValue: activity?.tracksInventory ?? false)
        _allowsReceivables = State(initialValue: activity?.allowsReceivables ?? true)
        _sortOrder = State(initialValue: activity?.sortOrder ?? 0)
    }

    var body: some View {
        Form {
            Section("Identificación") {
                TextField("Código", text: $code)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                TextField("Nombre", text: $name)
                TextField("Descripción", text: $description, axis: .vertical)
                    .lineLimit(2...4)
            }
            Section("Tipo y flujo") {
                Picker("Tipo", selection: $activityType) { ForEach(activityTypes, id: \.self) { Text($0.readableSnakeCase).tag($0) } }
                Picker("Flujo", selection: $workflowMode) { ForEach(workflowModes, id: \.self) { Text($0.readableSnakeCase).tag($0) } }
                Picker("Estado", selection: $status) { ForEach(statuses, id: \.self) { Text($0.readableSnakeCase).tag($0) } }
            }
            Section("Reglas") {
                Toggle("Requiere agenda", isOn: $requiresScheduling)
                Toggle("Controla inventario", isOn: $tracksInventory)
                Toggle("Permite cuentas por cobrar", isOn: $allowsReceivables)
                Stepper("Orden: \(sortOrder)", value: $sortOrder, in: 0...999)
            }
            AdminBusinessReasonField(reason: $reason)
            Section {
                AdminBusinessSaveButton(title: activity == nil ? "Crear actividad" : "Guardar actividad", isSaving: viewModel.isSaving) {
                    Task {
                        let ok = await viewModel.saveActivity(
                            SaveAdminActivityInput(
                                id: activity?.id,
                                code: code,
                                name: name,
                                description: description,
                                activityType: activityType,
                                workflowMode: workflowMode,
                                status: status,
                                requiresScheduling: requiresScheduling,
                                tracksInventory: tracksInventory,
                                allowsReceivables: allowsReceivables,
                                sortOrder: sortOrder,
                                reason: reason
                            )
                        )
                        if ok { dismiss() }
                    }
                }
            }
        }
        .navigationTitle(activity == nil ? "Nueva actividad" : "Editar actividad")
        .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { dismiss() } } }
    }
}
