//
//  AdminSupplierStatementViews.swift
//  Nexo Admin
//
//  Created by José Ruiz on 29/7/26.
//
//  27R.N — Read-only supplier statement and operational export surfaces.
//

import SwiftUI

struct AdminSupplierStatementView: View {
    @StateObject private var viewModel: AdminSupplierStatementViewModel

    init(viewModel: AdminSupplierStatementViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        Form {
            boundarySection
            supplierSection
            filterSection
            actionSection
            messageSection
            balanceSection
            exportSection
            operationalExportsSection
            movementSection
        }
        .navigationTitle("Estado de cuenta")
        .task { await viewModel.loadSuppliersIfNeeded() }
        .refreshable {
            if !viewModel.selectedSupplierId.isEmpty {
                await viewModel.refresh()
            }
        }
    }

    private var boundarySection: some View {
        Section {
            Label(
                "Saldos, movimientos y CSV provienen del backend. Admin no reconstruye el estado de cuenta ni genera contabilidad oficial.",
                systemImage: "checkmark.shield.fill"
            )
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var supplierSection: some View {
        Section("Proveedor") {
            if viewModel.canBrowseSuppliers {
                HStack {
                    TextField("Buscar proveedor", text: $viewModel.supplierSearch)
                        .textInputAutocapitalization(.never)
                    Button {
                        Task { await viewModel.searchSuppliers() }
                    } label: {
                        if viewModel.isLoadingSuppliers {
                            ProgressView()
                        } else {
                            Image(systemName: "magnifyingglass")
                        }
                    }
                    .disabled(viewModel.isLoadingSuppliers)
                }

                Picker("Proveedor", selection: $viewModel.selectedSupplierId) {
                    Text("Selecciona un proveedor").tag("")
                    ForEach(viewModel.suppliers) { supplier in
                        Text(supplier.displayName).tag(supplier.id)
                    }
                }
            } else {
                TextField("ID técnico del proveedor", text: $viewModel.selectedSupplierId)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                Text("Falta suppliers.view para mostrar el selector de proveedores; la consulta sigue protegida por supplier_statements.view.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if !viewModel.selectedSupplierId.isEmpty {
                LabeledContent("Selección", value: viewModel.selectedSupplierName)
            }
        }
    }

    private var filterSection: some View {
        Section("Filtros") {
            TextField("Sucursal opcional", text: $viewModel.branchId)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            TextField("Moneda", text: $viewModel.currency)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
            TextField("Desde · AAAA-MM-DD", text: $viewModel.from)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            TextField("Hasta · AAAA-MM-DD", text: $viewModel.to)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            TextField("Corte · AAAA-MM-DD", text: $viewModel.asOf)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            Button("Limpiar filtros") { viewModel.clearFilters() }
        }
    }

    private var actionSection: some View {
        Section {
            Button {
                Task { await viewModel.refresh() }
            } label: {
                HStack {
                    if viewModel.isLoading { ProgressView() }
                    Label("Consultar estado de cuenta", systemImage: "doc.text.magnifyingglass")
                }
                .frame(maxWidth: .infinity)
            }
            .disabled(viewModel.isLoading || !viewModel.canView)
        }
    }

    @ViewBuilder
    private var messageSection: some View {
        if let error = viewModel.errorMessage {
            Section {
                Label(error, systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
            }
        }
        if let info = viewModel.infoMessage {
            Section {
                Label(info, systemImage: "info.circle.fill")
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private var balanceSection: some View {
        if let opening = viewModel.openingBalance,
           let closing = viewModel.closingBalance {
            Section("Saldos canónicos") {
                AdminSupplierStatementMoneyRow(title: "Saldo inicial", money: opening)
                AdminSupplierStatementMoneyRow(title: "Saldo final", money: closing, emphasized: true)
                if let value = viewModel.statementCurrency {
                    LabeledContent("Moneda", value: value)
                }
                if let value = viewModel.statementFrom {
                    LabeledContent("Desde", value: value)
                }
                if let value = viewModel.statementTo {
                    LabeledContent("Hasta", value: value)
                }
                if let value = viewModel.statementAsOf {
                    LabeledContent("Fecha de corte", value: value)
                }
                Text("El saldo final es el valor autoritativo devuelto por el servidor; no se calcula con las filas visibles.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private var exportSection: some View {
        if viewModel.canExport {
            Section("Exportación") {
                Button {
                    Task { await viewModel.exportCSV() }
                } label: {
                    HStack {
                        if viewModel.isExporting { ProgressView() }
                        Label("Generar CSV", systemImage: "square.and.arrow.down")
                    }
                }
                .disabled(viewModel.isExporting || viewModel.selectedSupplierId.isEmpty)

                if let file = viewModel.downloadedFile {
                    LabeledContent("Filas", value: String(file.rowCount))
                    ShareLink(item: file.localURL) {
                        Label("Compartir \(file.fileName)", systemImage: "square.and.arrow.up.fill")
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var operationalExportsSection: some View {
        if viewModel.canViewOperationalExports {
            Section("Más exportaciones") {
                NavigationLink {
                    AdminProcurementExportsView(
                        viewModel: viewModel.operationalExportsViewModel
                    )
                } label: {
                    Label("Reportes operativos reconciliados", systemImage: "tray.full.fill")
                }
            }
        }
    }

    private var movementSection: some View {
        Section("Movimientos") {
            if viewModel.isLoading && viewModel.lines.isEmpty {
                ProgressView("Cargando estado de cuenta…")
            } else if viewModel.lines.isEmpty {
                ContentUnavailableView(
                    "Sin movimientos",
                    systemImage: "doc.text.magnifyingglass",
                    description: Text("Selecciona un proveedor y consulta el periodo requerido.")
                )
            } else {
                ForEach(viewModel.lines) { line in
                    AdminSupplierStatementLineRow(
                        line: line,
                        showsAudit: viewModel.canViewAudit
                    )
                        .onAppear {
                            Task { await viewModel.loadNextPageIfNeeded(currentLine: line) }
                        }
                }
                if viewModel.isLoadingMore {
                    ProgressView("Cargando más movimientos…")
                }
            }
        }
    }
}

struct AdminProcurementExportsView: View {
    @StateObject private var viewModel: AdminProcurementExportsViewModel

    init(viewModel: AdminProcurementExportsViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        Form {
            Section {
                Label(
                    "Cada archivo lo genera el backend desde hechos operativos reconciliados. No es un libro contable oficial.",
                    systemImage: "tray.full.fill"
                )
                .font(.footnote)
                .foregroundStyle(.secondary)
            }

            filtersSection
            messagesSection
            reportsSection
            downloadedFileSection
        }
        .navigationTitle("Exportaciones")
        .task { await viewModel.loadIfNeeded() }
        .refreshable { await viewModel.refreshCatalog() }
    }

    private var filtersSection: some View {
        Section("Filtros comunes") {
            TextField("Sucursal opcional", text: $viewModel.branchId)
            TextField("Proveedor opcional", text: $viewModel.supplierId)
            TextField("Categoría opcional", text: $viewModel.category)
            TextField("Producto opcional", text: $viewModel.catalogItemId)
            TextField("Método de pago opcional", text: $viewModel.paymentMethod)
            TextField("Tipo de evidencia opcional", text: $viewModel.attachmentSourceType)
            TextField("Moneda", text: $viewModel.currency)
                .textInputAutocapitalization(.characters)
            TextField("Desde · AAAA-MM-DD", text: $viewModel.from)
            TextField("Hasta · AAAA-MM-DD", text: $viewModel.to)
            TextField("Corte · AAAA-MM-DD", text: $viewModel.asOf)
            Button("Limpiar filtros") { viewModel.clearFilters() }
        }
        .textInputAutocapitalization(.never)
        .autocorrectionDisabled()
    }

    @ViewBuilder
    private var messagesSection: some View {
        if let error = viewModel.errorMessage {
            Section {
                Label(error, systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
            }
        }
        if let info = viewModel.infoMessage {
            Section {
                Label(info, systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var reportsSection: some View {
        Section("Reportes operativos") {
            if viewModel.isLoading && viewModel.reports.isEmpty {
                ProgressView("Cargando catálogo backend…")
            } else if viewModel.reports.isEmpty {
                ContentUnavailableView(
                    "Sin reportes",
                    systemImage: "tray",
                    description: Text("El catálogo operativo no está disponible para este usuario.")
                )
            } else {
                ForEach(viewModel.reports) { report in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(report.title)
                            .font(.headline)
                        Text(report.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Button {
                            Task { await viewModel.export(report) }
                        } label: {
                            HStack {
                                if viewModel.exportingReportType == report.reportType {
                                    ProgressView()
                                }
                                Label("Exportar CSV", systemImage: "square.and.arrow.down")
                            }
                        }
                        .disabled(!viewModel.canExport || viewModel.exportingReportType != nil)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }

    @ViewBuilder
    private var downloadedFileSection: some View {
        if let file = viewModel.downloadedFile {
            Section("Archivo listo") {
                LabeledContent("Tipo", value: file.exportType)
                LabeledContent("Versión", value: file.exportVersion)
                LabeledContent("Filas", value: String(file.rowCount))
                ShareLink(item: file.localURL) {
                    Label("Compartir \(file.fileName)", systemImage: "square.and.arrow.up.fill")
                }
            }
        }
    }
}

private struct AdminSupplierStatementLineRow: View {
    let line: AdminSupplierStatementLine
    let showsAudit: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Label(line.sourceType.title, systemImage: line.sourceType.systemImage)
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text(line.occurredDate)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            Text(line.description)
                .font(.body)
            AdminSupplierStatementMoneyRow(title: "Cargo", money: line.charge)
            AdminSupplierStatementMoneyRow(title: "Abono", money: line.credit)
            AdminSupplierStatementMoneyRow(
                title: "Saldo corriente",
                money: line.runningBalance,
                emphasized: true
            )
            if showsAudit {
                VStack(alignment: .leading, spacing: 3) {
                    Label(line.auditTitle, systemImage: "link.badge.plus")
                    Text("\(line.auditResourceType) · \(line.auditResourceId)")
                        .textSelection(.enabled)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct AdminSupplierStatementMoneyRow: View {
    let title: String
    let money: AdminProcurementMoney
    var emphasized = false

    var body: some View {
        LabeledContent(title) {
            Text(money.formatted)
                .fontWeight(emphasized ? .semibold : .regular)
                .monospacedDigit()
        }
    }
}
