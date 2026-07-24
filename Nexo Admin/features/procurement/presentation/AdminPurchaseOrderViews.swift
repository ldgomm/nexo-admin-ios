//
//  AdminPurchaseOrderViews.swift
//  Nexo Admin
//
//  27R.N.3 — Read-only purchase order list, filters and audit detail.
//

import SwiftUI

struct AdminPurchaseOrderListView: View {
    @StateObject private var viewModel: AdminPurchaseOrderViewModel

    init(viewModel: AdminPurchaseOrderViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        List {
            Section {
                NexoAdminUXInlineMessage(
                    title: "Supervisión administrativa",
                    message: "Esta superficie consulta órdenes canónicas del backend. Crear, editar, enviar, cancelar o cerrar corresponde al flujo operativo de Business.",
                    tone: .info
                )
            }

            filterSection
            feedbackSection
            resultSection
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Órdenes de compra")
        .searchable(text: $viewModel.query, prompt: "Número, proveedor o contenido")
        .onSubmit(of: .search) { Task { await viewModel.refresh() } }
        .task { await viewModel.loadIfNeeded() }
        .refreshable { await viewModel.refresh() }
    }

    private var filterSection: some View {
        Section("Filtros del backend") {
            Picker("Estado", selection: $viewModel.statusFilter) {
                ForEach(AdminPurchaseOrderStatusFilter.allCases) { filter in
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
            TextField("Esperada desde (AAAA-MM-DD)", text: $viewModel.expectedFrom)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            TextField("Esperada hasta (AAAA-MM-DD)", text: $viewModel.expectedTo)
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
                    title: "No se pudieron cargar las órdenes",
                    message: error,
                    tone: .danger
                )
            }
        }
    }

    @ViewBuilder
    private var resultSection: some View {
        Section("Resultados") {
            if viewModel.isLoading && viewModel.purchaseOrders.isEmpty {
                HStack {
                    Spacer()
                    ProgressView("Cargando órdenes…")
                    Spacer()
                }
            } else if viewModel.purchaseOrders.isEmpty {
                EmptyStateView(
                    systemImage: "doc.text.magnifyingglass",
                    title: "Sin órdenes de compra",
                    message: viewModel.hasActiveFilters
                        ? "No hay órdenes que coincidan con los filtros enviados al backend."
                        : "Todavía no existen órdenes de compra para supervisar."
                )
            } else {
                ForEach(viewModel.purchaseOrders) { order in
                    NavigationLink {
                        AdminPurchaseOrderDetailView(viewModel: viewModel, orderId: order.id)
                    } label: {
                        AdminPurchaseOrderRow(order: order)
                    }
                    .task { await viewModel.loadMoreIfNeeded(current: order) }
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

private struct AdminPurchaseOrderRow: View {
    let order: AdminPurchaseOrder

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(alignment: .firstTextBaseline) {
                Text(order.orderNumber)
                    .font(.headline)
                Spacer(minLength: 8)
                NexoAdminUXStatusBadge(
                    title: order.status.title,
                    systemImage: order.status.systemImage,
                    tint: order.status.tint
                )
            }

            Text(order.supplierSnapshot.displayName)
                .font(.subheadline)

            HStack(spacing: 12) {
                Label(order.expectedDate ?? "Sin fecha esperada", systemImage: "calendar")
                Label("\(order.lines.count) líneas", systemImage: "list.bullet.rectangle")
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            Text(order.total?.formatted ?? "Costos protegidos por permiso")
                .font(.caption.weight(.semibold))
                .foregroundStyle(order.costsVisible ? Color.primary : Color.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct AdminPurchaseOrderDetailView: View {
    @ObservedObject var viewModel: AdminPurchaseOrderViewModel
    let orderId: String

    var body: some View {
        Group {
            if let order = viewModel.order(id: orderId) {
                orderList(order)
            } else if viewModel.isLoadingDetail {
                ProgressView("Cargando orden…")
            } else {
                NexoAdminUXEmptyState(
                    systemImage: "doc.text.magnifyingglass",
                    title: "Orden no disponible",
                    message: viewModel.detailErrorMessage ?? "Vuelve a la lista y actualiza la consulta."
                )
                .padding(20)
            }
        }
        .navigationTitle(viewModel.order(id: orderId)?.orderNumber ?? "Orden de compra")
        .task(id: orderId) { await viewModel.refreshDetail(id: orderId) }
    }

    private func orderList(_ order: AdminPurchaseOrder) -> some View {
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
                LabeledContent("Orden", value: order.orderNumber)
                LabeledContent("Estado", value: order.status.title)
                LabeledContent("Proveedor", value: order.supplierSnapshot.displayName)
                LabeledContent("Sucursal", value: order.branchId)
                LabeledContent("Moneda", value: order.currency)
                optionalContent("Fecha esperada", order.expectedDate)
                LabeledContent("Condición de pago", value: order.paymentTermsSnapshot.title)
            }

            if viewModel.canViewReceipts {
                Section("Recepciones vinculadas") {
                    NavigationLink {
                        AdminPurchaseReceiptListView(
                            viewModel: viewModel.makeReceiptViewModel(for: order.id)
                        )
                    } label: {
                        Label("Revisar recepciones de esta orden", systemImage: "shippingbox.and.arrow.backward.fill")
                    }
                }
            }

            if order.costsVisible {
                Section("Totales confirmados por backend") {
                    moneyContent("Subtotal", order.subtotal)
                    moneyContent("Descuento", order.discountTotal)
                    moneyContent("Impuestos", order.taxTotal)
                    moneyContent("Total", order.total)
                }
            } else {
                Section {
                    NexoAdminUXInlineMessage(
                        title: "Costos protegidos",
                        message: "El backend omitió costos y totales. Se requiere purchase_orders.cost_view; Admin no intenta reconstruirlos.",
                        tone: .warning
                    )
                }
            }

            Section("Líneas: ordenado frente a recibido") {
                ForEach(order.lines) { line in
                    VStack(alignment: .leading, spacing: 7) {
                        HStack {
                            Text(line.descriptionSnapshot)
                                .font(.headline)
                            Spacer(minLength: 8)
                            Text(line.kind.title)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Text(
                            "Ordenado: \(line.orderedQuantity.formatted) · Recibido: \(line.receivedQuantityFormatted) \(line.orderedQuantity.unitCode)"
                        )
                        .font(.subheadline)

                        if let sku = line.catalogItemSnapshot?.sku {
                            Label(sku, systemImage: "barcode")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        if let warehouse = line.targetWarehouseId {
                            Label(warehouse, systemImage: "building.2.crop.circle")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        if order.costsVisible {
                            HStack(spacing: 12) {
                                if let unitCost = line.unitCost {
                                    Text("Unitario: \(unitCost.formatted)")
                                }
                                if let total = line.lineTotal {
                                    Text("Total: \(total.formatted)")
                                }
                            }
                            .font(.caption.weight(.semibold))
                        }

                        if let notes = line.notes?.trimmedOrNil {
                            Text(notes)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }

            Section("Evidencia y notas") {
                optionalContent("Notas", order.notes)
                LabeledContent("Adjuntos vinculados", value: String(order.attachmentIds.count))
            }

            Section("Auditoría y ciclo de vida") {
                LabeledContent("Versión", value: String(order.version))
                LabeledContent("Creada", value: order.createdAt)
                LabeledContent("Creada por", value: order.createdBy)
                LabeledContent("Actualizada", value: order.updatedAt)
                LabeledContent("Actualizada por", value: order.updatedBy)
                optionalContent("Enviada", order.sentAt)
                optionalContent("Enviada por", order.sentBy)
                optionalContent("Cerrada", order.closedAt)
                optionalContent("Cerrada por", order.closedBy)
                optionalContent("Motivo de cierre", order.closeReason)
                optionalContent("Cancelada", order.cancelledAt)
                optionalContent("Cancelada por", order.cancelledBy)
                optionalContent("Motivo de cancelación", order.cancellationReason)
            }

            Section {
                NexoAdminUXInlineMessage(
                    title: "Sin mutaciones desde Admin",
                    message: "La ruta Admin de órdenes es de solo lectura. Las transiciones permanecen en Business y se auditan en backend.",
                    tone: .info
                )
            }
        }
        .refreshable { await viewModel.refreshDetail(id: order.id) }
    }

    @ViewBuilder
    private func optionalContent(_ label: String, _ value: String?) -> some View {
        if let value = value?.trimmedOrNil {
            LabeledContent(label, value: value)
        }
    }

    @ViewBuilder
    private func moneyContent(_ label: String, _ value: AdminProcurementMoney?) -> some View {
        if let value {
            LabeledContent(label, value: value.formatted)
        }
    }
}

private extension AdminPurchaseOrderStatus {
    var tint: Color {
        switch self {
        case .draft: return .secondary
        case .sent: return .blue
        case .partiallyReceived: return .orange
        case .received: return .green
        case .cancelled: return .red
        case .closed: return .purple
        }
    }
}
