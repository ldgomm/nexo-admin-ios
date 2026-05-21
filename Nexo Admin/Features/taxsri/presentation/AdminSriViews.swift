import SwiftUI

struct AdminSriSettingsView: View {
    @ObservedObject var viewModel: AdminTaxSriViewModel
    let permissions: Set<String>
    @State private var showEdit = false
    @State private var showProduction = false

    var body: some View {
        AdminTaxSriSectionCard(title: "Configuración SRI", subtitle: "Ambiente, emisión y gate de producción", systemImage: "network") {
            if let settings = viewModel.sriSettings {
                AdminTaxSriInfoRow(title: "Ambiente", value: settings.environment.uppercased(), systemImage: "server.rack")
                AdminTaxSriInfoRow(title: "Tipo emisión", value: settings.emissionType, systemImage: "paperplane")
                AdminTaxSriInfoRow(title: "Modo autorización", value: settings.authorizationMode, systemImage: "checkmark.seal")
                AdminTaxSriInfoRow(title: "Estab / Pto Emi", value: "\(settings.establishmentCode ?? "—")-\(settings.emissionPointCode ?? "—")", systemImage: "number.square")
                AdminTaxSriInfoRow(title: "Producción", value: settings.productionEnabled ? "Habilitada" : "No habilitada", systemImage: settings.productionEnabled ? "checkmark.shield" : "lock.shield")
                HStack {
                    if PermissionSet(permissions).can(PermissionCatalog.documentsElectronicInvoiceManageSettings) {
                        Button("Editar SRI") { showEdit = true }.buttonStyle(.bordered)
                    }
                    if PermissionSet(permissions).can(PermissionCatalog.documentsElectronicInvoiceEnableProduction) && !settings.productionEnabled {
                        Button("Solicitar producción") { showProduction = true }.buttonStyle(.borderedProminent)
                    }
                }
            } else {
                Text("No hay configuración SRI cargada.").foregroundStyle(.secondary)
            }
        }
        .sheet(isPresented: $showEdit) { SriSettingsEditSheet(viewModel: viewModel) { showEdit = false } }
        .sheet(isPresented: $showProduction) { ProductionGateSheet(viewModel: viewModel) { showProduction = false } }
    }
}

private struct SriSettingsEditSheet: View {
    @ObservedObject var viewModel: AdminTaxSriViewModel
    let onClose: () -> Void
    @State private var environment = "test"
    @State private var emissionType = "normal"
    @State private var authorizationMode = "offline"
    @State private var establishmentCode = ""
    @State private var emissionPointCode = ""
    @State private var reason = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("SRI") {
                    Picker("Ambiente", selection: $environment) {
                        Text("Pruebas").tag("test")
                        Text("Producción").tag("production")
                    }
                    TextField("Tipo emisión", text: $emissionType)
                    TextField("Modo autorización", text: $authorizationMode)
                    TextField("Establecimiento", text: $establishmentCode)
                    TextField("Punto emisión", text: $emissionPointCode)
                }
                Section("Advertencia") {
                    Text("Cambiar ambiente no habilita producción por sí solo. El backend mantiene el gate de habilitación.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Section("Motivo") { TextField("Motivo de auditoría", text: $reason, axis: .vertical).lineLimit(3, reservesSpace: true) }
            }
            .onAppear {
                environment = viewModel.sriSettings?.environment ?? "test"
                emissionType = viewModel.sriSettings?.emissionType ?? "normal"
                authorizationMode = viewModel.sriSettings?.authorizationMode ?? "offline"
                establishmentCode = viewModel.sriSettings?.establishmentCode ?? ""
                emissionPointCode = viewModel.sriSettings?.emissionPointCode ?? ""
            }
            .navigationTitle("Editar SRI")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancelar", action: onClose) }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        Task {
                            await viewModel.updateSriSettings(UpdateAdminSriSettingsInput(environment: environment, emissionType: emissionType, authorizationMode: authorizationMode, establishmentCode: establishmentCode, emissionPointCode: emissionPointCode, reason: reason))
                            onClose()
                        }
                    }.disabled(reason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

private struct ProductionGateSheet: View {
    @ObservedObject var viewModel: AdminTaxSriViewModel
    let onClose: () -> Void
    @State private var confirmation = ""
    @State private var reason = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Confirmación fuerte") {
                    Text("Escribe exactamente HABILITAR PRODUCCION. Esta acción solo solicita el gate; el backend decide si procede.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    TextField("HABILITAR PRODUCCION", text: $confirmation)
                }
                Section("Motivo") { TextField("Motivo de auditoría", text: $reason, axis: .vertical).lineLimit(3, reservesSpace: true) }
            }
            .navigationTitle("Gate producción")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancelar", action: onClose) }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Solicitar") {
                        Task {
                            await viewModel.requestProductionEnable(confirmationText: confirmation, reason: reason)
                            onClose()
                        }
                    }.disabled(confirmation != "HABILITAR PRODUCCION" || reason.isEmpty)
                }
            }
        }
    }
}

