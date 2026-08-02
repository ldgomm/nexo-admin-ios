//
//  AdminInventoryModels.swift
//  Nexo Admin
//
//  Created by José Ruiz on 29/7/26.
//

import Foundation

enum AdminInventoryFilter: String, CaseIterable, Identifiable, Sendable {
    case all
    case tracked
    case lowStock
    case outOfStock
    case unconfigured

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: return "Todos"
        case .tracked: return "Controlados"
        case .lowStock: return "Stock bajo"
        case .outOfStock: return "Sin stock"
        case .unconfigured: return "Sin configurar"
        }
    }
}

enum AdminInventoryAdjustmentKind: String, CaseIterable, Identifiable, Sendable {
    case increase = "INCREASE"
    case decrease = "DECREASE"
    case set = "SET"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .increase: return "Aumentar"
        case .decrease: return "Disminuir"
        case .set: return "Fijar stock"
        }
    }
}

struct AdminInventoryItem: Identifiable, Equatable, Sendable {
    let id: String
    let catalogItemId: String
    let branchId: String?
    let warehouseId: String?
    let name: String?
    let sku: String?
    let barcode: String?
    let catalogStatus: String?
    let quantityOnHand: String
    let quantityReserved: String
    let quantityAvailable: String
    let quantityDamaged: String
    let quantityInTransit: String
    let stockUnit: String
    let lowStockThreshold: String
    let status: String
    let tracksInventory: Bool
    let hasStockProfile: Bool
    let allowNegativeStock: Bool
    let blockSaleWhenInsufficientStock: Bool
    let averageCost: String?
    let lastCost: String?
    let referenceValue: String?
    let lastMovementAt: String?
    let updatedAt: String?

    var displayName: String {
        name?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty ?? "Producto \(catalogItemId)"
    }

    var normalizedStatus: String {
        status.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    var isLowStock: Bool { normalizedStatus == "low_stock" }

    var isOutOfStock: Bool {
        normalizedStatus == "out_of_stock" || decimal(quantityAvailable) <= .zero
    }

    var needsConfiguration: Bool {
        !tracksInventory || !hasStockProfile || normalizedStatus == "no_profile" || normalizedStatus == "untracked"
    }

    var statusTitle: String {
        if !tracksInventory { return "Sin control de inventario" }
        if !hasStockProfile || normalizedStatus == "no_profile" { return "Sin saldo inicial" }
        if isOutOfStock { return "Sin stock" }
        if isLowStock { return "Stock bajo" }
        return "Disponible"
    }

    var quantityOnHandTitle: String { AdminInventoryNumberFormatter.format(quantityOnHand, unit: stockUnit) }
    var quantityAvailableTitle: String { AdminInventoryNumberFormatter.format(quantityAvailable, unit: stockUnit) }
    var lowStockThresholdTitle: String { AdminInventoryNumberFormatter.format(lowStockThreshold, unit: stockUnit) }

    private func decimal(_ value: String) -> Decimal {
        Decimal(string: value.replacingOccurrences(of: ",", with: "."), locale: Locale(identifier: "en_US_POSIX")) ?? .zero
    }
}

struct AdminInventoryMovement: Identifiable, Equatable, Sendable {
    let id: String
    let branchId: String
    let catalogItemId: String
    let warehouseId: String?
    let type: String
    let direction: String
    let quantity: String
    let quantityDelta: String
    let quantityBefore: String?
    let quantityAfter: String?
    let unitCode: String
    let reason: String?
    let reasonCode: String?
    let sourceType: String?
    let sourceId: String?
    let occurredAt: String
    let createdBy: String?

    var title: String {
        if type.lowercased().contains("adjust") { return "Ajuste manual" }
        switch direction.lowercased() {
        case "in": return "Entrada de inventario"
        case "out": return "Salida de inventario"
        default: return type.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }

    var deltaTitle: String {
        let prefix = direction.lowercased() == "out" ? "−" : direction.lowercased() == "in" ? "+" : ""
        return "\(prefix)\(AdminInventoryNumberFormatter.format(quantity, unit: unitCode))"
    }

    var balanceTransitionTitle: String? {
        guard let quantityBefore, let quantityAfter else { return nil }
        return "\(AdminInventoryNumberFormatter.format(quantityBefore, unit: unitCode)) → \(AdminInventoryNumberFormatter.format(quantityAfter, unit: unitCode))"
    }

    var occurredAtTitle: String {
        let precise = ISO8601DateFormatter()
        precise.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let standard = ISO8601DateFormatter()
        guard let date = precise.date(from: occurredAt) ?? standard.date(from: occurredAt) else {
            return occurredAt
        }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_EC")
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct AdminInventoryPolicyInput: Equatable, Sendable {
    var tracksInventory: Bool
    var stockUnit: String
    var lowStockThreshold: String
    var allowNegativeStock: Bool
    var blockSaleWhenInsufficientStock: Bool
    var reason: String
    var defaultWarehouseId: String?
    var valuationMode: String?
    var referenceCost: String?
}

struct AdminInventoryAdjustmentInput: Equatable, Sendable {
    var branchId: String
    var catalogItemId: String
    var kind: AdminInventoryAdjustmentKind
    var quantity: String
    var reason: String
    var notes: String?
    var unitCode: String
    var allowNegativeStock: Bool
    var warehouseId: String?
    var reasonCode: String?
    var unitCost: String?
    var requestId: String
}

struct AdminInventoryAdjustmentResult: Equatable, Sendable {
    let balance: AdminInventoryItem
    let movement: AdminInventoryMovement
    let idempotencyReplayed: Bool
}

struct AdminInventoryReadiness: Equatable, Sendable {
    let total: Int
    let tracked: Int
    let unconfigured: Int
    let lowStock: Int
    let outOfStock: Int
    let referenceValue: Decimal

    init(items: [AdminInventoryItem]) {
        total = items.count
        tracked = items.filter { $0.tracksInventory && $0.hasStockProfile && !$0.needsConfiguration }.count
        unconfigured = items.filter(\.needsConfiguration).count
        lowStock = items.filter(\.isLowStock).count
        outOfStock = items.filter { $0.tracksInventory && $0.isOutOfStock }.count
        referenceValue = items.reduce(.zero) { partial, item in
            partial + (item.referenceValue.flatMap {
                Decimal(string: $0.replacingOccurrences(of: ",", with: "."), locale: Locale(identifier: "en_US_POSIX"))
            } ?? .zero)
        }
    }

    var isReady: Bool { total > 0 && unconfigured == 0 }

    var statusTitle: String {
        if isReady { return "Inventario configurado" }
        if unconfigured == 1 { return "1 producto sin configurar" }
        if unconfigured > 1 { return "\(unconfigured) productos sin configurar" }
        return "Inventario requiere atención"
    }
}

enum AdminInventoryNumberFormatter {
    static func format(_ raw: String, unit: String? = nil) -> String {
        let normalized = raw.replacingOccurrences(of: ",", with: ".")
        let value = Decimal(string: normalized, locale: Locale(identifier: "en_US_POSIX")) ?? .zero
        let number = NSDecimalNumber(decimal: value)
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "es_EC")
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 6
        let rendered = formatter.string(from: number) ?? normalized
        guard let unit = unit?.trimmingCharacters(in: .whitespacesAndNewlines), !unit.isEmpty else { return rendered }
        let readableUnit = ["unit", "unidad", "units"].contains(unit.lowercased()) ? "unidades" : unit
        return "\(rendered) \(readableUnit)"
    }
}

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}
