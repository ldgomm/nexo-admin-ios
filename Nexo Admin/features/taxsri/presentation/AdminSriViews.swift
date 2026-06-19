//
//  AdminSriViews.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import Combine
import SwiftUI
import UIKit
import QuickLook

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
    let electronicDocumentRepository: (any AdminElectronicDocumentRepository)?
    @State private var showReason = false
    @State private var selectedRun: AdminSriHomologationRun?

    init(
        viewModel: AdminTaxSriViewModel,
        permissions: Set<String>,
        electronicDocumentRepository: (any AdminElectronicDocumentRepository)? = nil
    ) {
        self.viewModel = viewModel
        self.permissions = permissions
        self.electronicDocumentRepository = electronicDocumentRepository
    }

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
                AdminSriHomologationFeaturedRunCard(run: latestRun) {
                    selectedRun = latestRun
                }
            } else if !viewModel.isStartingHomologation {
                AdminSriHomologationEmptyState()
            }

            if !historicalRuns.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Historial")
                        .font(.subheadline.weight(.semibold))
                    ForEach(Array(historicalRuns)) { run in
                        AdminSriHomologationHistoryRow(run: run) {
                            selectedRun = run
                        }
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
        .sheet(item: $selectedRun) { run in
            AdminSriHomologationDetailSheet(
                run: run,
                documentRepository: electronicDocumentRepository,
                permissions: permissions
            )
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
    let onViewDetail: () -> Void

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

            if run.hasDocumentEvidence {
                AdminSriHomologationDocumentEvidenceCard(run: run, compact: true)
            }

            if run.humanErrorMessage != nil || run.suggestedRecoveryHint != nil {
                AdminSriHomologationErrorDiagnosticCard(run: run, compact: true)
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

            HStack(spacing: 10) {
                Button {
                    onViewDetail()
                } label: {
                    Label("Ver detalle", systemImage: "doc.text.magnifyingglass")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Button {
                    UIPasteboard.general.string = run.supportSummaryWithDocumentEvidence
                } label: {
                    Label("Copiar soporte", systemImage: "doc.on.doc")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
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

private struct AdminSriHomologationDocumentEvidenceCard: View {
    let run: AdminSriHomologationRun
    var compact: Bool
    var documentRepository: (any AdminElectronicDocumentRepository)?
    var permissions: Set<String>

    init(
        run: AdminSriHomologationRun,
        compact: Bool,
        documentRepository: (any AdminElectronicDocumentRepository)? = nil,
        permissions: Set<String> = []
    ) {
        self.run = run
        self.compact = compact
        self.documentRepository = documentRepository
        self.permissions = permissions
    }

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 8 : 12) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "doc.richtext")
                    .foregroundStyle(.blue)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Documento técnico relacionado")
                        .font(compact ? .caption.weight(.semibold) : .subheadline.weight(.semibold))
                    Text("La corrida ya trae vínculo documental desde backend. Usa el ID para abrir o buscar la factura técnica en Documentos electrónicos.")
                        .font(compact ? .caption2 : .caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            if compact {
                if let documentId = run.primaryDocumentId {
                    AdminSriCopyableEvidenceRow(title: "Documento", value: documentId)
                }
                AdminSriEvidenceMetric(title: "Estado documento", value: run.documentEvidenceStatusText, systemImage: "checkmark.seal")
            } else {
                AdminSriCopyableEvidenceRow(title: "Document ID", value: run.primaryDocumentId)
                AdminSriCopyableEvidenceRow(title: "Sale ID", value: run.primarySaleId)
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], alignment: .leading, spacing: 12) {
                    AdminSriEvidenceMetric(title: "Estado documento", value: run.documentEvidenceStatusText, systemImage: "checkmark.seal")
                    AdminSriEvidenceMetric(title: "Artefactos", value: run.artifactSummaryText, systemImage: "tray.full")
                }

                linkedDocumentAction
            }
        }
        .padding(compact ? 10 : 0)
        .background(
            Group {
                if compact {
                    RoundedRectangle(cornerRadius: 12).fill(.blue.opacity(0.08))
                } else {
                    Color.clear
                }
            }
        )
    }

    @ViewBuilder
    private var linkedDocumentAction: some View {
        if let documentId = run.primaryDocumentId, let documentRepository {
            NavigationLink {
                AdminSriLinkedHomologationDocumentScreen(
                    documentId: documentId,
                    repository: documentRepository,
                    permissions: permissions
                )
            } label: {
                Label("Ver documento técnico", systemImage: "doc.text.magnifyingglass")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        } else if run.primaryDocumentId != nil {
            NexoAdminUXInlineMessage(
                title: "Documento enlazado",
                message: "El contrato trae Document ID, pero esta entrada no recibió el repositorio de documentos para abrirlo desde aquí.",
                tone: .info
            )
        }
    }
}

private struct AdminSriLinkedHomologationDocumentScreen: View {
    @StateObject private var viewModel: AdminSriLinkedHomologationDocumentViewModel

    init(documentId: String, repository: any AdminElectronicDocumentRepository, permissions: Set<String>) {
        _viewModel = StateObject(
            wrappedValue: AdminSriLinkedHomologationDocumentViewModel(
                documentId: documentId,
                repository: repository,
                permissions: permissions
            )
        )
    }

    var body: some View {
        Group {
            switch viewModel.state {
            case .idle, .loading:
                NexoAdminUXLoadingState(
                    title: "Cargando documento técnico…",
                    message: "Consultando Document Vault por el ID generado en la homologación."
                )

            case .empty(let message):
                NexoAdminUXEmptyState(
                    systemImage: "doc.text.magnifyingglass",
                    title: "Sin documento",
                    message: message
                )
                .padding(16)

            case .failed(let message):
                NexoAdminUXEmptyState(
                    systemImage: "wifi.exclamationmark",
                    title: "No se pudo abrir el documento",
                    message: message,
                    actionTitle: "Reintentar"
                ) {
                    Task { await viewModel.load() }
                }
                .padding(16)

            case .loaded(let detail):
                loadedContent(detail)
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Documento técnico")
        .navigationBarTitleDisplayMode(.inline)
        .task(id: viewModel.documentId) { await viewModel.loadIfNeeded() }
        .sheet(item: $viewModel.previewFile) { file in
            AdminSriDocumentQuickLookPreview(fileURL: file.localURL)
        }
    }

    private func loadedContent(_ detail: AdminElectronicDocumentDetail) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                if let message = viewModel.actionMessage {
                    NexoAdminUXInlineMessage(title: "Listo", message: message, tone: .success)
                } else if let message = viewModel.actionErrorMessage {
                    NexoAdminUXInlineMessage(title: "No se pudo completar", message: message, tone: .danger)
                }

                NexoAdminUXCard {
                    NexoAdminUXSectionHeader(
                        "Factura técnica enlazada",
                        subtitle: "Documento creado por la corrida de homologación y almacenado en Document Vault.",
                        systemImage: "doc.richtext"
                    )

                    AdminSriCopyableEvidenceRow(title: "Document ID", value: detail.id)
                    AdminSriCopyableEvidenceRow(title: "Número", value: detail.summary.displayNumber)
                    AdminSriCopyableEvidenceRow(title: "Cliente", value: detail.summary.customerName)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], alignment: .leading, spacing: 12) {
                        AdminSriEvidenceMetric(title: "Estado", value: detail.summary.statusTitle, systemImage: "checkmark.seal")
                        AdminSriEvidenceMetric(title: "SRI", value: detail.summary.sriStatusTitle, systemImage: "building.columns")
                        AdminSriEvidenceMetric(title: "Ambiente", value: detail.summary.environmentTitle, systemImage: "server.rack")
                        AdminSriEvidenceMetric(title: "Total", value: detail.summary.moneyText, systemImage: "dollarsign.circle")
                    }
                }

                NexoAdminUXCard {
                    NexoAdminUXSectionHeader(
                        "Evidencia SRI",
                        subtitle: "Clave, autorización y fechas publicadas por el detalle documental.",
                        systemImage: "number.square"
                    )

                    AdminSriCopyableEvidenceRow(title: "Clave de acceso", value: detail.sri.accessKey ?? detail.summary.accessKey)
                    AdminSriCopyableEvidenceRow(title: "Autorización", value: detail.sri.authorizationNumber ?? detail.summary.authorizationNumber)
                    AdminSriCopyableEvidenceRow(title: "Autorizado en", value: detail.sri.authorizedAt ?? detail.summary.authorizedAt)
                }

                NexoAdminUXCard {
                    NexoAdminUXSectionHeader(
                        "Archivos",
                        subtitle: "Acciones reales disponibles desde el contrato actual de documentos electrónicos.",
                        systemImage: "tray.full"
                    )

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        Button {
                            Task { await viewModel.openRide() }
                        } label: {
                            if viewModel.isOpeningRide {
                                ProgressView().frame(maxWidth: .infinity)
                            } else {
                                Label("Abrir RIDE", systemImage: "doc.richtext")
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(!viewModel.canOpenRide(detail) || viewModel.isBusy)

                        Button {
                            Task { await viewModel.openXml() }
                        } label: {
                            if viewModel.isOpeningXml {
                                ProgressView().frame(maxWidth: .infinity)
                            } else {
                                Label("Abrir XML", systemImage: "chevron.left.forwardslash.chevron.right")
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .buttonStyle(.bordered)
                        .disabled(!viewModel.canOpenXml(detail) || viewModel.isBusy)
                    }

                    if detail.artifacts.ride == nil && detail.artifacts.authorizedXml == nil && detail.artifacts.signedXml == nil {
                        NexoAdminUXInlineMessage(
                            title: "Sin archivos reportados",
                            message: "El documento existe, pero el backend no reportó RIDE/XML disponibles para abrir desde Admin.",
                            tone: .warning
                        )
                    }
                }
            }
            .padding(16)
        }
    }
}

@MainActor
private final class AdminSriLinkedHomologationDocumentViewModel: ObservableObject {
    @Published private(set) var state: LoadableViewState<AdminElectronicDocumentDetail> = .idle
    @Published private(set) var actionMessage: String?
    @Published private(set) var actionErrorMessage: String?
    @Published private(set) var isOpeningRide = false
    @Published private(set) var isOpeningXml = false
    @Published var previewFile: AdminElectronicDocumentDownloadedFile?

    let documentId: String
    private let repository: any AdminElectronicDocumentRepository
    private let permissions: PermissionSet

    init(documentId: String, repository: any AdminElectronicDocumentRepository, permissions: Set<String>) {
        self.documentId = documentId
        self.repository = repository
        self.permissions = PermissionSet(values: permissions)
    }

    var isBusy: Bool { isOpeningRide || isOpeningXml }

    func loadIfNeeded() async {
        if case .idle = state {
            await load()
        }
    }

    func load() async {
        state = .loading
        actionMessage = nil
        actionErrorMessage = nil
        do {
            state = .loaded(try await repository.getDocument(id: documentId))
        } catch {
            state = .failed(error.userFriendlyMessage)
        }
    }

    func canOpenRide(_ detail: AdminElectronicDocumentDetail) -> Bool {
        let hasPermission = permissions.canAny([PermissionCatalog.documentsDownloadPDF, PermissionCatalog.documentsDownloadRide, PermissionCatalog.taxManage])
        return hasPermission && detail.artifacts.ride != nil
    }

    func canOpenXml(_ detail: AdminElectronicDocumentDetail) -> Bool {
        let hasPermission = permissions.canAny([PermissionCatalog.documentsDownloadXML, PermissionCatalog.taxManage])
        return hasPermission && (detail.artifacts.authorizedXml != nil || detail.artifacts.signedXml != nil)
    }

    func openRide() async {
        guard let detail = loadedDetail, canOpenRide(detail) else {
            actionErrorMessage = "No puedes abrir el RIDE para este documento o todavía no está disponible."
            return
        }
        guard !isBusy else { return }
        isOpeningRide = true
        actionMessage = nil
        actionErrorMessage = nil
        defer { isOpeningRide = false }
        do {
            previewFile = try await repository.downloadRideFile(documentId: documentId)
            actionMessage = "RIDE listo para visualizar."
        } catch {
            actionErrorMessage = error.userFriendlyMessage
        }
    }

    func openXml() async {
        guard let detail = loadedDetail, canOpenXml(detail) else {
            actionErrorMessage = "No puedes abrir el XML para este documento o todavía no está disponible."
            return
        }
        guard !isBusy else { return }
        isOpeningXml = true
        actionMessage = nil
        actionErrorMessage = nil
        defer { isOpeningXml = false }
        do {
            previewFile = try await repository.downloadXmlFile(documentId: documentId, authorizedOnly: true)
            actionMessage = "XML listo para visualizar."
        } catch {
            actionErrorMessage = error.userFriendlyMessage
        }
    }

    private var loadedDetail: AdminElectronicDocumentDetail? {
        if case .loaded(let detail) = state { return detail }
        return nil
    }
}

private struct AdminSriDocumentQuickLookPreview: UIViewControllerRepresentable {
    let fileURL: URL

    func makeCoordinator() -> Coordinator {
        Coordinator(fileURL: fileURL)
    }

    func makeUIViewController(context: Context) -> QLPreviewController {
        let controller = QLPreviewController()
        controller.dataSource = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: QLPreviewController, context: Context) {}

    final class Coordinator: NSObject, QLPreviewControllerDataSource {
        let fileURL: URL

        init(fileURL: URL) {
            self.fileURL = fileURL
        }

        func numberOfPreviewItems(in controller: QLPreviewController) -> Int { 1 }

        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
            fileURL as NSURL
        }
    }
}

private extension AdminSriHomologationRun {
    var supportSummaryWithDocumentEvidence: String {
        guard hasDocumentEvidence else { return supportSummary }

        var lines = [supportSummary, "", "Documento técnico relacionado:"]
        if let primaryDocumentId {
            lines.append("Document ID: \(primaryDocumentId)")
        }
        if let primarySaleId {
            lines.append("Sale ID: \(primarySaleId)")
        }
        if let primaryFinalDocumentStatus {
            lines.append("Estado documento: \(documentEvidenceStatusText) [\(primaryFinalDocumentStatus)]")
        }
        if !artifactTypes.isEmpty {
            lines.append("Artefactos: \(artifactSummaryText)")
        }
        return lines.joined(separator: "\n")
    }
}

private struct AdminSriHomologationChecklistRow: View {
    let item: AdminSriReadinessItem

    private var iconName: String {
        if item.isPassedForHomologation { return "checkmark.circle.fill" }
        if item.isFailedForHomologation { return "xmark.octagon.fill" }
        if item.isPendingForHomologation { return "hourglass.circle.fill" }
        if item.isSkippedForHomologation { return "minus.circle.fill" }
        return "questionmark.circle.fill"
    }

    private var tint: Color {
        if item.isPassedForHomologation { return .green }
        if item.isFailedForHomologation { return .red }
        if item.isPendingForHomologation { return .orange }
        return .secondary
    }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: iconName)
                .foregroundStyle(tint)
            VStack(alignment: .leading, spacing: 3) {
                Text(item.homologationDisplayTitle)
                    .font(.caption.weight(.semibold))
                Text(item.homologationDisplayDescription)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
            AdminTaxSriStatusBadge(text: item.humanStatus)
        }
    }
}


