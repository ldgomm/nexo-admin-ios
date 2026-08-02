//
//  AdminPayableViews.swift
//  Nexo Admin
//
//  Created by José Ruiz on 29/7/26.
//
//  27R.N — Read-only payable ageing, due-date filters and detail.
//

import SwiftUI

struct AdminPayableListView: View {
    @StateObject private var viewModel: AdminPayableViewModel

    init(viewModel: AdminPayableViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        List {
            Section {
                NexoAdminUXInlineMessage(
                    title: "Saldos canónicos",
                    message: "Importes, estado efectivo, vencimiento y envejecimiento vienen del backend. Admin no recalcula ni modifica cuentas por pagar.",
                    tone: .info
                )
            }

            agingSection
            filterSection
            messageSections
            resultSection
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Cuentas por pagar")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task { await viewModel.refresh() }
                } label: {
                    if viewModel.isLoading || viewModel.isLoadingAging {
                        ProgressView().controlSize(.small)
                    } else {
                        Image(systemName: "arrow.clockwise")
                    }
                }
                .disabled(viewModel.isLoading || viewModel.isLoadingAging)
                .accessibilityLabel("Actualizar cuentas por pagar")
            }
        }
        .task { await viewModel.loadIfNeeded() }
        .refreshable { await viewModel.refresh() }
    }

    @ViewBuilder
    private var agingSection: some View {
        if viewModel.canViewAging {
            Section("Envejecimiento del backend") {
                if viewModel.isLoadingAging && viewModel.aging == nil {
                    HStack {
                        Spacer()
                        ProgressView("Cargando vencimientos…")
                        Spacer()
                    }
                } else if let aging = viewModel.aging {
                    LabeledContent("Fecha de corte", value: aging.asOf)
                    LabeledContent("Moneda", value: aging.currency)
                    ForEach(aging.buckets) { bucket in
                        HStack(alignment: .firstTextBaseline) {
                            Label(bucket.code.title, systemImage: bucket.code.systemImage)
                            Spacer(minLength: 8)
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(bucket.balance.formatted)
                                    .font(.subheadline.weight(.semibold))
                                    .monospacedDigit()
                                Text("\(bucket.count) registro(s)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                } else if let error = viewModel.agingErrorMessage {
                    NexoAdminUXInlineMessage(
                        title: "Envejecimiento no disponible",
                        message: error,
                        tone: .warning
                    )
                }
            }
        }
    }

    private var filterSection: some View {
        Section("Filtros del backend") {
            TextField("Sucursal (opcional)", text: $viewModel.branchId)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            TextField("Proveedor (opcional)", text: $viewModel.supplierId)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            TextField("Moneda, por ejemplo USD", text: $viewModel.currency)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
            TextField("Fecha de corte (AAAA-MM-DD)", text: $viewModel.asOf)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

            if viewModel.canViewList {
                Picker("Estado efectivo", selection: $viewModel.statusFilter) {
                    ForEach(AdminPayableStatusFilter.allCases) { filter in
                        Text(filter.title).tag(filter)
                    }
                }
                .onChange(of: viewModel.statusFilter) { _, _ in
                    Task { await viewModel.refresh() }
                }

                TextField("Vencimiento desde (AAAA-MM-DD)", text: $viewModel.dueFrom)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                TextField("Vencimiento hasta (AAAA-MM-DD)", text: $viewModel.dueTo)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                Text("Estado y rango de vencimiento filtran la lista. Sucursal, proveedor, moneda y fecha de corte también acotan el envejecimiento.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                Text("Tu permiso permite consultar únicamente el envejecimiento por sucursal, proveedor, moneda y fecha de corte.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Button("Aplicar filtros") { Task { await viewModel.refresh() } }
            if viewModel.hasActiveFilters {
                Button("Limpiar filtros") { Task { await viewModel.clearFilters() } }
            }
        }
    }

    @ViewBuilder
    private var messageSections: some View {
        if let error = viewModel.errorMessage {
            Section {
                NexoAdminUXInlineMessage(
                    title: "No se pudieron cargar las cuentas",
                    message: error,
                    tone: .danger
                )
            }
        }

        if let warning = viewModel.referenceWarning {
            Section {
                NexoAdminUXInlineMessage(
                    title: "Referencias protegidas",
                    message: warning,
                    tone: .warning
                )
            }
        }
    }

    @ViewBuilder
    private var resultSection: some View {
        Section("Resultados") {
            if !viewModel.canViewList {
                NexoAdminUXInlineMessage(
                    title: "Lista no autorizada",
                    message: "El envejecimiento puede estar disponible, pero la lista y el detalle requieren payables.view.",
                    tone: .warning
                )
            } else if viewModel.isLoading && viewModel.payables.isEmpty {
                HStack {
                    Spacer()
                    ProgressView("Cargando cuentas…")
                    Spacer()
                }
            } else if viewModel.payables.isEmpty {
                EmptyStateView(
                    systemImage: "calendar.badge.checkmark",
                    title: "Sin cuentas por pagar",
                    message: viewModel.hasActiveFilters
                        ? "No hay cuentas que coincidan con los filtros enviados al backend."
                        : "Todavía no existen cuentas por pagar para supervisar."
                )
            } else {
                ForEach(viewModel.payables) { presentation in
                    NavigationLink {
                        AdminPayableDetailView(
                            viewModel: viewModel,
                            payableId: presentation.id
                        )
                    } label: {
                        AdminPayableRow(presentation: presentation)
                    }
                    .task { await viewModel.loadMoreIfNeeded(current: presentation) }
                }

                if viewModel.isLoadingMore {
                    HStack {
                        Spacer()
                        ProgressView("Cargando más…")
                        Spacer()
                    }
                } else if viewModel.hasMore {
                    Button("Cargar más") { Task { await viewModel.loadNextPage() } }
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }
}

private struct AdminPayableRow: View {
    let presentation: AdminPayablePresentation

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(alignment: .firstTextBaseline) {
                Text(presentation.supplierTitle)
                    .font(.headline)
                    .lineLimit(2)
                Spacer(minLength: 8)
                NexoAdminUXStatusBadge(
                    title: presentation.payable.effectiveStatus.title,
                    systemImage: presentation.payable.effectiveStatus.systemImage,
                    tint: presentation.payable.effectiveStatus.tint
                )
            }

            Text(presentation.sourceTitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            HStack {
                Label(presentation.payable.dueDate, systemImage: "calendar")
                Spacer()
                Text(presentation.payable.balance.formatted)
                    .font(.subheadline.weight(.semibold))
                    .monospacedDigit()
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct AdminPayableDetailView: View {
    @ObservedObject var viewModel: AdminPayableViewModel
    let payableId: String

    var body: some View {
        Group {
            if let presentation = viewModel.payablePresentation(id: payableId) {
                payableList(presentation)
            } else if viewModel.isLoadingDetail {
                ProgressView("Cargando cuenta…")
            } else {
                NexoAdminUXEmptyState(
                    systemImage: "calendar.badge.exclamationmark",
                    title: "Cuenta no disponible",
                    message: viewModel.detailErrorMessage ?? "Vuelve a la lista y actualiza la consulta."
                )
                .padding(20)
            }
        }
        .navigationTitle("Cuenta por pagar")
        .task(id: payableId) { await viewModel.refreshDetail(id: payableId) }
    }

    private func payableList(_ presentation: AdminPayablePresentation) -> some View {
        let payable = presentation.payable
        return List {
            if let error = viewModel.detailErrorMessage {
                Section {
                    NexoAdminUXInlineMessage(
                        title: "Detalle no actualizado",
                        message: error,
                        tone: .warning
                    )
                }
            }

            Section("Obligación") {
                LabeledContent("Proveedor", value: presentation.supplierTitle)
                LabeledContent("Fuente", value: presentation.sourceTitle)
                LabeledContent("Vencimiento", value: payable.dueDate)
                LabeledContent("Fecha de corte", value: viewModel.snapshotAsOf ?? viewModel.aging?.asOf ?? "Servidor")
                LabeledContent("Estado efectivo", value: payable.effectiveStatus.title)
                LabeledContent("Estado de liquidación", value: payable.settlementStatus.title)
                LabeledContent("Moneda", value: payable.currency)
                Text(payable.effectiveStatus.explanation)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("Importes canónicos del backend") {
                moneyContent("Importe original", payable.originalAmount)
                moneyContent("Pagado", payable.paidAmount)
                moneyContent("Saldo", payable.balance)
            }

            Section("Aplicaciones de pago") {
                LabeledContent("Conteo", value: payable.allocationCountTitle)
                Text("Admin muestra las referencias recibidas; no reaplica pagos ni reconstruye el saldo.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("Auditoría") {
                LabeledContent("Versión", value: String(payable.version))
                LabeledContent("Creado", value: payable.createdAt)
                LabeledContent("Actualizado", value: payable.updatedAt)

                if viewModel.canViewAudit {
                    LabeledContent("Cuenta", value: payable.id)
                    LabeledContent("Sucursal ID", value: payable.branchId)
                    LabeledContent("Proveedor ID", value: payable.supplierId)
                    LabeledContent("Tipo de fuente", value: payable.sourceType)
                    LabeledContent("Fuente ID", value: payable.sourceId)
                    LabeledContent("Creado por", value: payable.createdBy)
                    LabeledContent("Actualizado por", value: payable.updatedBy)
                    ForEach(payable.allocationIds, id: \.self) { id in
                        Label(id, systemImage: "arrow.left.arrow.right.circle")
                            .font(.caption)
                    }
                } else {
                    Text("Actores, IDs internos y aplicaciones requieren procurement.audit_view.")
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                NexoAdminUXInlineMessage(
                    title: "Solo lectura",
                    message: "Pagos, anulaciones y reversos pertenecen a superficies posteriores y permisos específicos. Esta vista no cambia el saldo.",
                    tone: .info
                )
            }
        }
        .refreshable { await viewModel.refreshDetail(id: payable.id) }
    }

    private func moneyContent(_ label: String, _ value: AdminProcurementMoney) -> some View {
        LabeledContent(label, value: value.formatted)
    }
}

private extension AdminPayableEffectiveStatus {
    var tint: Color {
        switch self {
        case .open: return .blue
        case .partiallyPaid: return .orange
        case .paid: return .green
        case .overdue: return .red
        case .cancelled: return .secondary
        }
    }
}
