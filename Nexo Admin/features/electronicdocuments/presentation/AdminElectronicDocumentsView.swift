//
//  AdminElectronicDocumentsView.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import SwiftUI

struct AdminElectronicDocumentsView: View {
    @StateObject var viewModel: AdminElectronicDocumentsViewModel
    @State private var showsFilters = false
    @State private var showsRetryAuthorizationConfirmation = false
    @State private var showsRetryReceptionConfirmation = false
    @State private var showsRegenerateRideConfirmation = false
    @State private var showsEmailSheet = false
    @State private var showsShareSheet = false

    var body: some View {
        NavigationSplitView {
            documentList
                .navigationTitle("Comprobantes")
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            showsFilters = true
                        } label: {
                            Label("Filtros", systemImage: viewModel.filter.hasActiveFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                        }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            Task { await viewModel.refresh() }
                        } label: {
                            Label("Actualizar", systemImage: "arrow.clockwise")
                        }
                    }
                }
        } detail: {
            documentDetail
        }
        .task { await viewModel.load() }
        .sheet(isPresented: $showsFilters) {
            NavigationStack {
                AdminElectronicDocumentFiltersView(viewModel: viewModel)
            }
        }
        .sheet(isPresented: $showsEmailSheet) {
            NavigationStack {
                AdminElectronicDocumentEmailSheet(viewModel: viewModel)
            }
        }
        .confirmationDialog(
            "Reintentar autorización",
            isPresented: $showsRetryAuthorizationConfirmation,
            titleVisibility: .visible
        ) {
            Button("Reintentar autorización") {
                Task { await viewModel.retrySelectedAuthorization() }
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("El backend volverá a consultar la autorización y registrará auditoría. Úsalo solo para estados recuperables.")
        }
        .confirmationDialog(
            "Reintentar recepción",
            isPresented: $showsRetryReceptionConfirmation,
            titleVisibility: .visible
        ) {
            Button("Reintentar recepción") {
                Task { await viewModel.retrySelectedReception() }
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("El backend volverá a enviar el XML firmado al servicio de recepción del SRI sin generar nueva clave ni nuevo secuencial.")
        }
        .confirmationDialog(
            "Regenerar RIDE",
            isPresented: $showsRegenerateRideConfirmation,
            titleVisibility: .visible
        ) {
            Button("Regenerar RIDE") {
                Task { await viewModel.regenerateSelectedRide() }
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Solo se regenerará la representación imprimible. No se modifica XML, clave de acceso ni autorización.")
        }
        .alert("Listo", isPresented: Binding(get: { viewModel.lastActionMessage != nil }, set: { _ in viewModel.dismissActionMessages() })) {
            Button("OK", role: .cancel) { viewModel.dismissActionMessages() }
        } message: {
            Text(viewModel.lastActionMessage ?? "")
        }
        .alert("No se pudo completar", isPresented: Binding(get: { viewModel.actionErrorMessage != nil }, set: { _ in viewModel.dismissActionMessages() })) {
            Button("OK", role: .cancel) { viewModel.dismissActionMessages() }
        } message: {
            Text(viewModel.actionErrorMessage ?? "")
        }
        .sheet(isPresented: Binding(get: { viewModel.artifactToShare != nil && showsShareSheet }, set: { showsShareSheet = $0 })) {
            if let artifact = viewModel.artifactToShare, let url = artifact.downloadURL {
                ShareSheet(items: [url])
            } else {
                EmptyStateView(systemImage: "link.badge.plus", title: "Archivo no disponible", message: "El backend no devolvió una URL temporal para compartir este archivo.")
            }
        }
    }

    private var documentList: some View {
        Group {
            switch viewModel.documentsState {
            case .idle, .loading:
                VStack(spacing: 12) {
                    ProgressView()
                    Text("Cargando comprobantes…")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            case .empty(let message):
                EmptyStateView(systemImage: "doc.text.magnifyingglass", title: "Sin comprobantes", message: message)

            case .failed(let message):
                ErrorStateView(title: "No se pudieron cargar los comprobantes", message: message) {
                    Task { await viewModel.load() }
                }

            case .loaded(let documents):
                List(documents, selection: $viewModel.selectedDocumentId) { document in
                    Button {
                        Task { await viewModel.select(document: document) }
                    } label: {
                        AdminElectronicDocumentRow(document: document)
                    }
                    .buttonStyle(.plain)
                }
                .refreshable { await viewModel.refresh() }
            }
        }
    }

    private var documentDetail: some View {
        Group {
            switch viewModel.selectedDetailState {
            case .idle:
                EmptyStateView(systemImage: "doc.text", title: "Selecciona un comprobante", message: "Aquí verás estado SRI, errores, RIDE/XML, email y timeline.")

            case .loading:
                VStack(spacing: 12) {
                    ProgressView()
                    Text("Cargando detalle…")
                        .foregroundStyle(.secondary)
                }

            case .empty(let message):
                EmptyStateView(systemImage: "doc.text", title: "Sin detalle", message: message)

            case .failed(let message):
                ErrorStateView(title: "No se pudo cargar el comprobante", message: message) {
                    if let id = viewModel.selectedDocumentId {
                        Task { await viewModel.loadDetail(id: id) }
                    }
                }

            case .loaded(let detail):
                AdminElectronicDocumentDetailView(
                    detail: detail,
                    viewModel: viewModel,
                    onRetryReception: { showsRetryReceptionConfirmation = true },
                    onRetryAuthorization: { showsRetryAuthorizationConfirmation = true },
                    onRegenerateRide: { showsRegenerateRideConfirmation = true },
                    onEmail: { showsEmailSheet = true },
                    onShareRide: {
                        Task {
                            await viewModel.prepareRideShare()
                            showsShareSheet = true
                        }
                    },
                    onShareXml: {
                        Task {
                            await viewModel.prepareXmlShare()
                            showsShareSheet = true
                        }
                    }
                )
            }
        }
    }
}

private struct AdminElectronicDocumentRow: View {
    let document: AdminElectronicDocumentSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(document.displayNumber)
                        .font(.headline)
                    Text(document.customerName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(document.moneyText)
                    .font(.subheadline.bold())
            }

            HStack(spacing: 8) {
                StatusPill(title: document.sriStatusTitle, systemImage: sriIcon(document.sriStatus), tint: sriTint(document.sriStatus))
                StatusPill(title: document.environmentTitle, systemImage: "server.rack", tint: .secondary)
            }

            if let message = document.lastErrorMessage, !message.isEmpty {
                Label(message, systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 6)
    }

    private func sriIcon(_ status: String) -> String {
        switch status.lowercased() {
        case "authorized": "checkmark.seal.fill"
        case "returned", "rejected", "failed", "error": "xmark.octagon.fill"
        case "processing", "ppr": "clock.badge.exclamationmark"
        default: "doc.badge.clock"
        }
    }

    private func sriTint(_ status: String) -> Color {
        switch status.lowercased() {
        case "authorized": .green
        case "returned", "rejected", "failed", "error": .red
        case "processing", "ppr": .orange
        default: .secondary
        }
    }
}

private struct AdminElectronicDocumentDetailView: View {
    let detail: AdminElectronicDocumentDetail
    @ObservedObject var viewModel: AdminElectronicDocumentsViewModel
    let onRetryReception: () -> Void
    let onRetryAuthorization: () -> Void
    let onRegenerateRide: () -> Void
    let onEmail: () -> Void
    let onShareRide: () -> Void
    let onShareXml: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                actionBar
                operationalState
                sriState
                if !detail.errors.isEmpty { errorsSection }
                artifactsSection
                emailSection
                totalsSection
                linesSection
                timelineSection
            }
            .padding(16)
        }
        .navigationTitle(detail.summary.displayNumber)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        HCard {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(detail.summary.documentType.capitalized)
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                    Text(detail.summary.displayNumber)
                        .font(.title2.bold())
                    Text(detail.summary.customerName)
                        .font(.headline)
                    if let id = detail.summary.customerIdentification {
                        Text(id)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 8) {
                    Text(detail.summary.moneyText)
                        .font(.title3.bold())
                    StatusPill(title: detail.summary.sriStatusTitle, systemImage: "checkmark.seal", tint: detail.summary.isAuthorized ? .green : .orange)
                }
            }
        }
    }

    private var actionBar: some View {
        HCard {
            Text("Acciones")
                .font(.headline)
            let visibleActions = viewModel.visibleActions(on: detail)
            if visibleActions.isEmpty {
                Text("No hay acciones operativas disponibles para este comprobante en este momento.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(visibleActions, id: \.publicRawValue) { action in
                        ButtonActionCard(
                            title: action.title,
                            systemImage: actionIcon(action),
                            enabled: actionIsEnabled(action),
                            isLoading: viewModel.isLoadingAction(action),
                            action: actionHandler(action)
                        )
                    }
                }
            }
            if let title = viewModel.loadingActionTitle {
                ProgressView("Procesando: \(title)…")
            }
        }
    }

    private var operationalState: some View {
        HCard {
            Text("Resumen operativo")
                .font(.headline)
            if !detail.availableActions.isEmpty {
                LabeledContent("Acciones backend", value: detail.availableActions.map(\.title).joined(separator: " · "))
                    .font(.caption)
            }
            LabeledContent("Reintentos recepción", value: "\(detail.retrySummary.receptionRetryCount)")
            LabeledContent("Reintentos autorización", value: "\(detail.retrySummary.authorizationRetryCount)")
            LabeledContent("Intentos email", value: "\(detail.retrySummary.emailAttempts)")
            LabeledContent("Regeneraciones RIDE", value: "\(detail.retrySummary.rideRegenerationCount)")
            if let message = detail.retrySummary.message, !message.isEmpty {
                Label(message, systemImage: "info.circle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func actionIcon(_ action: AdminElectronicDocumentAction) -> String {
        switch action {
        case .downloadRide: "doc.richtext"
        case .downloadXml: "chevron.left.forwardslash.chevron.right"
        case .resendEmail: "paperplane"
        case .retryReception: "arrow.up.doc"
        case .retryAuthorization: "arrow.triangle.2.circlepath"
        case .regenerateRide: "doc.badge.gearshape"
        case .viewDetail: "doc.text.magnifyingglass"
        case .viewTimeline: "clock.arrow.circlepath"
        case .unknown: "questionmark.circle"
        }
    }

    private func actionIsEnabled(_ action: AdminElectronicDocumentAction) -> Bool {
        guard !viewModel.isPerformingAction else { return false }
        switch action {
        case .downloadRide:
            return viewModel.canPerform(.downloadRide, on: detail) && detail.artifacts.ride != nil
        case .downloadXml:
            return viewModel.canPerform(.downloadXml, on: detail) && (detail.artifacts.authorizedXml != nil || detail.artifacts.signedXml != nil)
        default:
            return viewModel.canPerform(action, on: detail)
        }
    }

    private func actionHandler(_ action: AdminElectronicDocumentAction) -> () -> Void {
        switch action {
        case .downloadRide:
            return onShareRide
        case .downloadXml:
            return onShareXml
        case .resendEmail:
            return onEmail
        case .retryReception:
            return onRetryReception
        case .retryAuthorization:
            return onRetryAuthorization
        case .regenerateRide:
            return onRegenerateRide
        default:
            return {}
        }
    }

    private var sriState: some View {
        HCard {
            Text("Estado SRI")
                .font(.headline)
            Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 8) {
                GridRow { Text("Ambiente").foregroundStyle(.secondary); Text(detail.sri.environmentTitle) }
                GridRow { Text("Recepción").foregroundStyle(.secondary); Text(detail.sri.receptionStatus ?? "—") }
                GridRow { Text("Autorización").foregroundStyle(.secondary); Text(detail.sri.authorizationStatus ?? detail.summary.sriStatusTitle) }
                GridRow { Text("Clave acceso").foregroundStyle(.secondary); Text(detail.sri.accessKey ?? "—").textSelection(.enabled) }
                GridRow { Text("Núm. autorización").foregroundStyle(.secondary); Text(detail.sri.authorizationNumber ?? "—").textSelection(.enabled) }
                GridRow { Text("Reintentos").foregroundStyle(.secondary); Text("\(detail.sri.retryCount)") }
            }
            .font(.subheadline)
        }
    }

    private var errorsSection: some View {
        HCard {
            Text("Errores SRI")
                .font(.headline)
            ForEach(detail.errors) { error in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        StatusPill(title: error.code, systemImage: "number", tint: .orange)
                        if error.retryable {
                            StatusPill(title: "Reintentable", systemImage: "arrow.clockwise", tint: .blue)
                        }
                    }
                    Text(error.userMessage)
                        .font(.subheadline.bold())
                    DisclosureGroup("Detalle técnico") {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(error.rawMessage)
                            if let technical = error.technicalMessage {
                                Text(technical)
                            }
                            if let field = error.field {
                                Text("Campo: \(field)")
                            }
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                    }
                }
                .padding(.vertical, 6)
                Divider()
            }
        }
    }

    private var artifactsSection: some View {
        HCard {
            Text("RIDE / XML")
                .font(.headline)
            ArtifactRow(title: "RIDE", artifact: detail.artifacts.ride)
            ArtifactRow(title: "XML autorizado", artifact: detail.artifacts.authorizedXml)
            ArtifactRow(title: "XML firmado", artifact: detail.artifacts.signedXml)
        }
    }

    private var emailSection: some View {
        HCard {
            Text("Email")
                .font(.headline)
            LabeledContent("Estado", value: detail.email.statusTitle)
            LabeledContent("Destinatario", value: detail.email.recipient ?? "—")
            LabeledContent("Enviado", value: detail.email.sentAt ?? "—")
            LabeledContent("Intentos", value: "\(detail.email.attempts)")
            if let error = detail.email.lastError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
    }

    private var totalsSection: some View {
        HCard {
            Text("Totales")
                .font(.headline)
            LabeledContent("Subtotal gravado", value: MoneyFormatter.format(detail.totals.subtotalTaxed, currency: detail.totals.currency))
            LabeledContent("Subtotal 0%", value: MoneyFormatter.format(detail.totals.subtotalZeroRate, currency: detail.totals.currency))
            LabeledContent("Subtotal exento", value: MoneyFormatter.format(detail.totals.subtotalExempt, currency: detail.totals.currency))
            LabeledContent("Descuento", value: MoneyFormatter.format(detail.totals.discountTotal, currency: detail.totals.currency))
            LabeledContent("IVA", value: MoneyFormatter.format(detail.totals.taxTotal, currency: detail.totals.currency))
            LabeledContent("Total", value: MoneyFormatter.format(detail.totals.grandTotal, currency: detail.totals.currency))
        }
    }

    private var linesSection: some View {
        HCard {
            Text("Líneas")
                .font(.headline)
            if detail.lines.isEmpty {
                Text("Sin líneas cargadas en el detalle.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(detail.lines) { line in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(line.description)
                                .font(.subheadline.bold())
                            Spacer()
                            Text(MoneyFormatter.format(line.subtotal, currency: detail.totals.currency))
                        }
                        Text("Cant. \(line.quantityText) • PU \(MoneyFormatter.format(line.unitPrice, currency: detail.totals.currency)) • IVA \(MoneyFormatter.format(line.taxValue, currency: detail.totals.currency))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Divider()
                }
            }
        }
    }

    private var timelineSection: some View {
        HCard {
            Text("Timeline")
                .font(.headline)
            if detail.timeline.isEmpty {
                Text("Sin eventos cargados.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(detail.timeline) { event in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: timelineIcon(event.severity))
                            .foregroundStyle(timelineTint(event.severity))
                        VStack(alignment: .leading, spacing: 4) {
                            Text(event.title)
                                .font(.subheadline.bold())
                            Text(event.message)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(event.createdAt)
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    Divider()
                }
            }

            Button {
                Task { await viewModel.refreshSelectedTimeline() }
            } label: {
                if viewModel.isLoadingAction(.viewTimeline) {
                    ProgressView()
                } else {
                    Label("Actualizar timeline", systemImage: "clock.arrow.circlepath")
                }
            }
            .disabled(!viewModel.canPerform(.viewTimeline, on: detail) || viewModel.isPerformingAction)
        }
    }

    private func timelineIcon(_ severity: AdminSriErrorSeverity) -> String {
        switch severity {
        case .info: "circle.fill"
        case .warning: "exclamationmark.triangle.fill"
        case .error: "xmark.octagon.fill"
        case .critical: "flame.fill"
        }
    }

    private func timelineTint(_ severity: AdminSriErrorSeverity) -> Color {
        switch severity {
        case .info: .blue
        case .warning: .orange
        case .error: .red
        case .critical: .red
        }
    }
}

private struct AdminElectronicDocumentFiltersView: View {
    @ObservedObject var viewModel: AdminElectronicDocumentsViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            Section("Búsqueda") {
                TextField("Cliente, número o clave", text: $viewModel.filter.query)
                TextField("Cliente", text: $viewModel.filter.customer)
                TextField("Número", text: $viewModel.filter.number)
                TextField("Tipo", text: $viewModel.filter.documentType)
            }
            Section("Estados") {
                Picker("Documento", selection: $viewModel.filter.status) {
                    ForEach(AdminElectronicDocumentStatusFilter.allCases) { status in
                        Text(status.title).tag(status)
                    }
                }
                Picker("SRI", selection: $viewModel.filter.sriStatus) {
                    ForEach(AdminSriStatusFilter.allCases) { status in
                        Text(status.title).tag(status)
                    }
                }
            }
            Section("Rango") {
                DatePicker("Desde", selection: Binding(get: { viewModel.filter.fromDate ?? Date() }, set: { viewModel.filter.fromDate = $0 }), displayedComponents: .date)
                Toggle("Usar fecha desde", isOn: Binding(get: { viewModel.filter.fromDate != nil }, set: { viewModel.filter.fromDate = $0 ? Date() : nil }))
                DatePicker("Hasta", selection: Binding(get: { viewModel.filter.toDate ?? Date() }, set: { viewModel.filter.toDate = $0 }), displayedComponents: .date)
                Toggle("Usar fecha hasta", isOn: Binding(get: { viewModel.filter.toDate != nil }, set: { viewModel.filter.toDate = $0 ? Date() : nil }))
            }
            Section {
                Button("Aplicar filtros") {
                    Task {
                        await viewModel.applyFilters()
                        dismiss()
                    }
                }
                Button("Limpiar filtros", role: .destructive) {
                    Task {
                        await viewModel.clearFilters()
                        dismiss()
                    }
                }
            }
        }
        .navigationTitle("Filtros")
        .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Cerrar") { dismiss() } } }
    }
}