private struct AdminSriHomologationHistoryRow: View {
    let run: AdminSriHomologationRun
    let onViewDetail: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
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

            Button {
                onViewDetail()
            } label: {
                Image(systemName: "chevron.right.circle")
                    .font(.title3)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel("Ver detalle de homologación")
        }
    }
}


private struct AdminSriHomologationDetailSheet: View {
    let run: AdminSriHomologationRun
    let documentRepository: (any AdminElectronicDocumentRepository)?
    let permissions: Set<String>
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    AdminSriHomologationDetailHeader(run: run)

                    AdminTaxSriSectionCard(
                        title: "Evidencia de la corrida",
                        subtitle: "Datos principales que prueban qué se ejecutó y qué devolvió el backend.",
                        systemImage: "doc.text.magnifyingglass"
                    ) {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], alignment: .leading, spacing: 12) {
                            AdminSriEvidenceMetric(title: "Estado", value: run.displayStatus, systemImage: "checkmark.seal")
                            AdminSriEvidenceMetric(title: "Ambiente", value: run.displayEnvironment, systemImage: "server.rack")
                            AdminSriEvidenceMetric(title: "Inicio", value: run.displayStartedAt, systemImage: "clock")
                            AdminSriEvidenceMetric(title: "Fin", value: run.displayFinishedAt, systemImage: "checkmark.circle")
                            AdminSriEvidenceMetric(title: "Duración", value: run.durationText, systemImage: "timer")
                            AdminSriEvidenceMetric(title: "Checklist", value: run.checklist.isEmpty ? "—" : "\(run.checklist.count) ítem(s)", systemImage: "list.bullet.clipboard")
                        }
                    }

                    AdminTaxSriSectionCard(
                        title: "Identificadores técnicos",
                        subtitle: "Copia estos datos para soporte, logs o trazabilidad documental.",
                        systemImage: "number.square"
                    ) {
                        AdminSriCopyableEvidenceRow(title: "Run ID", value: run.id)
                        AdminSriCopyableEvidenceRow(title: "Clave de acceso", value: run.primaryAccessKey)
                        AdminSriCopyableEvidenceRow(title: "Número de autorización", value: run.primaryAuthorizationNumber)
                    }

                    if run.hasDocumentEvidence {
                        AdminTaxSriSectionCard(
                            title: "Documento técnico relacionado",
                            subtitle: "Contrato mínimo entre homologación y Document Vault.",
                            systemImage: "doc.richtext"
                        ) {
                            AdminSriHomologationDocumentEvidenceCard(
                                run: run,
                                compact: false,
                                documentRepository: documentRepository,
                                permissions: permissions
                            )
                        }
                    }

                    if run.humanErrorMessage != nil || run.suggestedRecoveryHint != nil {
                        AdminTaxSriSectionCard(
                            title: run.isRejected ? "Rechazo / fallo detectado" : "Error humano",
                            subtitle: "Diagnóstico entendible y siguiente revisión sugerida.",
                            systemImage: run.isRejected ? "doc.badge.exclamationmark" : "xmark.octagon"
                        ) {
                            AdminSriHomologationErrorDiagnosticCard(run: run, compact: false)
                        }
                    }

                    AdminTaxSriSectionCard(
                        title: "Resumen para soporte",
                        subtitle: "Texto listo para copiar en tickets, chats internos o diagnóstico.",
                        systemImage: "wrench.and.screwdriver"
                    ) {
                        AdminSriSupportSummaryCard(summary: run.supportSummaryWithDocumentEvidence)
                    }

                    if !run.checklist.isEmpty {
                        AdminTaxSriSectionCard(
                            title: "Checklist expandido",
                            subtitle: "Escenarios y validaciones devueltas por backend.",
                            systemImage: "checklist"
                        ) {
                            ForEach(run.checklist) { item in
                                AdminSriHomologationChecklistDetailRow(item: item)
                                if item.id != run.checklist.last?.id {
                                    Divider()
                                }
                            }
                        }
                    }

                    AdminSriHomologationProductionWarning()
                }
                .padding(16)
            }
            .navigationTitle("Detalle homologación")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        UIPasteboard.general.string = run.supportSummaryWithDocumentEvidence
                    } label: {
                        Label("Copiar", systemImage: "doc.on.doc")
                    }
                }
            }
        }
    }
}

