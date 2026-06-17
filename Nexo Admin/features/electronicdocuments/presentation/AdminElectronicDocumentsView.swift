//
//  AdminElectronicDocumentsView.swift
//  Nexo Admin
//
//  Created by José Ruiz on 2/6/26.
//

import SwiftUI
import QuickLook

struct AdminElectronicDocumentsView: View {
    @StateObject var viewModel: AdminElectronicDocumentsViewModel
    @State private var showsRetryAuthorizationConfirmation = false
    @State private var showsRetryReceptionConfirmation = false
    @State private var showsRegenerateRideConfirmation = false
    @State private var showsEmailSheet = false
    @State private var pendingSearchTask: Task<Void, Never>?

    var body: some View {
        List {
            messageSection
            AdminElectronicDocumentFiltersView(
                viewModel: viewModel,
                onDebouncedSearch: scheduleSearch,
                onImmediateSearch: runSearchNow,
                onClearFilters: clearFiltersNow
            )
            documentsSection
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Comprobantes")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NexoAdminUXRefreshButton(isLoading: isLoadingDocuments || viewModel.isPerformingAction) {
                    Task { await viewModel.refresh() }
                }
            }
        }
        .task { await viewModel.load() }
        .refreshable { await viewModel.refresh() }
        .onDisappear {
            pendingSearchTask?.cancel()
            pendingSearchTask = nil
        }
        .sheet(isPresented: $showsEmailSheet) {
            NavigationStack {
                AdminElectronicDocumentEmailSheet(viewModel: viewModel)
            }
            .presentationDetents([.medium, .large])
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
            Text("El backend volverá a consultar autorización y registrará auditoría. Úsalo solo para estados recuperables.")
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
            Text("El backend reenviará el XML firmado al servicio de recepción del SRI sin generar nueva clave ni nuevo secuencial.")
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
        .sheet(item: $viewModel.previewFile) { file in
            AdminElectronicDocumentQuickLookPreview(fileURL: file.localURL)
        }
    }

    @ViewBuilder
    private var messageSection: some View {
        if let message = viewModel.lastActionMessage {
            Section {
                NexoAdminUXInlineMessage(title: "Listo", message: message, tone: .success)
                    .onTapGesture { viewModel.dismissActionMessages() }
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowBackground(Color.clear)
            }
        } else if let message = viewModel.actionErrorMessage {
            Section {
                NexoAdminUXInlineMessage(title: "No se pudo completar", message: message, tone: .danger)
                    .onTapGesture { viewModel.dismissActionMessages() }
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowBackground(Color.clear)
            }
        }
    }

    @ViewBuilder
    private var documentsSection: some View {
        switch viewModel.documentsState {
        case .idle, .loading:
            documentsLoadingSection

        case .empty(let message):
            documentsEmptySection(message)

        case .failed(let message):
            documentsFailedSection(message)

        case .loaded(let documents):
            documentsLoadedSection(documents)
        }
    }

    private var documentsLoadingSection: some View {
        Section {
            AdminElectronicDocumentsLoadingRow()
        } header: {
            Text("Resultados")
        }
    }

    @ViewBuilder
    private func documentsEmptySection(_ message: String) -> some View {
        Section {
            if viewModel.filter.hasActiveFilters {
                NexoAdminUXEmptyState(
                    systemImage: "doc.text.magnifyingglass",
                    title: "Sin coincidencias",
                    message: "No hay comprobantes con esos filtros. Limpia o cambia la búsqueda.",
                    actionTitle: "Limpiar filtros",
                    action: { clearFiltersNow() }
                )
                .padding(.vertical, 8)
                .listRowBackground(Color.clear)
            } else {
                NexoAdminUXEmptyState(
                    systemImage: "doc.text.magnifyingglass",
                    title: "Sin comprobantes",
                    message: message,
                    actionTitle: nil,
                    action: nil
                )
                .padding(.vertical, 8)
                .listRowBackground(Color.clear)
            }
        }
    }

    private func documentsFailedSection(_ message: String) -> some View {
        Section {
            NexoAdminUXEmptyState(
                systemImage: "wifi.exclamationmark",
                title: "No se pudieron cargar",
                message: message,
                actionTitle: "Reintentar",
                action: { Task { await viewModel.load() } }
            )
            .padding(.vertical, 8)
            .listRowBackground(Color.clear)
        }
    }

    private func documentsLoadedSection(_ documents: [AdminElectronicDocumentSummary]) -> some View {
        Section {
            ForEach(documents) { document in
                NavigationLink {
                    documentDestination(for: document)
                } label: {
                    AdminElectronicDocumentRow(document: document)
                }
                .buttonStyle(.plain)
            }
        } header: {
            resultsHeader(count: documents.count)
        } footer: {
            resultsFooter(count: documents.count)
        }
    }
    
    private func resultsHeader(count: Int) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text("Resultados")
            Spacer()
            Text("\(count)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private func resultsFooter(count: Int) -> some View {
        if count > 0 {
            if viewModel.filter.hasActiveFilters {
                Text("Filtros aplicados automáticamente. Limpia filtros para volver al listado reciente.")
            } else {
                Text("Mostrando comprobantes recientes. El detalle, RIDE/XML y timeline se cargan solo al abrir un comprobante.")
            }
        }
    }

    private var isLoadingDocuments: Bool {
        switch viewModel.documentsState {
        case .loading:
            return true
        default:
            return false
        }
    }

    private func scheduleSearch() {
        pendingSearchTask?.cancel()
        pendingSearchTask = Task {
            try? await Task.sleep(nanoseconds: 420_000_000)
            guard !Task.isCancelled else { return }
            await viewModel.applyFilters()
        }
    }

    private func runSearchNow() {
        pendingSearchTask?.cancel()
        pendingSearchTask = nil
        Task { await viewModel.applyFilters() }
    }

    private func clearFiltersNow() {
        pendingSearchTask?.cancel()
        pendingSearchTask = nil
        Task { await viewModel.clearFilters() }
    }

    private func documentDestination(for document: AdminElectronicDocumentSummary) -> some View {
        documentDetail
            .task(id: document.id) {
                await viewModel.select(document: document)
            }
    }

    private var documentDetail: some View {
        Group {
            switch viewModel.selectedDetailState {
            case .idle:
                NexoAdminUXEmptyState(
                    systemImage: "doc.text",
                    title: "Selecciona un comprobante",
                    message: "Aquí verás estado SRI, errores, RIDE/XML, email y timeline."
                )
                .padding(16)

            case .loading:
                NexoAdminUXLoadingState(
                    title: "Cargando detalle…",
                    message: "Consultando información completa del comprobante, artefactos y timeline."
                )

            case .empty(let message):
                NexoAdminUXEmptyState(systemImage: "doc.text", title: "Sin detalle", message: message)
                    .padding(16)

            case .failed(let message):
                NexoAdminUXEmptyState(
                    systemImage: "wifi.exclamationmark",
                    title: "No se pudo cargar el comprobante",
                    message: message,
                    actionTitle: "Reintentar"
                ) {
                    if let id = viewModel.selectedDocumentId {
                        Task { await viewModel.loadDetail(id: id) }
                    }
                }
                .padding(16)

            case .loaded(let detail):
                AdminElectronicDocumentDetailView(
                    detail: detail,
                    viewModel: viewModel,
                    onRetryReception: { showsRetryReceptionConfirmation = true },
                    onRetryAuthorization: { showsRetryAuthorizationConfirmation = true },
                    onRegenerateRide: { showsRegenerateRideConfirmation = true },
                    onEmail: { showsEmailSheet = true },
                    onShareRide: { Task { await viewModel.prepareRideShare() } },
                    onShareXml: { Task { await viewModel.prepareXmlShare() } }
                )
            }
        }
        .background(Color(.systemGroupedBackground))
    }
}