struct AdminSriReadinessView: View {
    @ObservedObject var viewModel: AdminTaxSriViewModel
    let permissions: Set<String>

    var body: some View {
        AdminTaxSriSectionCard(title: "Readiness SRI", subtitle: "Checklist antes de emitir", systemImage: "checkmark.seal") {
            if let readiness = viewModel.readiness {
                HStack {
                    Text("Estado: \(readiness.status.capitalized)").font(.headline)
                    Spacer()
                    Text("\(readiness.score)%").font(.title3.bold())
                }
                if !readiness.blockers.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Bloqueos").font(.subheadline.bold()).foregroundStyle(.red)
                        ForEach(readiness.blockers, id: \.self) { Text("• \($0)").font(.footnote) }
                    }
                }
                ForEach(readiness.items) { item in
                    HStack(alignment: .top) {
                        Image(systemName: item.status.lowercased() == "ok" || item.status.lowercased() == "ready" ? "checkmark.circle.fill" : item.required ? "xmark.octagon.fill" : "exclamationmark.triangle.fill")
                        VStack(alignment: .leading, spacing: 3) {
                            Text(item.title).font(.subheadline.weight(.semibold))
                            Text(item.description).font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        AdminTaxSriStatusBadge(text: item.status)
                    }
                    Divider()
                }
            } else {
                Text("Ejecuta readiness para conocer bloqueos.").foregroundStyle(.secondary)
            }
            if PermissionSet(permissions).can(PermissionCatalog.documentsElectronicInvoiceManageSettings) {
                Button(viewModel.isMutating ? "Ejecutando…" : "Ejecutar readiness") { Task { await viewModel.runReadiness() } }
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.isMutating)
            }
        }
    }
}

struct AdminSriHomologationView: View {
    @ObservedObject var viewModel: AdminTaxSriViewModel
    let permissions: Set<String>
    @State private var showReason = false

    var body: some View {
        AdminTaxSriSectionCard(title: "Homologación", subtitle: "Runs técnicos contra ambiente de pruebas", systemImage: "testtube.2") {
            if viewModel.homologationRuns.isEmpty {
                Text("No hay runs de homologación registrados.").foregroundStyle(.secondary)
            } else {
                ForEach(viewModel.homologationRuns) { run in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(run.id).font(.subheadline.weight(.semibold)).lineLimit(1)
                            Spacer()
                            AdminTaxSriStatusBadge(text: run.status)
                        }
                        Text("Ambiente: \(run.environment) • Inicio: \(run.startedAt ?? "—")")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        if let error = run.errorMessage { Text(error).font(.caption).foregroundStyle(.red) }
                    }
                    Divider()
                }
            }
            if PermissionSet(permissions).can(PermissionCatalog.documentsElectronicInvoiceHomologate) {
                Button("Ejecutar homologación") { showReason = true }.buttonStyle(.borderedProminent)
            }
        }
        .sheet(isPresented: $showReason) {
            AdminTaxSriReasonSheet(title: "Ejecutar homologación", actionTitle: "Ejecutar", onCancel: { showReason = false }) { reason in
                Task { await viewModel.startHomologation(reason: reason); showReason = false }
            }
        }
    }
}
