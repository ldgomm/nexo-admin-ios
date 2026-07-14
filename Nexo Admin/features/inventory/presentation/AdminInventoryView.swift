//
//  AdminInventoryView.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import Foundation
import SwiftUI

struct AdminInventoryView: View {
    @StateObject private var viewModel: AdminInventoryViewModel

    init(
        repository: any AdminInventoryRepository,
        branches: [AdminBusinessBranch],
        activities: [AdminBusinessActivity],
        permissions: Set<String>
    ) {
        _viewModel = StateObject(
            wrappedValue: AdminInventoryViewModel(
                repository: repository,
                branches: branches,
                activities: activities,
                permissions: permissions
            )
        )
    }

    var body: some View {
        Group {
            if !viewModel.canView {
                EmptyStateView(
                    systemImage: "lock.fill",
                    title: "Sin permiso de inventario",
                    message: "Necesitas inventory.view para abrir este módulo."
                )
            } else if viewModel.branches.isEmpty {
                EmptyStateView(
                    systemImage: "building.2.crop.circle",
                    title: "Primero crea una sucursal",
                    message: "El stock operativo siempre pertenece a una sucursal."
                )
            } else if viewModel.activities.isEmpty {
                EmptyStateView(
                    systemImage: "square.stack.3d.up.slash",
                    title: "Sin actividad activa",
                    message: "Activa al menos una actividad antes de configurar existencias."
                )
            } else {
                inventoryList
            }
        }
        .navigationTitle("Inventario")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task { await viewModel.refresh() }
                } label: {
                    if viewModel.isLoading {
                        ProgressView()
                    } else {
                        Image(systemName: "arrow.clockwise")
                    }
                }
                .disabled(viewModel.isLoading)
                .accessibilityLabel("Actualizar inventario")
            }
        }
        .task { await viewModel.loadIfNeeded() }
        .onChange(of: viewModel.selectedBranchId) { _, _ in
            Task { await viewModel.refresh() }
        }
        .onChange(of: viewModel.selectedActivityId) { _, _ in
            Task { await viewModel.refresh() }
        }
    }

    private var inventoryList: some View {
        List {
            if let error = viewModel.errorMessage {
                Section {
                    InventoryFeedbackRow(
                        title: "No se pudo completar",
                        message: error,
                        systemImage: "exclamationmark.triangle.fill",
                        color: .red,
                        dismiss: viewModel.clearMessages
                    )
                }
            } else if let success = viewModel.successMessage {
                Section {
                    InventoryFeedbackRow(
                        title: "Listo",
                        message: success,
                        systemImage: "checkmark.circle.fill",
                        color: .green,
                        dismiss: viewModel.clearMessages
                    )
                }
            }

            Section {
                Picker("Sucursal", selection: $viewModel.selectedBranchId) {
                    ForEach(viewModel.branches) { branch in
                        Text(branch.name).tag(branch.id)
                    }
                }

                Picker("Actividad", selection: $viewModel.selectedActivityId) {
                    ForEach(viewModel.activities) { activity in
                        Text(activity.name).tag(activity.id)
                    }
                }

                TextField("Producto, SKU o código", text: $viewModel.query)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                Picker("Estado", selection: $viewModel.selectedFilter) {
                    ForEach(AdminInventoryFilter.allCases) { filter in
                        Text(filter.title).tag(filter)
                    }
                }
            } header: {
                Text("Consulta")
            }

            Section {
                AdminInventoryReadinessView(readiness: viewModel.readiness)
                Text(viewModel.inventoryScopeMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if viewModel.hasActiveFilters {
                    Button("Mostrar todos los productos") {
                        viewModel.clearFilters()
                    }
                }
            } header: {
                Text("Salud total del inventario")
            }

            Section {
                Text("Incluye todos los productos y movimientos de la sucursal y actividad seleccionadas durante los últimos 30 días. Es un reporte operativo/referencial; no sustituye un Kardex contable o legal.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Button {
                    Task { await viewModel.exportConsolidatedKardex() }
                } label: {
                    HStack(spacing: 8) {
                        if viewModel.isExportingKardex {
                            ProgressView().controlSize(.small)
                        } else {
                            Image(systemName: "square.and.arrow.down")
                        }
                        Text(viewModel.isExportingKardex ? "Preparando CSV…" : "Exportar Kardex consolidado CSV")
                    }
                }
                .disabled(viewModel.isExportingKardex)
                if let file = viewModel.downloadedKardexFile {
                    ShareLink(item: file.localURL) {
                        Label("Compartir \(file.fileName)", systemImage: "square.and.arrow.up")
                    }
                }
            } header: {
                Text("Kardex operativo")
            }

            Section {
                if viewModel.isLoading && viewModel.items.isEmpty {
                    HStack {
                        Spacer()
                        ProgressView("Cargando inventario…")
                        Spacer()
                    }
                    .padding(.vertical, 24)
                } else if viewModel.visibleItems.isEmpty {
                    EmptyStateView(
                        systemImage: "shippingbox",
                        title: "Sin coincidencias",
                        message: "Cambia la búsqueda, el estado o la sucursal seleccionada."
                    )
                } else {
                    ForEach(viewModel.visibleItems) { item in
                        NavigationLink {
                            AdminInventoryItemDetailView(
                                viewModel: viewModel,
                                catalogItemId: item.catalogItemId
                            )
                        } label: {
                            AdminInventoryItemRow(item: item)
                        }
                    }
                }
            } header: {
                Text(viewModel.visibleResultTitle)
            } footer: {
                Text("Solo aparecen productos del catálogo local de la actividad seleccionada. Ajustar stock no copia productos ni los habilita en otras actividades.")
            }
        }
        .refreshable { await viewModel.refresh() }
    }
}