private struct AdminElectronicDocumentsLoadingRow: View {
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ProgressView()
            VStack(alignment: .leading, spacing: 3) {
                Text("Cargando comprobantes…")
                    .font(.subheadline.weight(.semibold))
                Text("Admin carga el listado de forma ligera. El detalle se abre bajo demanda para que la pantalla no se sienta pesada.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 10)
    }
}

private struct AdminElectronicDocumentRow: View {
    let document: AdminElectronicDocumentSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(document.displayNumber)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(document.customerName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer(minLength: 8)
                Text(document.moneyText)
                    .font(.subheadline.weight(.bold))
                    .monospacedDigit()
            }

            HStack(spacing: 8) {
                NexoAdminUXStatusBadge(
                    title: document.sriStatusTitle,
                    systemImage: sriIcon(document.sriStatus),
                    tint: sriTint(document.sriStatus)
                )
                NexoAdminUXStatusBadge(title: document.environmentTitle, systemImage: "server.rack", tint: .secondary)
            }

            if let message = document.lastErrorMessage, !message.isEmpty {
                Label(message, systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 7)
    }

    private func sriIcon(_ status: String) -> String {
        switch status.lowercased() {
        case "authorized": return "checkmark.seal.fill"
        case "returned", "rejected", "failed", "error": return "xmark.octagon.fill"
        case "processing", "ppr": return "clock.badge.exclamationmark"
        default: return "doc.badge.clock"
        }
    }

