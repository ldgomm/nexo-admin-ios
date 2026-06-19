//
//  AdminSriViews.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import SwiftUI
import UIKit

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

    private var canHomologate: Bool {
        PermissionSet(permissions).can(PermissionCatalog.documentsElectronicInvoiceHomologate)
    }

    private var latestRun: AdminSriHomologationRun? {
        viewModel.homologationRuns.first
    }

    private var historicalRuns: ArraySlice<AdminSriHomologationRun> {
        viewModel.homologationRuns.dropFirst()
    }

    var body: some View {
        AdminTaxSriSectionCard(
            title: "Homologación SRI TEST",
            subtitle: "Ejecuta una factura técnica de prueba y revisa la evidencia principal sin entrar a Mongo ni logs.",
            systemImage: "testtube.2"
        ) {
            AdminSriHomologationTestNotice()

            if viewModel.isStartingHomologation {
                AdminSriHomologationRunningCard()
            }

            if let latestRun {
                AdminSriHomologationFeaturedRunCard(run: latestRun)
            } else if !viewModel.isStartingHomologation {
                AdminSriHomologationEmptyState()
            }

            if !historicalRuns.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Historial")
                        .font(.subheadline.weight(.semibold))
                    ForEach(Array(historicalRuns)) { run in
                        AdminSriHomologationHistoryRow(run: run)
                        if run.id != historicalRuns.last?.id {
                            Divider()
                        }
                    }
                }
                .padding(.top, 4)
            }

            if canHomologate {
                Button {
                    guard !viewModel.isStartingHomologation else { return }
                    showReason = true
                } label: {
                    Label(
                        viewModel.isStartingHomologation ? "Ejecutando prueba…" : "Ejecutar homologación TEST",
                        systemImage: viewModel.isStartingHomologation ? "hourglass" : "play.circle.fill"
                    )
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isStartingHomologation)
                .padding(.top, 4)
            }
        }
        .sheet(isPresented: $showReason) {
            AdminTaxSriReasonSheet(
                title: "Probar emisión en ambiente de pruebas",
                actionTitle: viewModel.isStartingHomologation ? "Ejecutando…" : "Probar",
                isSubmitting: viewModel.isStartingHomologation,
                onCancel: {
                    if !viewModel.isStartingHomologation {
                        showReason = false
                    }
                }
            ) { reason in
                guard !viewModel.isStartingHomologation else { return }
                showReason = false
                Task {
                    await viewModel.startHomologation(reason: reason)
                }
            }
        }
    }
}

private struct AdminSriHomologationTestNotice: View {
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            VStack(alignment: .leading, spacing: 4) {
                Text("Esta prueba valida ambiente TEST")
                    .font(.subheadline.weight(.semibold))
                Text("Una corrida correcta demuestra que Nexo puede generar, firmar, enviar y consultar una factura técnica en pruebas. No habilita producción ni reemplaza la autorización/configuración productiva del SRI.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(.orange.opacity(0.10))
        )
    }
}

private struct AdminSriHomologationRunningCard: View {
    var body: some View {
        HStack(spacing: 12) {
            ProgressView()
            VStack(alignment: .leading, spacing: 3) {
                Text("Ejecutando prueba de homologación…")
                    .font(.subheadline.weight(.semibold))
                Text("No cierres esta pantalla. El botón queda bloqueado para evitar corridas duplicadas.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(.thinMaterial)
        )
    }
}

private struct AdminSriHomologationEmptyState: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Todavía no hay evidencia de homologación")
                .font(.subheadline.weight(.semibold))
            Text("Ejecuta una prueba para crear una factura técnica en ambiente TEST y ver aquí clave de acceso, autorización, duración y checklist.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(.thinMaterial)
        )
    }
}

private struct AdminSriHomologationFeaturedRunCard: View {
    let run: AdminSriHomologationRun

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Última corrida")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(run.displayTitle)
                        .font(.headline)
                }
                Spacer(minLength: 0)
                AdminTaxSriStatusBadge(text: run.displayStatus)
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], alignment: .leading, spacing: 10) {
                AdminSriEvidenceMetric(title: "Ambiente", value: run.displayEnvironment, systemImage: "server.rack")
                AdminSriEvidenceMetric(title: "Duración", value: run.durationText, systemImage: "timer")
                AdminSriEvidenceMetric(title: "Inicio", value: run.displayStartedAt, systemImage: "clock")
                AdminSriEvidenceMetric(title: "Fin", value: run.displayFinishedAt, systemImage: "checkmark.circle")
            }

            VStack(alignment: .leading, spacing: 8) {
                AdminSriCopyableEvidenceRow(title: "Clave de acceso", value: run.primaryAccessKey)
                AdminSriCopyableEvidenceRow(title: "Autorización", value: run.primaryAuthorizationNumber)
            }

            if let error = run.humanErrorMessage {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "xmark.octagon.fill")
                        .foregroundStyle(.red)
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            if !run.checklist.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Checklist técnico")
                        .font(.subheadline.weight(.semibold))
                    ForEach(run.checklist) { item in
                        AdminSriHomologationChecklistRow(item: item)
                    }
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.thinMaterial)
        )
    }
}

private struct AdminSriEvidenceMetric: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: systemImage)
                .foregroundStyle(.secondary)
                .frame(width: 18)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(value.isEmpty ? "—" : value)
                    .font(.caption.weight(.semibold))
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
        }
    }
}

private struct AdminSriCopyableEvidenceRow: View {
    let title: String
    let value: String?
    @State private var didCopy = false

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(value ?? "—")
                    .font(.caption.monospaced())
                    .textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
            if let value, !value.isEmpty {
                Button {
                    UIPasteboard.general.string = value
                    didCopy = true
                } label: {
                    Image(systemName: didCopy ? "checkmark" : "doc.on.doc")
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("Copiar \(title)")
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.background.opacity(0.6))
        )
    }
}

private struct AdminSriHomologationChecklistRow: View {
    let item: AdminSriReadinessItem

    private var isPassed: Bool {
        let value = item.status.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        return value == "PASSED" || value == "AUTHORIZED" || value == "OK" || value == "READY"
    }

    private var displayTitle: String {
        let value = item.title.trimmingCharacters(in: .whitespacesAndNewlines)
        if value == "FINAL_CONSUMER" || item.code == "FINAL_CONSUMER" {
            return "Factura consumidor final"
        }
        return value.isEmpty ? item.code : value
    }

    private var displayDescription: String {
        let value = item.description.trimmingCharacters(in: .whitespacesAndNewlines)
        if value.uppercased() == "AUTHORIZED" {
            return "Comprobante técnico autorizado en ambiente TEST."
        }
        return value.isEmpty ? "Sin descripción técnica." : value
    }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: isPassed ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .foregroundStyle(isPassed ? .green : .orange)
            VStack(alignment: .leading, spacing: 3) {
                Text(displayTitle)
                    .font(.caption.weight(.semibold))
                Text(displayDescription)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
            AdminTaxSriStatusBadge(text: item.status)
        }
    }
}

private struct AdminSriHomologationHistoryRow: View {
    let run: AdminSriHomologationRun

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(run.displayStartedAt)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
                Spacer(minLength: 8)
                AdminTaxSriStatusBadge(text: run.displayStatus)
            }
            HStack(spacing: 8) {
                Text(run.displayEnvironment)
                Text("•")
                Text(run.durationText)
                if let accessKey = run.primaryAccessKey {
                    Text("•")
                    Text(accessKey)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .font(.caption.monospaced())
                }
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
    }
}
