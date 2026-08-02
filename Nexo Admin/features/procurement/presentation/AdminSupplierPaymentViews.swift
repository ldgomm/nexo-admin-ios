//
//  AdminSupplierPaymentViews.swift
//  Nexo Admin
//
//  Created by José Ruiz on 29/7/26.
//
//  27R.N — Supplier-payment review and permission-controlled void UI.
//

import SwiftUI

struct AdminSupplierPaymentListView: View {
    @StateObject private var viewModel: AdminSupplierPaymentViewModel

    init(viewModel: AdminSupplierPaymentViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        List {
            Section {
                NexoAdminUXInlineMessage(
                    title: "Pagos canónicos",
                    message: "Importe, aplicaciones, estados y reversos vienen del backend. Admin no registra pagos nuevos ni reconstruye saldos localmente.",
                    tone: .info
                )
            }

            filterSection
            messageSections
            resultSection
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Pagos a proveedores")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task { await viewModel.refresh() }
                } label: {
                    if viewModel.isLoading {
                        ProgressView().controlSize(.small)
                    } else {
                        Image(systemName: "arrow.clockwise")
                    }
                }
                .disabled(viewModel.isLoading)
                .accessibilityLabel("Actualizar pagos a proveedores")
            }
        }
        .task { await viewModel.loadIfNeeded() }
        .refreshable { await viewModel.refresh() }
    }

    private var filterSection: some View {
        Section("Filtros del backend") {
            TextField("Buscar por número de pago", text: $viewModel.query)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
            TextField("Sucursal (opcional)", text: $viewModel.branchId)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            TextField("Proveedor (opcional)", text: $viewModel.supplierId)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            TextField("Pagado desde (AAAA-MM-DD)", text: $viewModel.paymentFrom)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            TextField("Pagado hasta (AAAA-MM-DD)", text: $viewModel.paymentTo)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

            Picker("Estado", selection: $viewModel.statusFilter) {
                ForEach(AdminSupplierPaymentStatusFilter.allCases) { filter in
                    Text(filter.title).tag(filter)
                }
            }

            if viewModel.canViewSensitive {
                Picker("Método", selection: $viewModel.methodFilter) {
                    ForEach(AdminSupplierPaymentMethodFilter.allCases) { filter in
                        Text(filter.title).tag(filter)
                    }
                }
            } else {
                Text("Método, referencia, notas y adjuntos requieren supplier_payments.sensitive_view.")
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
                    title: "No se pudieron cargar los pagos",
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
            if !viewModel.canView {
                NexoAdminUXInlineMessage(
                    title: "Lista no autorizada",
                    message: "La lista y el detalle requieren supplier_payments.view.",
                    tone: .warning
                )
            } else if viewModel.isLoading && viewModel.supplierPayments.isEmpty {
                HStack {
                    Spacer()
                    ProgressView("Cargando pagos…")
                    Spacer()
                }
            } else if viewModel.supplierPayments.isEmpty {
                EmptyStateView(
                    systemImage: "banknote",
                    title: "Sin pagos a proveedores",
                    message: viewModel.hasActiveFilters
                        ? "No hay pagos que coincidan con los filtros enviados al backend."
                        : "Todavía no existen pagos a proveedores para supervisar."
                )
            } else {
                ForEach(viewModel.supplierPayments) { presentation in
                    NavigationLink {
                        AdminSupplierPaymentDetailView(
                            viewModel: viewModel,
                            paymentId: presentation.id
                        )
                    } label: {
                        AdminSupplierPaymentRow(presentation: presentation)
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

private struct AdminSupplierPaymentRow: View {
    let presentation: AdminSupplierPaymentPresentation

    var body: some View {
        let payment = presentation.payment
        VStack(alignment: .leading, spacing: 7) {
            HStack(alignment: .firstTextBaseline) {
                Text(payment.paymentNumber)
                    .font(.headline)
                Spacer(minLength: 8)
                NexoAdminUXStatusBadge(
                    title: payment.status.title,
                    systemImage: payment.status.systemImage,
                    tint: payment.status.tint
                )
            }

            Text(presentation.supplierTitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            HStack {
                Label(payment.paymentDate, systemImage: "calendar")
                Spacer()
                Text(payment.amount.formatted)
                    .font(.subheadline.weight(.semibold))
                    .monospacedDigit()
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct AdminSupplierPaymentDetailView: View {
    @ObservedObject var viewModel: AdminSupplierPaymentViewModel
    let paymentId: String
    @State private var showsVoidSheet = false

    var body: some View {
        Group {
            if let presentation = viewModel.paymentPresentation(id: paymentId) {
                paymentList(presentation)
            } else if viewModel.isLoadingDetail {
                ProgressView("Cargando pago…")
            } else {
                NexoAdminUXEmptyState(
                    systemImage: "banknote",
                    title: "Pago no disponible",
                    message: viewModel.detailErrorMessage ?? "Vuelve a la lista y actualiza la consulta."
                )
                .padding(20)
            }
        }
        .navigationTitle("Pago a proveedor")
        .task(id: paymentId) { await viewModel.refreshDetail(id: paymentId) }
        .sheet(isPresented: $showsVoidSheet) {
            AdminSupplierPaymentVoidSheet(
                viewModel: viewModel,
                paymentId: paymentId
            )
        }
    }

    private func paymentList(_ presentation: AdminSupplierPaymentPresentation) -> some View {
        let payment = presentation.payment
        return List {
            if let error = viewModel.detailErrorMessage {
                Section {
                    NexoAdminUXInlineMessage(
                        title: "Operación no completada",
                        message: error,
                        tone: .warning
                    )
                }
            }

            if let info = viewModel.detailInfoMessage {
                Section {
                    NexoAdminUXInlineMessage(
                        title: "Respuesta del servidor",
                        message: info,
                        tone: .info
                    )
                }
            }

            if let warning = viewModel.detailReferenceWarning {
                Section {
                    NexoAdminUXInlineMessage(
                        title: "Referencias protegidas",
                        message: warning,
                        tone: .warning
                    )
                }
            }

            Section("Pago") {
                LabeledContent("Número", value: payment.paymentNumber)
                LabeledContent("Proveedor", value: presentation.supplierTitle)
                LabeledContent("Fecha", value: payment.paymentDate)
                LabeledContent("Estado", value: payment.status.title)
                LabeledContent("Moneda", value: payment.currency)
                LabeledContent("Importe", value: payment.amount.formatted)
                LabeledContent("Aplicaciones", value: payment.allocationCountTitle)
                Text(payment.status.explanation)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            sensitiveSection(payment)
            allocationSection(payment)
            auditSection(payment)
            voidSection(payment)
        }
        .refreshable { await viewModel.refreshDetail(id: payment.id) }
    }

    @ViewBuilder
    private func sensitiveSection(_ payment: AdminSupplierPayment) -> some View {
        Section("Evidencia sensible") {
            if viewModel.canViewSensitive {
                LabeledContent("Método", value: payment.method?.title ?? "No informado")
                LabeledContent("Referencia", value: payment.reference ?? "No informada")
                LabeledContent("Notas", value: payment.notes ?? "Sin notas")
                LabeledContent("Adjuntos", value: String(payment.attachmentIds?.count ?? 0))

                if viewModel.canViewAudit {
                    if let cashMovementId = payment.cashMovementId {
                        LabeledContent("Movimiento de caja", value: cashMovementId)
                    }
                    ForEach(payment.attachmentIds ?? [], id: \.self) { attachmentId in
                        Label(attachmentId, systemImage: "paperclip")
                            .font(.caption)
                    }
                }
            } else {
                Text("Método, referencia, notas, adjuntos y vínculo de caja requieren supplier_payments.sensitive_view.")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func allocationSection(_ payment: AdminSupplierPayment) -> some View {
        Section("Aplicaciones canónicas") {
            ForEach(payment.allocations) { allocation in
                let index = payment.allocations.firstIndex(where: { $0.id == allocation.id }) ?? 0
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(viewModel.payableReferenceTitle(for: allocation, index: index))
                            .font(.subheadline.weight(.semibold))
                        Spacer(minLength: 8)
                        Text(allocation.status.title)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(allocation.status == .applied ? .green : .secondary)
                    }
                    LabeledContent("Importe aplicado", value: allocation.amount.formatted)
                    LabeledContent("Saldo anterior", value: allocation.payableBalanceBefore.formatted)
                    LabeledContent("Saldo posterior", value: allocation.payableBalanceAfter.formatted)

                    if allocation.status == .reversed {
                        LabeledContent("Revertida", value: allocation.reversedAt ?? "Servidor")
                        LabeledContent("Motivo", value: allocation.reversalReason ?? "No informado")
                    }

                    if viewModel.canViewAudit {
                        LabeledContent("Aplicación ID", value: allocation.id)
                        LabeledContent("Cuenta por pagar ID", value: allocation.payableId)
                        LabeledContent("Creada por", value: allocation.createdBy)
                        if let reversedBy = allocation.reversedBy {
                            LabeledContent("Revertida por", value: reversedBy)
                        }
                    }
                }
                .padding(.vertical, 4)
            }

            Text("Los saldos anterior y posterior llegan del backend. Admin no vuelve a aplicar ni resta importes.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private func auditSection(_ payment: AdminSupplierPayment) -> some View {
        Section("Auditoría") {
            LabeledContent("Versión", value: String(payment.version))
            LabeledContent("Creado", value: payment.createdAt)
            LabeledContent("Actualizado", value: payment.updatedAt)
            if let recordedAt = payment.recordedAt {
                LabeledContent("Registrado", value: recordedAt)
            }
            if let voidedAt = payment.voidedAt {
                LabeledContent("Anulado", value: voidedAt)
            }
            if let voidReason = payment.voidReason {
                LabeledContent("Motivo de anulación", value: voidReason)
            }

            if viewModel.canViewAudit {
                LabeledContent("Pago ID", value: payment.id)
                LabeledContent("Sucursal ID", value: payment.branchId)
                LabeledContent("Proveedor ID", value: payment.supplierId)
                LabeledContent("Creado por", value: payment.createdBy)
                LabeledContent("Actualizado por", value: payment.updatedBy)
                if let recordedBy = payment.recordedBy {
                    LabeledContent("Registrado por", value: recordedBy)
                }
                if let voidedBy = payment.voidedBy {
                    LabeledContent("Anulado por", value: voidedBy)
                }
            } else {
                Text("Actores e IDs internos requieren procurement.audit_view.")
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private func voidSection(_ payment: AdminSupplierPayment) -> some View {
        Section("Control de anulación") {
            if viewModel.canVoid(paymentId: payment.id) {
                Button(role: .destructive) {
                    showsVoidSheet = true
                } label: {
                    Label("Anular pago", systemImage: "xmark.octagon.fill")
                }
                .disabled(viewModel.isVoiding(paymentId: payment.id))

                Text("La solicitud usa la versión actual y una clave idempotente. El backend conserva el pago y revierte sus aplicaciones; no elimina historial.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else if payment.status != .recorded {
                Text("Solo un pago registrado puede anularse.")
                    .foregroundStyle(.secondary)
            } else {
                Text("La anulación requiere supplier_payments.void.")
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct AdminSupplierPaymentVoidSheet: View {
    @ObservedObject var viewModel: AdminSupplierPaymentViewModel
    let paymentId: String

    @Environment(\.dismiss) private var dismiss
    @State private var reason = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    NexoAdminUXInlineMessage(
                        title: "Reverso con evidencia",
                        message: "La anulación no borra el pago. El backend restaura las aplicaciones y registra actor, motivo, versión e idempotencia.",
                        tone: .warning
                    )
                }

                Section("Motivo obligatorio") {
                    TextField("Describe por qué se anula", text: $reason, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Anular pago")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                        .disabled(viewModel.isVoiding(paymentId: paymentId))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Anular", role: .destructive) {
                        Task {
                            if await viewModel.voidPayment(id: paymentId, reason: reason) != nil {
                                dismiss()
                            }
                        }
                    }
                    .disabled(
                        reason.trimmedOrNil == nil
                            || viewModel.isVoiding(paymentId: paymentId)
                    )
                }
            }
        }
    }
}

private extension AdminSupplierPaymentStatus {
    var tint: Color {
        switch self {
        case .processing: return .orange
        case .recorded: return .green
        case .voiding: return .orange
        case .voided: return .secondary
        }
    }
}
