//
//  AdminOperationsView.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import SwiftUI

struct AdminOperationsView: View {
    @StateObject var viewModel: AdminOperationsViewModel
    @State private var selectedCashSession: AdminCashSession?
    @State private var selectedAuditLog: AdminAuditLogRecord?

    var body: some View {
        NavigationStack {
            Group {
                if !viewModel.hasAnyAccess {
                    ContentUnavailableView(
                        "Sin permisos",
                        systemImage: "lock.shield",
                        description: Text("Necesitas permisos de caja, reportes o auditoría para revisar esta sección.")
                    )
                } else {
                    content
                }
            }
            .navigationTitle("Caja y auditoría")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { Task { await viewModel.refresh() } } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(viewModel.isLoading)
                }
            }
            .task { await viewModel.loadInitial() }
            .refreshable { await viewModel.refresh() }
            .sheet(item: $selectedCashSession) { session in
                NavigationStack { CashSessionDetailView(session: session) }
            }
            .sheet(item: $selectedAuditLog) { log in
                NavigationStack { AuditLogDetailView(log: log) }
            }
        }
    }

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Picker("Sección", selection: $viewModel.selectedSection) {
                    ForEach(AdminOperationsViewModel.Section.allCases) { section in
                        Text(section.title).tag(section)
                    }
                }
                .pickerStyle(.segmented)

                rangeSelector

                if let error = viewModel.errorMessage {
                    ErrorStateView(title: "No se pudo cargar", message: error, retry: { Task { await viewModel.refresh() } })
                }

                if viewModel.isLoading && viewModel.todayReport == nil && viewModel.cashSessions.isEmpty && viewModel.auditLogs.isEmpty {
                    ProgressView("Cargando operación…")
                        .frame(maxWidth: .infinity)
                        .padding(40)
                } else {
                    switch viewModel.selectedSection {
                    case .snapshot:
                        operationalSnapshotContent
                    case .overview:
                        overviewContent
                    case .cash:
                        cashContent
                    case .reports:
                        reportsContent
                    case .audit:
                        auditContent
                    }
                }
            }
            .padding(18)
        }
    }

    private var rangeSelector: some View {
        HCard {
            Text("Rango")
                .font(.headline)
            HStack {
                Button("Hoy") { viewModel.applyTodayRange(); Task { await viewModel.refresh() } }
                    .buttonStyle(.bordered)
                Button("7 días") { viewModel.applyLastSevenDaysRange(); Task { await viewModel.refresh() } }
                    .buttonStyle(.bordered)
                Button("30 días") { viewModel.applyLastThirtyDaysRange(); Task { await viewModel.refresh() } }
                    .buttonStyle(.bordered)
            }
            .font(.subheadline.weight(.semibold))
        }
    }

    private var operationalSnapshotContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            HCard {
                Label("Readiness operativo", systemImage: "checkmark.seal.fill")
                    .font(.headline)
                Text(viewModel.readinessTitle)
                    .font(.subheadline.weight(.semibold))
                if viewModel.readinessChecks.isEmpty {
                    Text("Sin checks de readiness cargados. Revisa /api/v1/admin/support/diagnostics.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(viewModel.readinessChecks.prefix(5)) { check in
                        SnapshotCheckRow(check: check)
                    }
                }
            }

            AdminAccountantPackReadinessCard()
            
            if let current = viewModel.operationalCashSession {
                CashSessionCard(session: current) { selectedCashSession = current }
            } else {
                HCard {
                    Label("Estado de caja", systemImage: "banknote")
                        .font(.headline)
                    Text("No hay caja abierta o no se pudo cargar la caja actual.")
                        .foregroundStyle(.secondary)
                    if let cash = viewModel.todayReport?.cash {
                        LabeledContent("Cajas abiertas", value: "\(cash.openSessionCount)")
                        LabeledContent("Cajas cerradas", value: "\(cash.closedSessionCount)")
                        LabeledContent("Movimientos", value: "\(cash.movementCount)")
                    }
                }
            }

            SnapshotEventListCard(
                title: "Últimas ventas",
                subtitle: "Eventos recientes de venta desde auditoría/timeline, sin entrar como Business.",
                emptyMessage: "Sin ventas recientes en auditoría para este rango.",
                events: viewModel.recentSalesEvents
            )

            SnapshotEventListCard(
                title: "Últimos pagos",
                subtitle: "Pagos, abonos o movimientos asociados a cobro.",
                emptyMessage: "Sin pagos recientes en auditoría para este rango.",
                events: viewModel.recentPaymentEvents
            )

            SnapshotEventListCard(
                title: "Últimos documentos",
                subtitle: "Comprobantes, RIDE, XML, autorización o estados documentales.",
                emptyMessage: "Sin documentos recientes en auditoría para este rango.",
                events: viewModel.recentDocumentEvents
            )

            SnapshotEventListCard(
                title: "Errores de documentos",
                subtitle: "Rechazos, fallos o advertencias documentales/SRI.",
                emptyMessage: "Sin errores documentales recientes para este rango.",
                events: viewModel.documentErrorEvents
            )

            HCard {
                Label("Estado de inventario / alertas", systemImage: "shippingbox.fill")
                    .font(.headline)
                if viewModel.inventoryAlertEvents.isEmpty {
                    Text("Sin alertas de inventario/stock en auditoría o reporte operativo.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(viewModel.inventoryAlertEvents) { event in
                        SnapshotEventRow(event: event)
                        Divider()
                    }
                }
                if let topItems = viewModel.todayReport?.topItems, !topItems.isEmpty {
                    Divider()
                    Text("Productos con movimiento")
                        .font(.subheadline.weight(.semibold))
                    ForEach(topItems.prefix(3)) { item in
                        HStack {
                            Text(item.name)
                            Spacer()
                            Text("Cant. \(item.quantity)")
                                .foregroundStyle(.secondary)
                        }
                        .font(.caption)
                    }
                }
            }

            SnapshotEventListCard(
                title: "Últimas exportaciones",
                subtitle: "Generación/descarga de paquetes y archivos operativos.",
                emptyMessage: "Sin exportaciones recientes en auditoría para este rango.",
                events: viewModel.recentExportEvents
            )

            SnapshotEventListCard(
                title: "Auditoría básica",
                subtitle: "Últimos eventos generales para soporte.",
                emptyMessage: "Sin auditoría reciente para este rango.",
                events: viewModel.basicAuditEvents
            )
        }
    }

    private var overviewContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let report = viewModel.todayReport {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    OperationsMetricCard(title: "Ventas", value: report.sales.grandTotal.formatted, subtitle: "\(report.sales.saleCount) ventas", systemImage: "chart.line.uptrend.xyaxis")
                    OperationsMetricCard(title: "Cobrado", value: report.sales.paidTotal.formatted, subtitle: "Por cobrar \(report.sales.receivableTotal.formatted)", systemImage: "creditcard")
                    OperationsMetricCard(title: "Caja", value: report.cash.expectedOpenCashTotal.formatted, subtitle: "\(report.cash.openSessionCount) abiertas", systemImage: "banknote")
                    OperationsMetricCard(title: "IVA/Impuestos", value: report.tax.taxTotal.formatted, subtitle: "\(report.tax.authorizedDocumentCount) docs autorizados", systemImage: "doc.text")
                }

                if !report.alerts.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Alertas operativas")
                            .font(.headline)
                        ForEach(report.alerts) { alert in
                            OperationsAlertRow(alert: alert)
                        }
                    }
                }

                TopItemsCard(items: report.topItems)
            } else {
                ContentUnavailableView("Sin reporte diario", systemImage: "calendar.badge.exclamationmark")
            }
        }
    }

    private var cashContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let current = viewModel.currentCashSession {
                CashSessionCard(session: current) { selectedCashSession = current }
            } else {
                HCard {
                    Label("No hay caja abierta", systemImage: "tray")
                    Text("Cuando el negocio abra caja desde la app operativa, aparecerá aquí.")
                        .foregroundStyle(.secondary)
                }
            }

            HCard {
                Text("Historial de cierres")
                    .font(.headline)
                if viewModel.cashSessions.isEmpty {
                    Text("Sin sesiones de caja para este rango.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(viewModel.cashSessions) { session in
                        Button { selectedCashSession = session } label: {
                            CashSessionRow(session: session)
                        }
                        .buttonStyle(.plain)
                        Divider()
                    }
                }
            }
        }
    }

    private var reportsContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let sales = viewModel.salesSummary {
                HCard {
                    Text("Reporte de ventas")
                        .font(.headline)
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        OperationsMetricCard(title: "Total", value: sales.grandTotal.formatted, subtitle: "\(sales.saleCount) ventas", systemImage: "dollarsign.circle")
                        OperationsMetricCard(title: "Pendiente", value: sales.receivableTotal.formatted, subtitle: "\(sales.openSaleCount) abiertas", systemImage: "clock")
                    }
                    StatusCountsView(title: "Estado operativo", counts: sales.byOperationalStatus)
                    StatusCountsView(title: "Estado de pago", counts: sales.byPaymentStatus)
                    StatusCountsView(title: "Estado documental", counts: sales.byDocumentStatus)
                }
            }

            if let cash = viewModel.cashSummary {
                HCard {
                    Text("Reporte de caja")
                        .font(.headline)
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        OperationsMetricCard(title: "Entradas", value: cash.cashInTotal.formatted, subtitle: "Movimientos \(cash.movementCount)", systemImage: "arrow.down.circle")
                        OperationsMetricCard(title: "Salidas", value: cash.cashOutTotal.formatted, subtitle: "Neto \(cash.netCashMovement.formatted)", systemImage: "arrow.up.circle")
                    }
                    StatusCountsView(title: "Tipos de movimiento", counts: cash.byMovementType)
                }
            }
        }
    }

    private var auditContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            HCard {
                Text("Filtros de auditoría")
                    .font(.headline)
                TextField("Usuario", text: $viewModel.auditFilter.actorUserId)
                    .textFieldStyle(.roundedBorder)
                TextField("Acción", text: $viewModel.auditFilter.action)
                    .textFieldStyle(.roundedBorder)
                TextField("Módulo/surface", text: $viewModel.auditFilter.surface)
                    .textFieldStyle(.roundedBorder)
                Button("Aplicar filtros") { Task { await viewModel.refresh() } }
                    .buttonStyle(.borderedProminent)
            }

            if let diagnostics = viewModel.diagnostics {
                DiagnosticsCard(report: diagnostics)
            }

            HCard {
                Text("Auditoría general")
                    .font(.headline)
                if viewModel.auditLogs.isEmpty {
                    Text("Sin eventos para los filtros seleccionados.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(viewModel.auditLogs) { log in
                        Button { selectedAuditLog = log } label: {
                            AuditLogRow(log: log)
                        }
                        .buttonStyle(.plain)
                        Divider()
                    }
                }
            }

            HCard {
                Text("Timeline")
                    .font(.headline)
                ForEach(viewModel.timeline) { item in
                    TimelineItemRow(item: item)
                    Divider()
                }
            }
        }
    }
}

