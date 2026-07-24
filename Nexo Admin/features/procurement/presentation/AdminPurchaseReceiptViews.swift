//
//  AdminPurchaseReceiptViews.swift
//  Nexo Admin
//
//  27R.N.4 — Read-only receipt list, detail and inventory-effect review.
//

import Foundation
import SwiftUI

struct AdminPurchaseReceiptListView: View {
    @StateObject private var viewModel: AdminPurchaseReceiptViewModel

    init(viewModel: AdminPurchaseReceiptViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        List {
            Section {
                NexoAdminUXInlineMessage(
                    title: "Revisión administrativa",
                    message: "Admin consulta recepciones y efectos canónicos. Confirmar, cancelar o reparar inventario permanece fuera de esta superficie.",
                    tone: .info
                )
            }

            filterSection
            feedbackSection
            resultSection
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Recepciones")
        .task { await viewModel.loadIfNeeded() }
        .refreshable { await viewModel.refresh() }
    }

    private var filterSection: some View {
        Section("Filtros del backend") {
            Picker("Estado", selection: $viewModel.statusFilter) {
                ForEach(AdminPurchaseReceiptStatusFilter.allCases) { filter in
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
            TextField("Orden de compra (opcional)", text: $viewModel.purchaseOrderId)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            TextField("Recibida desde (ISO 8601)", text: $viewModel.receivedFrom)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            TextField("Recibida hasta (ISO 8601)", text: $viewModel.receivedTo)
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
                    title: "No se pudieron cargar las recepciones",
                    message: error,
                    tone: .danger
                )
            }
        }
    }

    @ViewBuilder
    private var resultSection: some View {
        Section("Resultados") {
            if viewModel.isLoading && viewModel.receipts.isEmpty {
                HStack {
                    Spacer()
                    ProgressView("Cargando recepciones…")
                    Spacer()
                }
            } else if viewModel.receipts.isEmpty {
                EmptyStateView(
                    systemImage: "shippingbox.and.arrow.backward",
                    title: "Sin recepciones",
                    message: viewModel.hasActiveFilters
                        ? "No hay recepciones que coincidan con los filtros enviados al backend."
                        : "Todavía no existen recepciones para revisar."
                )
            } else {
                ForEach(viewModel.receipts) { receipt in
                    NavigationLink {
                        AdminPurchaseReceiptDetailView(viewModel: viewModel, receiptId: receipt.id)
                    } label: {
                        AdminPurchaseReceiptRow(receipt: receipt)
                    }
                    .task { await viewModel.loadMoreIfNeeded(current: receipt) }
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

private struct AdminPurchaseReceiptRow: View {
    let receipt: AdminPurchaseReceipt

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(alignment: .firstTextBaseline) {
                Text(receipt.receiptNumber)
                    .font(.headline)
                Spacer(minLength: 8)
                NexoAdminUXStatusBadge(
                    title: receipt.status.title,
                    systemImage: receipt.status.systemImage,
                    tint: receipt.status.tint
                )
            }

            Text("Proveedor: \(receipt.supplierId)")
                .font(.subheadline)

            HStack(spacing: 12) {
                Label(receipt.receivedAt, systemImage: "calendar")
                Label("\(receipt.lines.count) líneas", systemImage: "list.bullet.rectangle")
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            Label(receipt.highLevelEffectTitle, systemImage: "arrow.triangle.2.circlepath")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct AdminPurchaseReceiptDetailView: View {
    @ObservedObject var viewModel: AdminPurchaseReceiptViewModel
    let receiptId: String

    var body: some View {
        Group {
            if let receipt = viewModel.receipt(id: receiptId) {
                receiptList(receipt)
            } else if viewModel.isLoadingDetail {
                ProgressView("Cargando recepción…")
            } else {
                NexoAdminUXEmptyState(
                    systemImage: "shippingbox.and.arrow.backward",
                    title: "Recepción no disponible",
                    message: viewModel.detailErrorMessage ?? "Vuelve a la lista y actualiza la consulta."
                )
                .padding(20)
            }
        }
        .navigationTitle(viewModel.receipt(id: receiptId)?.receiptNumber ?? "Recepción")
        .task(id: receiptId) { await viewModel.refreshDetail(id: receiptId) }
    }

    private func receiptList(_ receipt: AdminPurchaseReceipt) -> some View {
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

            identitySection(receipt)
            orderSection(receipt)
            quantitySection(receipt)
            inventoryEffectSection(receipt)
            trackingAndEvidenceSection(receipt)
            auditSection(receipt)

            Section {
                NexoAdminUXInlineMessage(
                    title: "Solo lectura",
                    message: "Admin no crea, edita, confirma, cancela ni revierte recepciones; tampoco escribe o repara inventario.",
                    tone: .info
                )
            }
        }
        .refreshable { await viewModel.refreshDetail(id: receipt.id) }
    }

    private func identitySection(_ receipt: AdminPurchaseReceipt) -> some View {
        Section("Identidad y estado") {
            LabeledContent("Recepción", value: receipt.receiptNumber)
            LabeledContent("Estado", value: receipt.status.title)
            LabeledContent("Proveedor", value: receipt.supplierId)
            LabeledContent("Sucursal", value: receipt.branchId)
            LabeledContent("Bodega", value: receipt.warehouseId)
            LabeledContent("Fecha recibida", value: receipt.receivedAt)
            LabeledContent("Versión", value: String(receipt.version))
        }
    }

    @ViewBuilder
    private func orderSection(_ receipt: AdminPurchaseReceipt) -> some View {
        Section("Orden vinculada") {
            if let order = viewModel.linkedPurchaseOrder(receiptId: receipt.id) {
                LabeledContent("Orden", value: order.orderNumber)
                LabeledContent("Estado de orden", value: order.status.title)
                NavigationLink {
                    AdminReceiptLinkedPurchaseOrderDestination(
                        viewModel: viewModel.makePurchaseOrderViewModel(),
                        orderId: order.id
                    )
                } label: {
                    Label("Abrir orden de compra", systemImage: "doc.text.magnifyingglass")
                }
            } else if let orderId = receipt.purchaseOrderId?.trimmedOrNil {
                LabeledContent("Orden", value: orderId)
                if let message = viewModel.linkedPurchaseOrderError(receiptId: receipt.id) {
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                Text("Recepción sin orden de compra.")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func quantitySection(_ receipt: AdminPurchaseReceipt) -> some View {
        Section("Cantidades por evento") {
            ForEach(receipt.lines) { line in
                VStack(alignment: .leading, spacing: 7) {
                    HStack {
                        Text(line.itemSnapshot?.localName ?? line.kind.title)
                            .font(.headline)
                        Spacer(minLength: 8)
                        Text(line.kind.title)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    LabeledContent(
                        "Recibida en este evento",
                        value: "\(line.receivedQuantity.formatted) \(line.unitCode)"
                    )
                    LabeledContent(
                        "Aceptada",
                        value: "\(line.acceptedQuantityFormatted) \(line.unitCode)"
                    )
                    LabeledContent(
                        "Rechazada",
                        value: "\(line.rejectedQuantityFormatted) \(line.unitCode)"
                    )

                    if let order = viewModel.linkedPurchaseOrder(receiptId: receipt.id),
                       let orderLineId = line.purchaseOrderLineId,
                       let orderLine = order.lines.first(where: { $0.id == orderLineId }) {
                        LabeledContent(
                            "Ordenada",
                            value: "\(orderLine.orderedQuantity.formatted) \(orderLine.orderedQuantity.unitCode)"
                        )
                        LabeledContent(
                            "Recibida acumulada",
                            value: "\(orderLine.receivedQuantityFormatted) \(orderLine.orderedQuantity.unitCode)"
                        )
                        Text("La cantidad restante no está expuesta por el contrato; Admin no la calcula.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if let unitCost = line.unitCost, viewModel.canViewCosts {
                        LabeledContent("Costo unitario de recepción", value: unitCost.formatted)
                    } else {
                        Text("Costo restringido o no registrado; no se interpreta como cero.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    @ViewBuilder
    private func inventoryEffectSection(_ receipt: AdminPurchaseReceipt) -> some View {
        Section("Efecto canónico en inventario") {
            if let effects = viewModel.inventoryEffects(receiptId: receipt.id) {
                NexoAdminUXStatusBadge(
                    title: effects.quantityStatus.title,
                    systemImage: effects.quantityStatus.systemImage,
                    tint: effects.quantityStatus.tint
                )
                LabeledContent("Alcance", value: effects.reconciliationScope.rawValue)
                LabeledContent("Valor", value: effects.valueStatus.title)

                if effects.currencyComesFromReceiptSource {
                    NexoAdminUXInlineMessage(
                        title: "Conciliación limitada a cantidades",
                        message: "La moneda del movimiento se deriva de la recepción. Esta pantalla no declara conciliación de valor ni contabilidad oficial.",
                        tone: .warning
                    )
                }
                if effects.trackedUnitEffectIsOutsideContract {
                    NexoAdminUXInlineMessage(
                        title: "Series y lotes fuera del contrato N4",
                        message: "La recepción conserva la evidencia expuesta, pero este contrato no concilia el efecto individual de unidades rastreadas.",
                        tone: .warning
                    )
                }

                ForEach(effects.lines) { effect in
                    effectLine(effect)
                }
            } else if let error = viewModel.effectError(receiptId: receipt.id) {
                NexoAdminUXInlineMessage(
                    title: "Efecto no disponible",
                    message: error,
                    tone: .warning
                )
            } else if viewModel.isLoadingDetail {
                ProgressView("Consultando efecto…")
            }
        }
    }

    private func effectLine(_ effect: AdminPurchaseReceiptInventoryEffectLine) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Text("Línea \(effect.receiptLineId)")
                    .font(.headline)
                Spacer(minLength: 8)
                NexoAdminUXStatusBadge(
                    title: effect.effectStatus.title,
                    systemImage: effect.effectStatus.systemImage,
                    tint: effect.effectStatus.tint
                )
            }

            LabeledContent(
                "Aceptada",
                value: "\(effect.receiptAcceptedQuantity.formatted) \(effect.receiptAcceptedQuantity.unitCode)"
            )
            LabeledContent("Bodega", value: effect.warehouseId)
            if let movement = effect.movementQuantity {
                LabeledContent("Movimiento", value: "\(movement.formatted) \(movement.unitCode)")
            }
            if let movementType = effect.movementType {
                LabeledContent("Tipo", value: movementType)
            }
            if let before = effect.quantityBefore, let after = effect.quantityAfter {
                LabeledContent("Saldo anterior", value: quantityString(before, effect))
                LabeledContent("Saldo posterior", value: quantityString(after, effect))
            }

            if viewModel.canViewCosts {
                if let unitCost = effect.unitCost {
                    LabeledContent("Costo unitario", value: unitCost.formatted)
                }
                if let totalCost = effect.totalCost {
                    LabeledContent("Costo total", value: totalCost.formatted)
                }
            }
            Text(effect.valueStatus.title)
                .font(.caption)
                .foregroundStyle(.secondary)

            if viewModel.canViewAudit {
                optionalContent("Movimiento ID", effect.inventoryMovementId)
                optionalContent("Fuente", effect.sourceType)
                optionalContent("Fuente ID", effect.sourceId)
                optionalContent("Línea fuente", effect.sourceLineId)
                optionalContent("Ocurrió", effect.occurredAt)
                optionalContent("Actor", effect.createdBy)
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private func trackingAndEvidenceSection(_ receipt: AdminPurchaseReceipt) -> some View {
        Section("Seguimiento y evidencia") {
            let trackedUnits = receipt.lines.flatMap(\.trackedUnits)
            if trackedUnits.isEmpty {
                Text("Sin series o lotes expuestos.")
                    .foregroundStyle(.secondary)
            } else if viewModel.canViewAudit {
                ForEach(trackedUnits.indices, id: \.self) { index in
                    let tracked = trackedUnits[index]
                    VStack(alignment: .leading, spacing: 4) {
                        LabeledContent("Tipo", value: tracked.trackingType)
                        LabeledContent("Valor", value: tracked.trackingValue)
                        optionalContent("Notas", tracked.notes)
                    }
                }
            } else {
                Text("La evidencia de series o lotes requiere procurement.audit_view.")
                    .foregroundStyle(.secondary)
            }

            if viewModel.canViewAudit {
                LabeledContent("Adjuntos vinculados", value: String(receipt.attachmentIds.count))
                optionalContent("Notas", receipt.notes)
            } else {
                Text("Adjuntos, notas y actores están protegidos por permiso de auditoría.")
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private func auditSection(_ receipt: AdminPurchaseReceipt) -> some View {
        Section("Auditoría y ciclo de vida") {
            LabeledContent("Creada", value: receipt.createdAt)
            LabeledContent("Actualizada", value: receipt.updatedAt)
            optionalContent("Confirmada", receipt.confirmedAt)
            optionalContent("Cancelada", receipt.cancelledAt)
            optionalContent("Motivo de cancelación", receipt.cancellationReason)

            if viewModel.canViewAudit {
                LabeledContent("Creada por", value: receipt.createdBy)
                LabeledContent("Actualizada por", value: receipt.updatedBy)
                optionalContent("Confirmada por", receipt.confirmedBy)
                optionalContent("Cancelada por", receipt.cancelledBy)
            }
        }
    }

    private func quantityString(
        _ value: Decimal,
        _ effect: AdminPurchaseReceiptInventoryEffectLine
    ) -> String {
        let quantity = AdminPurchaseQuantity(
            value: value,
            unitCode: effect.receiptAcceptedQuantity.unitCode,
            allowsDecimal: true
        )
        return "\(quantity.formatted) \(quantity.unitCode)"
    }

    @ViewBuilder
    private func optionalContent(_ label: String, _ value: String?) -> some View {
        if let value = value?.trimmedOrNil {
            LabeledContent(label, value: value)
        }
    }
}

private struct AdminReceiptLinkedPurchaseOrderDestination: View {
    @StateObject private var viewModel: AdminPurchaseOrderViewModel
    let orderId: String

    init(viewModel: AdminPurchaseOrderViewModel, orderId: String) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.orderId = orderId
    }

    var body: some View {
        AdminPurchaseOrderDetailView(viewModel: viewModel, orderId: orderId)
    }
}

private extension AdminPurchaseReceiptStatus {
    var tint: Color {
        switch self {
        case .draft: return .secondary
        case .confirming: return .orange
        case .confirmed: return .green
        case .cancelled: return .red
        }
    }
}

private extension AdminPurchaseReceiptQuantityReconciliationStatus {
    var systemImage: String {
        switch self {
        case .noEffectExpected: return "minus.circle.fill"
        case .pending: return "clock.arrow.circlepath"
        case .reviewRequired: return "exclamationmark.triangle.fill"
        case .quantityReconciled: return "checkmark.circle.fill"
        }
    }

    var tint: Color {
        switch self {
        case .noEffectExpected: return .secondary
        case .pending: return .orange
        case .reviewRequired: return .red
        case .quantityReconciled: return .green
        }
    }
}

private extension AdminPurchaseReceiptEffectStatus {
    var systemImage: String {
        switch self {
        case .notApplicable: return "minus.circle.fill"
        case .unverifiable: return "exclamationmark.triangle.fill"
        case .pending: return "clock.arrow.circlepath"
        case .quantityReconciled: return "checkmark.circle.fill"
        }
    }

    var tint: Color {
        switch self {
        case .notApplicable: return .secondary
        case .unverifiable: return .red
        case .pending: return .orange
        case .quantityReconciled: return .green
        }
    }
}