private struct AdminSriHomologationDetailHeader: View {
    let run: AdminSriHomologationRun

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: run.detailIconName)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(run.detailTint)
                    .frame(width: 42, height: 42)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(run.detailTint.opacity(0.12))
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(run.displayTitle)
                        .font(.headline)
                    Text(run.detailHeadline)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
                AdminTaxSriStatusBadge(text: run.displayStatus)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(.background)
                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
        )
    }
}

private struct AdminSriHomologationErrorDiagnosticCard: View {
    let run: AdminSriHomologationRun
    var compact: Bool
    @State private var didCopyError = false

    private var title: String {
        if run.isRejected { return "Comprobante no autorizado" }
        if run.isRunning { return "Corrida en proceso" }
        return "La corrida no pasó"
    }

    private var iconName: String {
        if run.isRejected { return "doc.badge.exclamationmark" }
        if run.isRunning { return "hourglass.circle.fill" }
        return "xmark.octagon.fill"
    }

    private var tint: Color {
        if run.isRunning { return .orange }
        return .red
    }

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 8 : 12) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: iconName)
                    .foregroundStyle(tint)
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(compact ? .caption.weight(.semibold) : .subheadline.weight(.semibold))
                    Text(run.humanErrorMessage ?? "No llegó un mensaje de error humano. Copia el resumen para revisar el estado técnico y el checklist.")
                        .font(compact ? .caption2 : .footnote)
                        .foregroundStyle(compact ? .secondary : tint)
                        .textSelection(.enabled)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            if !compact, let rawError = run.rawErrorMessage, rawError != run.humanErrorMessage {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Error técnico original")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(rawError)
                        .font(.caption.monospaced())
                        .textSelection(.enabled)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.background.opacity(0.65))
                )
            }

            if let hint = run.suggestedRecoveryHint {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "wrench.and.screwdriver")
                        .foregroundStyle(.secondary)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Revisar primero")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Text(hint)
                            .font(compact ? .caption2 : .caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

            if run.shouldWarnAgainstBlindRetry {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text("No reintentes a ciegas. Si el fallo es de configuración, firma, secuencia, XML o rechazo SRI, repetir puede generar más ruido sin corregir la causa.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            if !compact, let rawError = run.rawErrorMessage {
                Button {
                    UIPasteboard.general.string = rawError
                    didCopyError = true
                } label: {
                    Label(didCopyError ? "Error copiado" : "Copiar error técnico", systemImage: didCopyError ? "checkmark" : "doc.on.doc")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(compact ? 10 : 0)
        .background(
            Group {
                if compact {
                    RoundedRectangle(cornerRadius: 12).fill(tint.opacity(0.08))
                }
            }
        )
    }
}


private struct AdminSriSupportSummaryCard: View {
    let summary: String
    @State private var didCopy = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(summary)
                .font(.caption.monospaced())
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.thinMaterial)
                )

            Button {
                UIPasteboard.general.string = summary
                didCopy = true
            } label: {
                Label(didCopy ? "Resumen copiado" : "Copiar resumen completo", systemImage: didCopy ? "checkmark" : "doc.on.doc")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

private struct AdminSriHomologationChecklistDetailRow: View {
    let item: AdminSriReadinessItem

    private var iconName: String {
        if item.isPassedForHomologation { return "checkmark.circle.fill" }
        if item.isFailedForHomologation { return "xmark.octagon.fill" }
        if item.isPendingForHomologation { return "hourglass.circle.fill" }
        if item.isSkippedForHomologation { return "minus.circle.fill" }
        return "questionmark.circle.fill"
    }

    private var tint: Color {
        if item.isPassedForHomologation { return .green }
        if item.isFailedForHomologation { return .red }
        if item.isPendingForHomologation { return .orange }
        return .secondary
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: iconName)
                    .foregroundStyle(tint)
                VStack(alignment: .leading, spacing: 3) {
                    Text(item.homologationDisplayTitle)
                        .font(.subheadline.weight(.semibold))
                    Text(item.homologationDisplayDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                AdminTaxSriStatusBadge(text: item.humanStatus)
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], alignment: .leading, spacing: 8) {
                AdminSriEvidenceMetric(title: "Código", value: item.code, systemImage: "tag")
                AdminSriEvidenceMetric(title: "Estado técnico", value: item.status.isEmpty ? "—" : item.status, systemImage: "terminal")
                AdminSriEvidenceMetric(title: "Estado humano", value: item.humanStatus, systemImage: "text.badge.checkmark")
                AdminSriEvidenceMetric(title: "Requerido", value: item.required ? "Sí" : "No", systemImage: item.required ? "asterisk" : "minus.circle")
            }

            if item.isFailedForHomologation && item.required {
                Text("Esta validación es requerida. No conviene reintentar a ciegas: primero revisa el error y la configuración relacionada.")
                    .font(.caption2)
                    .foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let actionLabel = item.actionLabel, !actionLabel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(actionLabel)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 4)
    }
}


private struct AdminSriHomologationProductionWarning: View {
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "lock.shield")
                .foregroundStyle(.orange)
            VStack(alignment: .leading, spacing: 4) {
                Text("TEST aprobado no habilita producción")
                    .font(.subheadline.weight(.semibold))
                Text("Este detalle sirve para auditoría técnica de ambiente de pruebas. Para producción se mantiene el gate separado, configuración productiva y autorización correspondiente.")
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

private extension AdminSriHomologationRun {
    var supportSummary: String {
        var lines: [String] = [
            "Nexo Admin — Homologación SRI TEST",
            "Run ID: \(id)",
            "Estado: \(displayStatus) [\(status.isEmpty ? "sin estado técnico" : status)]",
            "Ambiente: \(displayEnvironment)",
            "Inicio: \(displayStartedAt)",
            "Fin: \(displayFinishedAt)",
            "Duración: \(durationText)",
            "Clave de acceso: \(primaryAccessKey ?? "—")",
            "Autorización: \(primaryAuthorizationNumber ?? "—")"
        ]

        if let error = humanErrorMessage {
            lines.append("Error humano: \(error)")
        }

        if let rawError = rawErrorMessage, rawError != humanErrorMessage {
            lines.append("Error técnico: \(rawError)")
        }

        if let hint = suggestedRecoveryHint {
            lines.append("Revisar primero: \(hint)")
        }

        if shouldWarnAgainstBlindRetry {
            lines.append("Advertencia: no reintentar a ciegas; corregir causa probable antes de repetir.")
        }

        if !checklist.isEmpty {
            lines.append("Checklist:")
            lines.append(contentsOf: checklist.map { "- \($0.code): \($0.humanStatus) [\($0.status)] — \($0.homologationDisplayDescription)" })
        }

        lines.append("Nota: ambiente TEST aprobado no habilita producción.")
        return lines.joined(separator: "\n")
    }

    var detailHeadline: String {
        if isPassed {
            return "La prueba terminó correctamente y dejó evidencia técnica para soporte."
        }
        if isRunning {
            return "La prueba sigue en proceso. Espera a que el backend complete la corrida antes de tomar decisiones."
        }
        if isRejected {
            return "El comprobante no terminó autorizado. Revisa error, checklist y respuesta técnica antes de reintentar."
        }
        if isFailed {
            return "La prueba falló. Copia el resumen de soporte y revisa la acción sugerida sin abrir logs."
        }
        return "Revisa la evidencia técnica de esta corrida de homologación."
    }

    var detailIconName: String {
        if isPassed { return "checkmark.seal.fill" }
        if isRunning { return "hourglass" }
        if isRejected { return "doc.badge.exclamationmark" }
        if isFailed { return "xmark.octagon.fill" }
        return "questionmark.circle.fill"
    }

    var detailTint: Color {
        if isPassed { return .green }
        if isRunning { return .orange }
        if isFailed { return .red }
        return .gray
    }
}