private struct AdminInventoryReadinessView: View {
    let readiness: AdminInventoryReadiness

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(
                readiness.statusTitle,
                systemImage: readiness.isReady ? "checkmark.seal.fill" : "exclamationmark.triangle.fill"
            )
            .font(.headline)
            .foregroundStyle(readiness.isReady ? Color.green : Color.orange)

            HStack(spacing: 10) {
                metric("Productos", value: readiness.total, color: .blue)
                metric("Controlados", value: readiness.tracked, color: .green)
                metric("Sin configurar", value: readiness.unconfigured, color: .orange)
            }

            HStack(spacing: 10) {
                metric("Stock bajo", value: readiness.lowStock, color: .orange)
                metric("Sin stock", value: readiness.outOfStock, color: .red)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Valor referencial")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(referenceValueTitle)
                        .font(.subheadline.weight(.semibold))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(10)
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
            }

            Text("El valor es operativo y referencial; no reemplaza valoración contable ni Kardex legal.")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }

    private func metric(_ title: String, value: Int, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("\(value)")
                .font(.title3.bold())
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
    }

    private var referenceValueTitle: String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "es_EC")
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSDecimalNumber(decimal: readiness.referenceValue)) ?? "USD 0"
    }
}

private struct AdminInventoryItemRow: View {
    let item: AdminInventoryItem

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: statusImage)
                .foregroundStyle(statusColor)
                .frame(width: 28, height: 28)
                .background(statusColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 5) {
                Text(item.displayName)
                    .font(.headline)
                if let sku = item.sku, !sku.isEmpty {
                    Text("SKU: \(sku)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Label(item.statusTitle, systemImage: statusImage)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(statusColor)
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 4) {
                if item.tracksInventory {
                    Text(item.quantityOnHandTitle)
                        .font(.subheadline.weight(.semibold))
                    Text("en mano")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Configurar")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.orange)
                }
            }
        }
        .padding(.vertical, 5)
    }

    private var statusImage: String {
        if item.needsConfiguration { return "gearshape.fill" }
        if item.isOutOfStock { return "xmark.octagon.fill" }
        if item.isLowStock { return "exclamationmark.triangle.fill" }
        return "checkmark.circle.fill"
    }

    private var statusColor: Color {
        if item.needsConfiguration || item.isLowStock { return .orange }
        if item.isOutOfStock { return .red }
        return .green
    }
}