private struct OperationsMetricCard: View {
    let title: String
    let value: String
    let subtitle: String
    let systemImage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: systemImage)
                .font(.title3.weight(.semibold))
            Text(value)
                .font(.headline)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Text(title)
                .font(.subheadline.weight(.semibold))
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct OperationsAlertRow: View {
    let alert: AdminOperationalAlert

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(color)
            VStack(alignment: .leading, spacing: 4) {
                Text(alert.message)
                    .font(.subheadline.weight(.semibold))
                if let actionHint = alert.actionHint {
                    Text(actionHint)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(12)
        .background(color.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var icon: String {
        switch alert.severity.lowercased() {
        case "error", "critical": return "exclamationmark.octagon.fill"
        case "warning": return "exclamationmark.triangle.fill"
        default: return "info.circle.fill"
        }
    }

    private var color: Color {
        switch alert.severity.lowercased() {
        case "error", "critical": return .red
        case "warning": return .orange
        default: return .blue
        }
    }
}

private struct TopItemsCard: View {
    let items: [AdminTopItemReportLine]

    var body: some View {
        HCard {
            Text("Productos/servicios principales")
                .font(.headline)
            if items.isEmpty {
                Text("Sin ítems vendidos en este rango.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(items) { item in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(item.name)
                                .font(.subheadline.weight(.semibold))
                            Text("Cantidad \(item.quantity)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(item.lineTotal.formatted)
                            .font(.subheadline.weight(.semibold))
                    }
                }
            }
        }
    }
}

private struct CashSessionCard: View {
    let session: AdminCashSession
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HCard {
                HStack {
                    Label(session.displayTitle, systemImage: "banknote")
                        .font(.headline)
                    Spacer()
                    Text(session.status.uppercased())
                        .font(.caption.weight(.bold))
                        .foregroundStyle(session.isOpen ? .green : .secondary)
                }
                LabeledContent("Esperado", value: session.expectedCashAmount.formatted)
                LabeledContent("Apertura", value: session.openingBalance.formatted)
                LabeledContent("Movimientos", value: "\(session.movementCount)")
            }
        }
        .buttonStyle(.plain)
    }
}

private struct CashSessionRow: View {
    let session: AdminCashSession

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(session.displayTitle)
                    .font(.subheadline.weight(.semibold))
                Text(session.openedAt)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(session.expectedCashAmount.formatted)
                    .font(.subheadline.weight(.semibold))
                Text(session.closedAt ?? "Abierta")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .contentShape(Rectangle())
    }
}