    private func sriTint(_ status: String) -> Color {
        switch status.lowercased() {
        case "authorized": return .green
        case "returned", "rejected", "failed", "error": return .red
        case "processing", "ppr": return .orange
        default: return .secondary
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
            LazyVStack(alignment: .leading, spacing: 16) {
                header
                primaryActions
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
        .background(Color(.systemGroupedBackground))
        .navigationTitle(detail.summary.displayNumber)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        NexoAdminUXCard(padding: 18) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(detail.summary.documentType.uppercased())
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.secondary)
                        .tracking(0.5)
                    Text(detail.summary.displayNumber)
                        .font(.title2.weight(.bold))
                    Text(detail.summary.customerName)
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    if let id = detail.summary.customerIdentification {
                        Text(id)
                            .font(.caption.monospaced())
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                    }
                }
                Spacer(minLength: 8)
                VStack(alignment: .trailing, spacing: 8) {
                    Text(detail.summary.moneyText)
                        .font(.title3.weight(.bold))
                        .monospacedDigit()
                    NexoAdminUXStatusBadge(
                        title: detail.summary.sriStatusTitle,
                        systemImage: detail.summary.isAuthorized ? "checkmark.seal.fill" : "doc.badge.clock",
                        tint: detail.summary.isAuthorized ? .green : .orange
                    )
                }
            }
        }
    }

    private var primaryActions: some View {
        NexoAdminUXCard {
            NexoAdminUXSectionHeader(
                "Acciones disponibles",
                subtitle: "Solo muestra acciones reales para el estado actual. Nada de botones muertos.",
                systemImage: "bolt.fill"
            )

            let actions = viewModel.visibleActions(on: detail)
            if actions.isEmpty {
                NexoAdminUXInlineMessage(
                    title: "Sin acciones por ahora",
                    message: "Este comprobante no tiene acciones operativas disponibles con el estado y permisos actuales.",
                    tone: .info
                )
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(actions, id: \.publicRawValue) { action in
                        AdminDocumentActionTile(
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
                NexoAdminUXInlineMessage(
                    title: "Procesando",
                    message: "Ejecutando: \(title)…",
                    tone: .info
                )
            }
        }
    }

    private var operationalState: some View {
        NexoAdminUXCard {
            NexoAdminUXSectionHeader(
                "Resumen operativo",
                subtitle: "Trazabilidad de intentos, emails y regeneraciones.",
                systemImage: "list.bullet.rectangle"
            )

            if !detail.availableActions.isEmpty {
                Text(detail.availableActions.map(\.title).joined(separator: " · "))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 9) {
                NexoAdminUXPlainRow(title: "Reintentos recepción", value: "\(detail.retrySummary.receptionRetryCount)", systemImage: "arrow.up.doc")
                NexoAdminUXPlainRow(title: "Reintentos autorización", value: "\(detail.retrySummary.authorizationRetryCount)", systemImage: "arrow.triangle.2.circlepath")
                NexoAdminUXPlainRow(title: "Intentos email", value: "\(detail.retrySummary.emailAttempts)", systemImage: "paperplane")
                NexoAdminUXPlainRow(title: "Regeneraciones RIDE", value: "\(detail.retrySummary.rideRegenerationCount)", systemImage: "doc.badge.gearshape")
            }

            if let message = detail.retrySummary.safeMessage {
                NexoAdminUXInlineMessage(title: "Nota", message: message, tone: .info)
            }
        }
    }

    private var sriState: some View {
        NexoAdminUXCard {
            NexoAdminUXSectionHeader(
                "Estado SRI",
                subtitle: "Datos clave para soporte, sin obligar al usuario a leer XML.",
                systemImage: "server.rack"
            )

            VStack(spacing: 9) {
                NexoAdminUXPlainRow(title: "Ambiente", value: detail.sri.environmentTitle, systemImage: "globe")
                NexoAdminUXPlainRow(title: "Recepción", value: detail.sri.receptionStatus ?? "—", systemImage: "tray.and.arrow.down")
                NexoAdminUXPlainRow(title: "Autorización", value: detail.sri.authorizationStatus ?? detail.summary.sriStatusTitle, systemImage: "checkmark.seal")
                NexoAdminUXPlainRow(title: "Reintentos", value: "\(detail.sri.retryCount)", systemImage: "arrow.clockwise")
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Clave de acceso")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(detail.sri.accessKey ?? "—")
                    .font(.caption.monospaced())
                    .textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Número de autorización")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(detail.sri.authorizationNumber ?? "—")
                    .font(.caption.monospaced())
                    .textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var errorsSection: some View {
        NexoAdminUXCard {
            NexoAdminUXSectionHeader(
                "Errores SRI",
                subtitle: "Primero mensaje humano; el detalle técnico queda plegado.",
                systemImage: "exclamationmark.triangle.fill"
            )

            ForEach(detail.errors) { error in
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        NexoAdminUXStatusBadge(title: error.safeCode, systemImage: "number", tint: .orange)
                        if error.retryable {
                            NexoAdminUXStatusBadge(title: "Reintentable", systemImage: "arrow.clockwise", tint: .blue)
                        }
                    }

                    Text(error.safeUserMessage)
                        .font(.subheadline.weight(.semibold))

                    DisclosureGroup("Detalle técnico") {
                        VStack(alignment: .leading, spacing: 6) {
                            if let raw = error.safeRawMessage {
                                Text(raw)
                            }
                            if let technical = error.safeTechnicalMessage {
                                Text(technical)
                            }
                            if let field = error.safeField {
                                Text("Campo: \(field)")
                            }
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                    }
                }
                .padding(.vertical, 6)

                if error.id != detail.errors.last?.id { Divider() }
            }
        }
    }

    private var artifactsSection: some View {
        NexoAdminUXCard {
            NexoAdminUXSectionHeader(
                "RIDE / XML",
                subtitle: "Artefactos disponibles para soporte, descarga o envío.",
                systemImage: "doc.richtext"
            )
            AdminDocumentArtifactRow(title: "RIDE", artifact: detail.artifacts.ride, systemImage: "doc.richtext")
            AdminDocumentArtifactRow(title: "XML autorizado", artifact: detail.artifacts.authorizedXml, systemImage: "checkmark.seal")
            AdminDocumentArtifactRow(title: "XML firmado", artifact: detail.artifacts.signedXml, systemImage: "signature")
        }
    }

    private var emailSection: some View {
        NexoAdminUXCard {
            NexoAdminUXSectionHeader(
                "Email al cliente",
                subtitle: "Seguimiento de entrega y reenvío controlado.",
                systemImage: "envelope"
            )
            VStack(spacing: 9) {
                NexoAdminUXPlainRow(title: "Estado", value: detail.email.statusTitle, systemImage: "circle.fill")
                NexoAdminUXPlainRow(title: "Destinatario", value: detail.email.recipient ?? "—", systemImage: "person.crop.circle")
                NexoAdminUXPlainRow(title: "Enviado", value: detail.email.sentAt ?? "—", systemImage: "calendar")
                NexoAdminUXPlainRow(title: "Intentos", value: "\(detail.email.attempts)", systemImage: "arrow.clockwise")
            }
            if let error = detail.email.lastError {
                NexoAdminUXInlineMessage(title: "Último error de email", message: error, tone: .warning)
            }
        }
    }

    private var totalsSection: some View {
        NexoAdminUXCard {
            NexoAdminUXSectionHeader("Totales", subtitle: "Valores tributarios del comprobante.", systemImage: "sum")
            VStack(spacing: 9) {
                NexoAdminUXPlainRow(title: "Subtotal gravado", value: MoneyFormatter.format(detail.totals.subtotalTaxed, currency: detail.totals.currency))
                NexoAdminUXPlainRow(title: "Subtotal 0%", value: MoneyFormatter.format(detail.totals.subtotalZeroRate, currency: detail.totals.currency))
                NexoAdminUXPlainRow(title: "Subtotal exento", value: MoneyFormatter.format(detail.totals.subtotalExempt, currency: detail.totals.currency))
                NexoAdminUXPlainRow(title: "Descuento", value: MoneyFormatter.format(detail.totals.discountTotal, currency: detail.totals.currency))
                NexoAdminUXPlainRow(title: "IVA", value: MoneyFormatter.format(detail.totals.taxTotal, currency: detail.totals.currency))
                Divider()
                NexoAdminUXPlainRow(title: "Total", value: MoneyFormatter.format(detail.totals.grandTotal, currency: detail.totals.currency))
            }
        }
    }

    private var linesSection: some View {
        NexoAdminUXCard {
            NexoAdminUXSectionHeader("Líneas", subtitle: "Detalle de productos o servicios incluidos.", systemImage: "list.bullet")
            if detail.lines.isEmpty {
                NexoAdminUXInlineMessage(title: "Sin líneas", message: "El detalle no incluye líneas cargadas.", tone: .info)
            } else {
                ForEach(detail.lines) { line in
                    VStack(alignment: .leading, spacing: 5) {
                        HStack(alignment: .firstTextBaseline) {
                            Text(line.description)
                                .font(.subheadline.weight(.semibold))
                            Spacer(minLength: 8)
                            Text(MoneyFormatter.format(line.subtotal, currency: detail.totals.currency))
                                .font(.subheadline.weight(.bold))
                                .monospacedDigit()
                        }
                        Text("Cant. \(line.quantityText) · PU \(MoneyFormatter.format(line.unitPrice, currency: detail.totals.currency)) · IVA \(MoneyFormatter.format(line.taxValue, currency: detail.totals.currency))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                    if line.id != detail.lines.last?.id { Divider() }
                }
            }
        }
    }

    private var timelineSection: some View {
        NexoAdminUXCard {
            NexoAdminUXSectionHeader(
                "Timeline",
                subtitle: "Historia del comprobante para soporte y auditoría.",
                systemImage: "clock.arrow.circlepath"
            )

            if detail.timeline.isEmpty {
                NexoAdminUXInlineMessage(title: "Sin eventos", message: "No hay eventos cargados para este comprobante.", tone: .info)
            } else {
                ForEach(detail.timeline) { event in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: timelineIcon(event.severity))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(timelineTint(event.severity))
                            .frame(width: 24, height: 24)

                        VStack(alignment: .leading, spacing: 3) {
                            Text(event.safeTitle)
                                .font(.subheadline.weight(.semibold))
                            Text(event.safeMessage)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                            Text(event.createdAt)
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .padding(.vertical, 4)
                    if event.id != detail.timeline.last?.id { Divider() }
                }
            }

            Button {
                Task { await viewModel.refreshSelectedTimeline() }
            } label: {
                if viewModel.isLoadingAction(.viewTimeline) {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else {
                    Label("Actualizar timeline", systemImage: "clock.arrow.circlepath")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.bordered)
            .disabled(!viewModel.canPerform(.viewTimeline, on: detail) || viewModel.isPerformingAction)
        }
    }

    private func actionIcon(_ action: AdminElectronicDocumentAction) -> String {
        switch action {
        case .downloadRide: return "doc.richtext"
        case .downloadXml: return "chevron.left.forwardslash.chevron.right"
        case .resendEmail: return "paperplane"
        case .retryReception: return "arrow.up.doc"
        case .retryAuthorization: return "arrow.triangle.2.circlepath"
        case .regenerateRide: return "doc.badge.gearshape"
        case .viewDetail: return "doc.text.magnifyingglass"
        case .viewTimeline: return "clock.arrow.circlepath"
        case .unknown: return "questionmark.circle"
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
        case .downloadRide: return onShareRide
        case .downloadXml: return onShareXml
        case .resendEmail: return onEmail
        case .retryReception: return onRetryReception
        case .retryAuthorization: return onRetryAuthorization
        case .regenerateRide: return onRegenerateRide
        default: return {}
        }
    }

    private func timelineIcon(_ severity: AdminSriErrorSeverity) -> String {
        switch severity {
        case .info: return "circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .error: return "xmark.octagon.fill"
        case .critical: return "flame.fill"
        }
    }

    private func timelineTint(_ severity: AdminSriErrorSeverity) -> Color {
        switch severity {
        case .info: return .blue
        case .warning: return .orange
        case .error: return .red
        case .critical: return .red
        }
    }
}

private struct AdminElectronicDocumentFiltersView: View {
    @ObservedObject var viewModel: AdminElectronicDocumentsViewModel
    let onDebouncedSearch: () -> Void
    let onImmediateSearch: () -> Void
    let onClearFilters: () -> Void

    @State private var showsAdvancedFilters = false

    init(
        viewModel: AdminElectronicDocumentsViewModel,
        onDebouncedSearch: @escaping () -> Void = {},
        onImmediateSearch: @escaping () -> Void = {},
        onClearFilters: @escaping () -> Void = {}
    ) {
        self.viewModel = viewModel
        self.onDebouncedSearch = onDebouncedSearch
        self.onImmediateSearch = onImmediateSearch
        self.onClearFilters = onClearFilters
    }

    var body: some View {
        Section {
            VStack(alignment: .leading, spacing: 14) {
                filterHeader
                searchField
                documentStatusFilter
                sriStatusFilter
                advancedFilters
            }
            .padding(.vertical, 4)
        } footer: {
            Text(filterFooterText)
        }
        .onChange(of: viewModel.filter.query) { _, _ in onDebouncedSearch() }
        .onChange(of: viewModel.filter.customer) { _, _ in onDebouncedSearch() }
        .onChange(of: viewModel.filter.number) { _, _ in onDebouncedSearch() }
        .onChange(of: viewModel.filter.documentType) { _, _ in onDebouncedSearch() }
        .onChange(of: viewModel.filter.status) { _, _ in onImmediateSearch() }
        .onChange(of: viewModel.filter.sriStatus) { _, _ in onImmediateSearch() }
        .onChange(of: viewModel.filter.fromDate) { _, _ in onImmediateSearch() }
        .onChange(of: viewModel.filter.toDate) { _, _ in onImmediateSearch() }
    }

    private var filterHeader: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Buscar comprobantes")
                    .font(.headline)
                Text("Factura, cliente, clave, autorización o monto")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
            if viewModel.filter.hasActiveFilters {
                Button {
                    onClearFilters()
                } label: {
                    Label("Limpiar", systemImage: "xmark.circle")
                        .font(.caption.weight(.semibold))
                }
                .buttonStyle(.borderless)
                .foregroundStyle(.secondary)
            }
        }
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            TextField("Buscar", text: $viewModel.filter.query)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.search)
                .onSubmit { onImmediateSearch() }

            if hasQueryText {
                Button {
                    viewModel.filter.query = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Limpiar texto de búsqueda")
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 11)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var documentStatusFilter: some View {
        FilterChipRow(title: "Documento") {
            ForEach(AdminElectronicDocumentStatusFilter.allCases) { status in
                filterChip(
                    title: status.title,
                    isSelected: viewModel.filter.status == status,
                    action: { viewModel.filter.status = status }
                )
            }
        }
    }

    private var sriStatusFilter: some View {
        FilterChipRow(title: "SRI") {
            ForEach(AdminSriStatusFilter.allCases) { status in
                filterChip(
                    title: status.title,
                    isSelected: viewModel.filter.sriStatus == status,
                    action: { viewModel.filter.sriStatus = status }
                )
            }
        }
    }

    private var advancedFilters: some View {
        DisclosureGroup(isExpanded: $showsAdvancedFilters) {
            VStack(alignment: .leading, spacing: 12) {
                TextField("Cliente específico", text: $viewModel.filter.customer)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .submitLabel(.search)
                    .onSubmit { onImmediateSearch() }

                TextField("Número específico", text: $viewModel.filter.number)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.search)
                    .onSubmit { onImmediateSearch() }

                TextField("Tipo de comprobante", text: $viewModel.filter.documentType)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.search)
                    .onSubmit { onImmediateSearch() }

                Divider()
                dateRangeFilter
            }
            .padding(.top, 8)
        } label: {
            HStack {
                Label("Más filtros", systemImage: "slider.horizontal.3")
                Spacer()
                if viewModel.filter.hasActiveFilters {
                    Text(activeFiltersText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
    }

    private var dateRangeFilter: some View {
        VStack(alignment: .leading, spacing: 10) {
            Toggle(isOn: fromDateEnabled) {
                Label("Desde", systemImage: "calendar")
            }

            if viewModel.filter.fromDate != nil {
                DatePicker(
                    "Fecha inicial",
                    selection: Binding(
                        get: { viewModel.filter.fromDate ?? Date() },
                        set: { viewModel.filter.fromDate = $0 }
                    ),
                    displayedComponents: .date
                )
                .datePickerStyle(.compact)
            }

            Toggle(isOn: toDateEnabled) {
                Label("Hasta", systemImage: "calendar.badge.clock")
            }

            if viewModel.filter.toDate != nil {
                DatePicker(
                    "Fecha final",
                    selection: Binding(
                        get: { viewModel.filter.toDate ?? Date() },
                        set: { viewModel.filter.toDate = $0 }
                    ),
                    displayedComponents: .date
                )
                .datePickerStyle(.compact)
            }
        }
    }

    private var fromDateEnabled: Binding<Bool> {
        Binding(
            get: { viewModel.filter.fromDate != nil },
            set: { isEnabled in
                viewModel.filter.fromDate = isEnabled ? (viewModel.filter.fromDate ?? Date()) : nil
            }
        )
    }

    private var toDateEnabled: Binding<Bool> {
        Binding(
            get: { viewModel.filter.toDate != nil },
            set: { isEnabled in
                viewModel.filter.toDate = isEnabled ? (viewModel.filter.toDate ?? Date()) : nil
            }
        )
    }

    private func filterChip(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.footnote.weight(isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? .primary : .secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(
                    Capsule(style: .continuous)
                        .fill(isSelected ? Color.accentColor.opacity(0.12) : Color(.secondarySystemGroupedBackground))
                )
                .overlay(
                    Capsule(style: .continuous)
                        .strokeBorder(isSelected ? Color.accentColor.opacity(0.45) : Color.secondary.opacity(0.12), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var hasQueryText: Bool {
        !viewModel.filter.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var filterFooterText: String {
        if viewModel.filter.hasActiveFilters {
            return "Filtros automáticos. No hace falta botón Buscar; solo escribe, toca estado o limpia."
        }
        return "Sin filtros activos. Se muestra el listado reciente y el detalle se abre bajo demanda."
    }

    private var activeFiltersText: String {
        var parts: [String] = []
        appendIfNeeded("Texto", value: viewModel.filter.query, to: &parts)
        appendIfNeeded("Cliente", value: viewModel.filter.customer, to: &parts)
        appendIfNeeded("Número", value: viewModel.filter.number, to: &parts)
        appendIfNeeded("Tipo", value: viewModel.filter.documentType, to: &parts)

        if isSpecificFilterTitle(viewModel.filter.status.title) { parts.append(viewModel.filter.status.title) }
        if isSpecificFilterTitle(viewModel.filter.sriStatus.title) { parts.append(viewModel.filter.sriStatus.title) }
        if let fromDate = viewModel.filter.fromDate { parts.append("Desde \(Self.dateFormatter.string(from: fromDate))") }
        if let toDate = viewModel.filter.toDate { parts.append("Hasta \(Self.dateFormatter.string(from: toDate))") }

        return parts.isEmpty ? "Activos" : parts.joined(separator: " · ")
    }

    private func appendIfNeeded(_ title: String, value: String, to parts: inout [String]) {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        parts.append("\(title): \(trimmed)")
    }

    private func isSpecificFilterTitle(_ title: String) -> Bool {
        let normalized = title
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .lowercased()

        return !["todo", "todos", "todas", "todos los estados", "cualquier estado", "cualquiera"].contains(normalized)
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
}

private struct FilterChipRow<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) { content }
                    .padding(.vertical, 2)
            }
        }
    }
}

private struct AdminDocumentActionTile: View {
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
                        .font(.title3.weight(.semibold))
                }
                Text(title)
                    .font(.caption.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, minHeight: 78)
            .padding(.horizontal, 8)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(Color.secondary.opacity(0.08), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(!enabled || isLoading)
        .opacity(enabled ? 1 : 0.45)
    }
}

private struct AdminDocumentArtifactRow: View {
    let title: String
    let artifact: AdminDocumentArtifact?
    let systemImage: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.headline.weight(.semibold))
                .frame(width: 34, height: 34)
                .background(Color.secondary.opacity(0.10), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(artifact?.safeFileName ?? "No disponible")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 8)
            Text(artifact?.sizeText ?? "—")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 5)
    }
}

private struct AdminElectronicDocumentEmailSheet: View {
    @ObservedObject var viewModel: AdminElectronicDocumentsViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            Section {
                TextField("Correo alternativo opcional", text: $viewModel.recipientOverride)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            } header: {
                Text("Destinatario")
            } footer: {
                Text("Déjalo vacío para usar el correo registrado del cliente.")
            }

            Section("Motivo") {
                TextField("Ej. cliente solicitó reenvío", text: $viewModel.emailReason, axis: .vertical)
                    .lineLimit(3...5)
            }

            Section {
                Button {
                    Task {
                        await viewModel.resendSelectedEmail()
                        dismiss()
                    }
                } label: {
                    if viewModel.isPerformingAction {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Label("Reenviar email", systemImage: "paperplane")
                            .frame(maxWidth: .infinity)
                    }
                }
                .disabled(viewModel.isPerformingAction)
            }
        }
        .navigationTitle("Reenviar comprobante")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cerrar") { dismiss() }
            }
        }
    }
}

private struct AdminElectronicDocumentQuickLookPreview: UIViewControllerRepresentable {
    let fileURL: URL

    func makeCoordinator() -> Coordinator {
        Coordinator(fileURL: fileURL)
    }

    func makeUIViewController(context: Context) -> QLPreviewController {
        let controller = QLPreviewController()
        controller.dataSource = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: QLPreviewController, context: Context) {
        context.coordinator.fileURL = fileURL
        uiViewController.reloadData()
    }

    final class Coordinator: NSObject, QLPreviewControllerDataSource {
        var fileURL: URL

        init(fileURL: URL) {
            self.fileURL = fileURL
        }

        func numberOfPreviewItems(in controller: QLPreviewController) -> Int { 1 }

        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
            fileURL as NSURL
        }
    }
}