private struct InventoryFeedbackRow: View {
    let title: String
    let message: String
    let systemImage: String
    let color: Color
    let dismiss: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: systemImage).foregroundStyle(color)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.subheadline.bold())
                Text(message).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Button(action: dismiss) {
                Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
    }
}

struct AdminInventoryItemDetailView: View {
    @ObservedObject var viewModel: AdminInventoryViewModel
    let catalogItemId: String

    @State private var tracksInventory = false
    @State private var stockUnit = "unit"
    @State private var lowStockThreshold = "0"
    @State private var allowNegativeStock = false
    @State private var blockSaleWhenInsufficientStock = true
    @State private var defaultWarehouseId = ""
    @State private var referenceCost = ""
    @State private var policyReason = "Configurar política de inventario"

    @State private var adjustmentKind: AdminInventoryAdjustmentKind = .set
    @State private var adjustmentQuantity = ""
    @State private var adjustmentReason = "Stock inicial confirmado"
    @State private var adjustmentNotes = ""
    @State private var didConfigure = false

    var body: some View {
        Group {
            if let item = viewModel.item(catalogItemId: catalogItemId) {
                detailList(item)
                    .navigationTitle(item.displayName)
                    .task(id: item.catalogItemId) {
                        configure(from: item)
                        await viewModel.loadMovements(for: item)
                    }
                    .onChange(of: item) { _, updated in
                        configure(from: updated)
                    }
            } else {
                EmptyStateView(
                    systemImage: "shippingbox",
                    title: "Producto no disponible",
                    message: "Actualiza el inventario y vuelve a intentarlo."
                )
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    private func detailList(_ item: AdminInventoryItem) -> some View {
        List {
            if let error = viewModel.errorMessage {
                Section {
                    InventoryFeedbackRow(
                        title: "No se pudo completar",
                        message: error,
                        systemImage: "exclamationmark.triangle.fill",
                        color: .red,
                        dismiss: viewModel.clearMessages
                    )
                }
            } else if let success = viewModel.successMessage {
                Section {
                    InventoryFeedbackRow(
                        title: "Listo",
                        message: success,
                        systemImage: "checkmark.circle.fill",
                        color: .green,
                        dismiss: viewModel.clearMessages
                    )
                }
            }

            Section("Saldo principal") {
                LabeledContent("Estado", value: item.statusTitle)
                LabeledContent("En mano", value: item.quantityOnHandTitle)
                LabeledContent("Disponible", value: item.quantityAvailableTitle)
                LabeledContent("Mínimo", value: item.lowStockThresholdTitle)
                if let warehouseId = item.warehouseId {
                    LabeledContent("Bodega", value: warehouseId)
                }
            }

            Section {
                AdminInventoryBalanceExplanationRow(
                    title: "Reservado",
                    value: AdminInventoryNumberFormatter.format(item.quantityReserved, unit: item.stockUnit),
                    explanation: "Lo crean y liberan las reservas del backend. Reduce el disponible sin cambiar las existencias en mano."
                )
                AdminInventoryBalanceExplanationRow(
                    title: "Dañado",
                    value: AdminInventoryNumberFormatter.format(item.quantityDamaged, unit: item.stockUnit),
                    explanation: "Se excluye del disponible. El backend actual aún no publica una operación Admin auditada para modificarlo."
                )
                AdminInventoryBalanceExplanationRow(
                    title: "En tránsito",
                    value: AdminInventoryNumberFormatter.format(item.quantityInTransit, unit: item.stockUnit),
                    explanation: "Está reservado para transferencias por etapas. Hoy las transferencias se completan inmediatamente, por eso normalmente permanece en cero."
                )
            } header: {
                Text("Compromisos y logística · solo lectura")
            } footer: {
                Text("Estos saldos no se editan con el ajuste manual de existencias. Cambian únicamente mediante operaciones específicas y auditadas del backend.")
            }

            Section {
                Toggle("Controlar inventario", isOn: $tracksInventory)
                    .onChange(of: tracksInventory) { wasTracking, isTracking in
                        if !wasTracking && isTracking {
                            allowNegativeStock = false
                            blockSaleWhenInsufficientStock = true
                            adjustmentKind = .set
                        }
                    }
                TextField("Unidad de stock", text: $stockUnit)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                TextField("Stock mínimo", text: $lowStockThreshold)
                    .keyboardType(.decimalPad)
                Toggle("Permitir stock negativo", isOn: $allowNegativeStock)
                Toggle("Bloquear venta si no alcanza", isOn: $blockSaleWhenInsufficientStock)
                    .disabled(allowNegativeStock)
                TextField("Bodega predeterminada (opcional)", text: $defaultWarehouseId)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                TextField("Costo referencial (opcional)", text: $referenceCost)
                    .keyboardType(.decimalPad)
                TextField("Motivo del cambio", text: $policyReason, axis: .vertical)
                    .lineLimit(2...4)

                Button {
                    Task {
                        _ = await viewModel.savePolicy(
                            catalogItemId: item.catalogItemId,
                            input: AdminInventoryPolicyInput(
                                tracksInventory: tracksInventory,
                                stockUnit: stockUnit,
                                lowStockThreshold: lowStockThreshold,
                                allowNegativeStock: allowNegativeStock,
                                blockSaleWhenInsufficientStock: blockSaleWhenInsufficientStock,
                                reason: policyReason,
                                defaultWarehouseId: defaultWarehouseId.trimmedOrNil,
                                valuationMode: referenceCost.trimmedOrNil == nil ? nil : "REFERENCE",
                                referenceCost: referenceCost.trimmedOrNil
                            )
                        )
                    }
                } label: {
                    Label("Guardar política", systemImage: "checkmark.shield.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!viewModel.canAdjust || viewModel.isSaving)
            } header: {
                Text("Política de inventario")
            } footer: {
                Text("Para productos físicos recomendamos no permitir negativos y bloquear la venta cuando el disponible sea insuficiente.")
            }

            Section {
                if !item.tracksInventory {
                    Label(
                        "Activa y guarda primero el control de inventario.",
                        systemImage: "info.circle.fill"
                    )
                    .foregroundStyle(.orange)
                } else {
                    Picker("Operación", selection: $adjustmentKind) {
                        ForEach(AdminInventoryAdjustmentKind.allCases) { kind in
                            Text(kind.title).tag(kind)
                        }
                    }
                    .pickerStyle(.segmented)

                    TextField(adjustmentKind == .set ? "Nuevo stock" : "Cantidad", text: $adjustmentQuantity)
                        .keyboardType(.decimalPad)
                    TextField("Motivo", text: $adjustmentReason, axis: .vertical)
                        .lineLimit(2...4)
                    TextField("Nota opcional", text: $adjustmentNotes, axis: .vertical)
                        .lineLimit(2...4)

                    Button {
                        Task {
                            let ok = await viewModel.adjust(
                                AdminInventoryAdjustmentInput(
                                    branchId: viewModel.selectedBranchId,
                                    catalogItemId: item.catalogItemId,
                                    kind: adjustmentKind,
                                    quantity: adjustmentQuantity,
                                    reason: adjustmentReason,
                                    notes: adjustmentNotes.trimmedOrNil,
                                    unitCode: stockUnit,
                                    allowNegativeStock: allowNegativeStock,
                                    warehouseId: defaultWarehouseId.trimmedOrNil ?? item.warehouseId,
                                    reasonCode: "ADMIN_MANUAL_ADJUSTMENT",
                                    unitCost: referenceCost.trimmedOrNil,
                                    requestId: UUID().uuidString.lowercased()
                                )
                            )
                            if ok { adjustmentQuantity = "" }
                        }
                    } label: {
                        Label("Aplicar ajuste", systemImage: "plusminus.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!viewModel.canAdjust || viewModel.isSaving)
                }
            } header: {
                Text("Actualizar existencias")
            } footer: {
                Text("Cada operación exige motivo, usa idempotencia y crea un movimiento auditable en backend.")
            }

            Section("Movimientos recientes") {
                let movements = viewModel.movements(catalogItemId: item.catalogItemId)
                if movements.isEmpty {
                    ContentUnavailableView(
                        "Sin movimientos",
                        systemImage: "clock.arrow.circlepath",
                        description: Text("Los ajustes y ventas aparecerán aquí.")
                    )
                } else {
                    ForEach(movements) { movement in
                        NavigationLink {
                            AdminInventoryMovementDetailView(movement: movement)
                        } label: {
                            AdminInventoryMovementRow(movement: movement)
                        }
                    }
                }
            }
        }
    }

    private func configure(from item: AdminInventoryItem) {
        tracksInventory = item.tracksInventory
        if item.hasStockProfile || !didConfigure {
            stockUnit = item.stockUnit
            lowStockThreshold = item.lowStockThreshold
            allowNegativeStock = item.allowNegativeStock
            blockSaleWhenInsufficientStock = item.blockSaleWhenInsufficientStock
            defaultWarehouseId = item.warehouseId ?? ""
            referenceCost = item.lastCost ?? item.averageCost ?? ""
        }
        didConfigure = true
    }
}

private struct AdminInventoryBalanceExplanationRow: View {
    let title: String
    let value: String
    let explanation: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            LabeledContent(title, value: value)
            Text(explanation)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }
}

private struct AdminInventoryMovementRow: View {
    let movement: AdminInventoryMovement

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Label(movement.title, systemImage: movement.direction.lowercased() == "out" ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text(movement.deltaTitle)
                    .font(.subheadline.bold())
                    .foregroundStyle(movement.direction.lowercased() == "out" ? .red : .green)
            }
            if let transition = movement.balanceTransitionTitle {
                Text("Saldo: \(transition)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if let reason = movement.reason?.trimmedOrNil {
                Text(reason)
                    .font(.caption)
            }
            Text(movement.occurredAtTitle)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

private struct AdminInventoryMovementDetailView: View {
    let movement: AdminInventoryMovement

    var body: some View {
        List {
            Section("Movimiento") {
                LabeledContent("Tipo", value: movement.title)
                LabeledContent("Cantidad", value: movement.deltaTitle)
                if let transition = movement.balanceTransitionTitle {
                    LabeledContent("Cambio de saldo", value: transition)
                }
                LabeledContent("Fecha", value: movement.occurredAtTitle)
                LabeledContent("Sucursal", value: movement.branchId)
                if let warehouseId = movement.warehouseId?.trimmedOrNil {
                    LabeledContent("Bodega", value: warehouseId)
                }
            }

            Section("Auditoría") {
                if let reason = movement.reason?.trimmedOrNil {
                    LabeledContent("Motivo", value: reason)
                }
                if let reasonCode = movement.reasonCode?.trimmedOrNil {
                    LabeledContent("Código", value: reasonCode)
                }
                if let sourceType = movement.sourceType?.trimmedOrNil {
                    LabeledContent("Origen", value: sourceType.replacingOccurrences(of: "_", with: " ").capitalized)
                }
                if let sourceId = movement.sourceId?.trimmedOrNil {
                    LabeledContent("Referencia", value: sourceId)
                }
                if let createdBy = movement.createdBy?.trimmedOrNil {
                    LabeledContent("Registrado por", value: createdBy)
                }
                LabeledContent("ID del movimiento", value: movement.id)
            }
        }
        .navigationTitle("Detalle del movimiento")
        .navigationBarTitleDisplayMode(.inline)
    }
}