private struct StatusCountsView: View {
    let title: String
    let counts: [AdminStatusCount]

    var body: some View {
        if !counts.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                ForEach(counts) { count in
                    HStack {
                        Text(count.status.replacingOccurrences(of: "_", with: " ").capitalized)
                        Spacer()
                        Text("\(count.count)")
                            .font(.headline)
                    }
                    .font(.caption)
                }
            }
        }
    }
}

private struct DiagnosticsCard: View {
    let report: AdminSupportDiagnosticsReport

    var body: some View {
        HCard {
            HStack {
                Label("Diagnóstico", systemImage: "stethoscope")
                    .font(.headline)
                Spacer()
                Text(report.status.uppercased())
                    .font(.caption.weight(.bold))
            }
            ForEach(report.checks.prefix(4)) { check in
                VStack(alignment: .leading, spacing: 2) {
                    Text(check.message)
                        .font(.subheadline.weight(.semibold))
                    if let hint = check.actionHint {
                        Text(hint)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}

private struct AuditLogRow: View {
    let log: AdminAuditLogRecord

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(log.title)
                    .font(.subheadline.weight(.semibold))
                Text(log.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(log.createdAt)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            Spacer()
            Text(log.severity.uppercased())
                .font(.caption2.weight(.bold))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.quaternary)
                .clipShape(Capsule())
        }
        .contentShape(Rectangle())
    }
}

private struct TimelineItemRow: View {
    let item: AdminAuditTimelineItem

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(item.title)
                .font(.subheadline.weight(.semibold))
            Text(item.description)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(item.occurredAt)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct CashSessionDetailView: View {
    let session: AdminCashSession

    var body: some View {
        List {
            Section("Resumen") {
                LabeledContent("Estado", value: session.status)
                LabeledContent("Abierta", value: session.openedAt)
                LabeledContent("Cerrada", value: session.closedAt ?? "—")
                LabeledContent("Apertura", value: session.openingBalance.formatted)
                LabeledContent("Esperado", value: session.expectedCashAmount.formatted)
                LabeledContent("Contado", value: session.countedCashAmount?.formatted ?? "—")
                LabeledContent("Diferencia", value: session.differenceAmount?.formatted ?? "—")
            }
            Section("Movimientos") {
                if session.movements.isEmpty {
                    Text("Sin movimientos.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(session.movements) { movement in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(movement.type.replacingOccurrences(of: "_", with: " ").capitalized)
                                    .font(.subheadline.weight(.semibold))
                                Spacer()
                                Text(movement.signedAmountTitle)
                                    .font(.subheadline.weight(.semibold))
                            }
                            Text(movement.occurredAt)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            if let notes = movement.notes {
                                Text(notes)
                                    .font(.caption)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(session.displayTitle)
    }
}

private struct AuditLogDetailView: View {
    let log: AdminAuditLogRecord

    var body: some View {
        List {
            Section("Evento") {
                LabeledContent("Acción", value: log.action)
                LabeledContent("Módulo", value: log.surface)
                LabeledContent("Fuente", value: log.source)
                LabeledContent("Severidad", value: log.severity)
                LabeledContent("Fecha", value: log.createdAt)
                LabeledContent("Actor", value: log.actorUserId ?? "—")
                LabeledContent("Target", value: [log.targetType, log.targetId].compactMap { $0 }.joined(separator: " / ").ifBlank("—"))
                LabeledContent("Correlación", value: log.correlationId ?? "—")
            }
            Section("Motivo y mensaje") {
                Text(log.reason ?? "Sin motivo registrado")
                Text(log.message ?? "Sin mensaje")
                    .foregroundStyle(.secondary)
            }
            AuditDictionarySection(title: "Antes", values: log.before)
            AuditDictionarySection(title: "Después", values: log.after)
            AuditDictionarySection(title: "Metadata", values: log.metadata)
        }
        .navigationTitle("Evento")
    }
}

private struct AuditDictionarySection: View {
    let title: String
    let values: [String: String?]

    var body: some View {
        Section(title) {
            if values.isEmpty {
                Text("Sin datos.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(values.keys.sorted(), id: \.self) { key in
                    LabeledContent(key, value: (values[key] ?? nil) ?? "—")
                }
            }
        }
    }
}

private extension String {
    func ifBlank(_ fallback: String) -> String {
        trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? fallback : self
    }
}

private struct SnapshotCheckRow: View {
    let check: AdminSupportDiagnosticCheck

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 3) {
                Text(check.message)
                    .font(.subheadline.weight(.semibold))
                if let hint = check.actionHint, !hint.isEmpty {
                    Text(hint)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var icon: String {
        switch check.status.lowercased() {
        case "pass", "ok", "healthy", "ready": return "checkmark.circle.fill"
        case "warn", "warning": return "exclamationmark.triangle.fill"
        case "fail", "error", "critical", "blocked": return "xmark.octagon.fill"
        default: return "info.circle.fill"
        }
    }

    private var color: Color {
        switch check.status.lowercased() {
        case "pass", "ok", "healthy", "ready": return .green
        case "warn", "warning": return .orange
        case "fail", "error", "critical", "blocked": return .red
        default: return .blue
        }
    }
}

private struct SnapshotEventListCard: View {
    let title: String
    let subtitle: String
    let emptyMessage: String
    let events: [AdminOperationalSnapshotEvent]

    var body: some View {
        HCard {
            Label(title, systemImage: events.first?.systemImage ?? "list.bullet.rectangle")
                .font(.headline)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
            if events.isEmpty {
                Text(emptyMessage)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(events) { event in
                    SnapshotEventRow(event: event)
                    Divider()
                }
            }
        }
    }
}

private struct SnapshotEventRow: View {
    let event: AdminOperationalSnapshotEvent

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: event.systemImage)
                .foregroundStyle(color)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline) {
                    Text(event.title)
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Text(event.severity.uppercased())
                        .font(.caption2.weight(.bold))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(color.opacity(0.14))
                        .clipShape(Capsule())
                }
                Text(event.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(event.occurredAt)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }

    private var color: Color {
        switch event.severity.lowercased() {
        case "error", "critical", "fail", "blocked": return .red
        case "warn", "warning": return .orange
        case "success", "ok", "pass", "info": return .blue
        default: return .secondary
        }
    }
}

private struct AdminAccountantPackReadinessCard: View {
    var body: some View {
        HCard {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "doc.zipper")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.blue)
                    .frame(width: 34, height: 34)
                    .background(.blue.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                VStack(alignment: .leading, spacing: 5) {
                    Text("Paquete contador")
                        .font(.headline)
                    Text("Readiness visible para soporte")
                        .font(.subheadline.weight(.semibold))
                    Text("Admin diagnostica disponibilidad y límites. La descarga operativa vive en Business.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Label("Endpoint esperado: /api/v1/business/finance/accountant-pack/draft.zip", systemImage: "link")
                Label("Contenido mínimo: manifest, cierres, ventas, pagos, caja, documentos, CxC y README_CONTADOR", systemImage: "doc.zipper")
                Label("No es contabilidad legal, ATS ni declaración tributaria", systemImage: "exclamationmark.shield")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .accessibilityIdentifier("admin.accountantPack.readinessCard")
    }
}
