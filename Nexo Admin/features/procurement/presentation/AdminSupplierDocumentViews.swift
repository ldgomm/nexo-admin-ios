//
//  AdminSupplierDocumentViews.swift
//  Nexo Admin
//
//  Created by José Ruiz on 29/7/26.
//
//  27R.N — Read-only supplier document register, filters and detail.
//

import SwiftUI

struct AdminSupplierDocumentListView: View {
    @StateObject private var viewModel: AdminSupplierDocumentViewModel

    init(viewModel: AdminSupplierDocumentViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        List {
            Section {
                NexoAdminUXInlineMessage(
                    title: "Registro operativo",
                    message: "Los importes, impuestos, vínculos y estados vienen del backend. Admin no confirma, cancela ni recalcula documentos de proveedor.",
                    tone: .info
                )
            }

            filterSection
            feedbackSection
            resultSection
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Documentos de proveedor")
        .searchable(text: $viewModel.query, prompt: "Número de documento")
        .onSubmit(of: .search) { Task { await viewModel.refresh() } }
        .task { await viewModel.loadIfNeeded() }
        .refreshable { await viewModel.refresh() }
    }

    private var filterSection: some View {
        Section("Filtros del backend") {
            Picker("Tipo", selection: $viewModel.documentTypeFilter) {
                ForEach(AdminSupplierDocumentTypeFilter.allCases) { filter in
                    Text(filter.title).tag(filter)
                }
            }
            .onChange(of: viewModel.documentTypeFilter) { _, _ in
                Task { await viewModel.refresh() }
            }

            Picker("Estado", selection: $viewModel.statusFilter) {
                ForEach(AdminSupplierDocumentStatusFilter.allCases) { filter in
                    Text(filter.title).tag(filter)
                }
            }
            .onChange(of: viewModel.statusFilter) { _, _ in
                Task { await viewModel.refresh() }
            }

            TextField("Sucursal (opcional)", text: $viewModel.branchId)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            TextField("Proveedor (opcional)", text: $viewModel.supplierId)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            TextField("Documento desde (AAAA-MM-DD)", text: $viewModel.documentDateFrom)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            TextField("Documento hasta (AAAA-MM-DD)", text: $viewModel.documentDateTo)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            TextField("Vencimiento desde (AAAA-MM-DD)", text: $viewModel.dueDateFrom)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            TextField("Vencimiento hasta (AAAA-MM-DD)", text: $viewModel.dueDateTo)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

            Button("Aplicar filtros") { Task { await viewModel.refresh() } }
            if viewModel.hasActiveFilters {
                Button("Limpiar filtros") { Task { await viewModel.clearFilters() } }
            }
        }
    }

    @ViewBuilder
    private var feedbackSection: some View {
        if let error = viewModel.errorMessage {
            Section {
                NexoAdminUXInlineMessage(
                    title: "No se pudieron cargar los documentos",
                    message: error,
                    tone: .danger
                )
            }
        }
    }

    @ViewBuilder
    private var resultSection: some View {
        Section("Resultados") {
            if viewModel.isLoading && viewModel.supplierDocuments.isEmpty {
                HStack {
                    Spacer()
                    ProgressView("Cargando documentos…")
                    Spacer()
                }
            } else if viewModel.supplierDocuments.isEmpty {
                EmptyStateView(
                    systemImage: "doc.text.magnifyingglass",
                    title: "Sin documentos de proveedor",
                    message: viewModel.hasActiveFilters
                        ? "No hay documentos que coincidan con los filtros enviados al backend."
                        : "Todavía no existen documentos de proveedor para supervisar."
                )
            } else {
                ForEach(viewModel.supplierDocuments) { document in
                    NavigationLink {
                        AdminSupplierDocumentDetailView(
                            viewModel: viewModel,
                            documentId: document.id
                        )
                    } label: {
                        AdminSupplierDocumentRow(document: document)
                    }
                    .task { await viewModel.loadMoreIfNeeded(current: document) }
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

private struct AdminSupplierDocumentRow: View {
    let document: AdminSupplierDocument

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(alignment: .firstTextBaseline) {
                Label(document.documentNumber, systemImage: document.documentType.systemImage)
                    .font(.headline)
                Spacer(minLength: 8)
                NexoAdminUXStatusBadge(
                    title: document.status.title,
                    systemImage: document.status.systemImage,
                    tint: document.status.tint
                )
            }

            Text(document.documentType.title)
                .font(.subheadline)

            HStack(spacing: 12) {
                Label(document.documentDate, systemImage: "calendar")
                Label(document.dueDate ?? "Sin vencimiento", systemImage: "calendar.badge.clock")
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            HStack {
                Text(document.total.formatted)
                    .font(.caption.weight(.semibold))
                Spacer()
                Text("Por pagar: \(document.payableAmount.formatted)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct AdminSupplierDocumentDetailView: View {
    @ObservedObject var viewModel: AdminSupplierDocumentViewModel
    let documentId: String

    var body: some View {
        Group {
            if let document = viewModel.supplierDocument(id: documentId) {
                documentList(document)
            } else if viewModel.isLoadingDetail {
                ProgressView("Cargando documento…")
            } else {
                NexoAdminUXEmptyState(
                    systemImage: "doc.text.magnifyingglass",
                    title: "Documento no disponible",
                    message: viewModel.detailErrorMessage ?? "Vuelve a la lista y actualiza la consulta."
                )
                .padding(20)
            }
        }
        .navigationTitle(viewModel.supplierDocument(id: documentId)?.documentNumber ?? "Documento")
        .task(id: documentId) { await viewModel.refreshDetail(id: documentId) }
    }

    private func documentList(_ document: AdminSupplierDocument) -> some View {
        List {
            if let error = viewModel.detailErrorMessage {
                Section {
                    NexoAdminUXInlineMessage(
                        title: "Detalle no actualizado",
                        message: error,
                        tone: .warning
                    )
                }
            }

            Section("Identidad y estado") {
                LabeledContent("Documento", value: document.documentNumber)
                LabeledContent("Tipo", value: document.documentType.title)
                LabeledContent("Estado", value: document.status.title)
                LabeledContent("Proveedor", value: document.supplierId)
                LabeledContent("Sucursal", value: document.branchId)
                LabeledContent("Fecha", value: document.documentDate)
                optionalContent("Vencimiento", document.dueDate)
                LabeledContent("Moneda", value: document.currency)
                LabeledContent("Versión", value: String(document.version))
            }

            Section("Totales canónicos del backend") {
                moneyContent("Subtotal", document.subtotal)
                moneyContent("Descuento", document.discountTotal)
                moneyContent("Impuestos", document.taxTotal)
                moneyContent("Total", document.total)
                moneyContent("Monto por pagar", document.payableAmount)
                optionalContent("Cuenta por pagar vinculada", document.payableId)
            }

            if let sourceTotals = document.sourceTotals {
                Section("Totales informados por la fuente") {
                    moneyContent("Total fuente", sourceTotals.total)
                    moneyContent("Impuestos fuente", sourceTotals.taxTotal)
                }
            }

            if let sourcePayment = document.sourcePayment {
                Section("Pago informado en origen") {
                    moneyContent("Monto", sourcePayment.amount)
                    LabeledContent("Método", value: sourcePayment.method)
                    LabeledContent("Fecha", value: sourcePayment.paymentDate)
                    optionalContent("Referencia", sourcePayment.reference)
                }
            }

            Section("Líneas") {
                ForEach(document.lines) { line in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(line.descriptionSnapshot)
                                .font(.headline)
                            Spacer(minLength: 8)
                            Text(line.kind.title)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Text("Cantidad: \(line.quantity.formatted) \(line.quantity.unitCode)")
                            .font(.subheadline)

                        HStack(spacing: 12) {
                            Text("Unitario: \(line.unitCost.formatted)")
                            Text("Total: \(line.lineTotal.formatted)")
                        }
                        .font(.caption.weight(.semibold))

                        Text(
                            "Neto: \(line.netAmount.formatted) · Impuesto: \(line.taxAmount.formatted) · Descuento: \(line.discountAmount.formatted)"
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)

                        if !line.taxes.isEmpty {
                            ForEach(Array(line.taxes.enumerated()), id: \.offset) { _, tax in
                                Text(
                                    "\(tax.taxCode ?? "Impuesto") \(tax.rateCode ?? ""): base \(tax.taxableBase.formatted), valor \(tax.amount.formatted)"
                                )
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            }
                        }

                        optionalLabel("Orden línea", line.purchaseOrderLineId, systemImage: "doc.text")
                        optionalLabel("Recepción línea", line.purchaseReceiptLineId, systemImage: "shippingbox")
                        optionalLabel("Categoría de gasto", line.expenseCategoryCode, systemImage: "tag")
                        optionalLabel("Notas", line.notes, systemImage: "note.text")
                    }
                    .padding(.vertical, 4)
                }
            }

            if !document.purchaseOrderIds.isEmpty || !document.purchaseReceiptIds.isEmpty {
                Section("Fuentes operativas vinculadas") {
                    ForEach(document.purchaseOrderIds, id: \.self) { id in
                        Label(id, systemImage: "doc.text")
                    }
                    ForEach(document.purchaseReceiptIds, id: \.self) { id in
                        Label(id, systemImage: "shippingbox")
                    }
                }
            }

            Section("Metadatos y evidencia") {
                optionalContent("Clave de acceso informada", document.accessKey)
                optionalContent("Autorización informada", document.authorizationNumber)
                optionalContent("Notas", document.notes)
                LabeledContent("Adjuntos vinculados", value: String(document.attachmentIds.count))
            }

            Section("Auditoría y ciclo de vida") {
                LabeledContent("Versión", value: String(document.version))
                LabeledContent("Creado", value: document.createdAt)
                LabeledContent("Actualizado", value: document.updatedAt)
                optionalContent("Confirmado", document.confirmedAt)
                optionalContent("Cancelado", document.cancelledAt)
                optionalContent("Motivo de cancelación", document.cancellationReason)

                if viewModel.canViewAudit {
                    LabeledContent("Creado por", value: document.createdBy)
                    LabeledContent("Actualizado por", value: document.updatedBy)
                    optionalContent("Confirmado por", document.confirmedBy)
                    optionalContent("Cancelado por", document.cancelledBy)
                    LabeledContent("Número normalizado", value: document.documentNumberNormalized)
                    optionalContent("CxP vinculada", document.payableId)
                } else {
                    Text("Los actores y referencias internas requieren procurement.audit_view.")
                        .foregroundStyle(.secondary)
                }
            }

            Section("Frontera contable y fiscal") {
                LabeledContent("Estado operativo", value: document.accountingStatus.title)
                NexoAdminUXInlineMessage(
                    title: "Sin afirmación oficial",
                    message: "Este registro conserva evidencia operativa. No valida SRI, deducibilidad ni clasificación contable oficial.",
                    tone: .info
                )
            }

            Section {
                NexoAdminUXInlineMessage(
                    title: "Solo lectura desde Admin",
                    message: "Crear, editar, confirmar o cancelar permanece en Business y bajo autorización del backend.",
                    tone: .info
                )
            }
        }
        .refreshable { await viewModel.refreshDetail(id: document.id) }
    }

    private func moneyContent(_ label: String, _ value: AdminProcurementMoney) -> some View {
        LabeledContent(label, value: value.formatted)
    }

    @ViewBuilder
    private func optionalContent(_ label: String, _ value: String?) -> some View {
        if let value = value?.trimmedOrNil {
            LabeledContent(label, value: value)
        }
    }

    @ViewBuilder
    private func optionalLabel(_ label: String, _ value: String?, systemImage: String) -> some View {
        if let value = value?.trimmedOrNil {
            Label("\(label): \(value)", systemImage: systemImage)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

private extension AdminSupplierDocumentStatus {
    var tint: Color {
        switch self {
        case .draft: return .secondary
        case .confirming: return .orange
        case .confirmed: return .green
        case .cancelled: return .red
        }
    }
}