private struct AdminElectronicDocumentEmailSheet: View {
    @ObservedObject var viewModel: AdminElectronicDocumentsViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            Section("Destinatario") {
                TextField("Correo alternativo opcional", text: $viewModel.recipientOverride)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
            Section("Motivo") {
                TextField("Motivo", text: $viewModel.emailReason, axis: .vertical)
                    .lineLimit(3...5)
            }
            Section {
                Button("Reenviar email") {
                    Task {
                        await viewModel.resendSelectedEmail()
                        dismiss()
                    }
                }
                .disabled(viewModel.isPerformingAction)
            }
        }
        .navigationTitle("Reenviar comprobante")
        .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Cerrar") { dismiss() } } }
    }
}

private struct StatusPill: View {
    let title: String
    let systemImage: String
    let tint: Color

    var body: some View {
        Label(title, systemImage: systemImage)
            .font(.caption.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(tint.opacity(0.12))
            .foregroundStyle(tint)
            .clipShape(Capsule())
    }
}

private struct ButtonActionCard: View {
    let title: String
    let systemImage: String
    let enabled: Bool
    var isLoading: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                } else {
                    Image(systemName: systemImage)
                        .font(.title3)
                }
                Text(title)
                    .font(.caption.bold())
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, minHeight: 72)
            .background(.quaternary.opacity(0.35))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(!enabled || isLoading)
        .opacity(enabled ? 1 : 0.45)
    }
}

private struct ArtifactRow: View {
    let title: String
    let artifact: AdminDocumentArtifact?

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.bold())
                Text(artifact?.fileName ?? "No disponible")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(artifact?.sizeText ?? "—")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

private struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
