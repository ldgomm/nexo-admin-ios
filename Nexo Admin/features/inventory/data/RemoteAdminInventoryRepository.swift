//
//  RemoteAdminInventoryRepository.swift
//  Nexo Admin
//
//  Created by José Ruiz on 29/7/26.
//

import Foundation

struct RemoteAdminInventoryRepository: AdminInventoryRepository {
    let api: AdminInventoryAPI

    func listInventory(branchId: String?, activityId: String, query: String?) async throws -> [AdminInventoryItem] {
        try await api.listInventory(
            branchId: branchId,
            activityId: activityId,
            query: query
        ).stock.map { $0.toDomain() }
    }

    func listMovements(branchId: String, catalogItemId: String, warehouseId: String?) async throws -> [AdminInventoryMovement] {
        try await api.listMovements(
            branchId: branchId,
            catalogItemId: catalogItemId,
            warehouseId: warehouseId
        ).movements.map { $0.toDomain() }
    }

    func updatePolicy(catalogItemId: String, input: AdminInventoryPolicyInput) async throws {
        _ = try await api.updatePolicy(
            catalogItemId: catalogItemId,
            request: AdminInventoryPolicyRequestDTO(
                tracksInventory: input.tracksInventory,
                stockUnit: input.stockUnit,
                lowStockThreshold: input.lowStockThreshold,
                allowNegativeStock: input.allowNegativeStock,
                blockSaleWhenInsufficientStock: input.blockSaleWhenInsufficientStock,
                reason: input.reason,
                defaultWarehouseId: input.defaultWarehouseId,
                valuationMode: input.valuationMode,
                referenceCost: input.referenceCost
            )
        )
    }

    func adjust(_ input: AdminInventoryAdjustmentInput) async throws -> AdminInventoryAdjustmentResult {
        let response = try await api.adjust(
            AdminInventoryAdjustmentRequestDTO(
                branchId: input.branchId,
                catalogItemId: input.catalogItemId,
                adjustmentType: input.kind.rawValue,
                quantity: input.quantity,
                reason: input.reason,
                notes: input.notes,
                unitCode: input.unitCode,
                requestId: input.requestId,
                allowNegativeStock: input.allowNegativeStock,
                warehouseId: input.warehouseId,
                reasonCode: input.reasonCode,
                unitCost: input.unitCost
            )
        )
        return AdminInventoryAdjustmentResult(
            balance: response.balance.toDomain(),
            movement: response.movement.toDomain(),
            idempotencyReplayed: response.idempotencyReplayed
        )
    }
    func downloadConsolidatedKardex(
        branchId: String, activityId: String, from: String, to: String,
        warehouseId: String?, movementType: String?
    ) async throws -> AdminInventoryDownloadedFile {
        let response = try await api.downloadConsolidatedKardex(
            branchId: branchId, activityId: activityId, from: from, to: to,
            warehouseId: warehouseId, movementType: movementType
        )
        let fallback = "nexo_kardex_operativo_todos_los_productos.csv"
        let fileName = Self.safeFileName(
            Self.fileName(fromContentDisposition: response.headerValue("Content-Disposition")) ?? fallback
        )
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("nexo-admin-inventory-exports", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let localURL = directory.appendingPathComponent("\(UUID().uuidString)-\(fileName)")
        try response.data.write(to: localURL, options: .atomic)
        return AdminInventoryDownloadedFile(
            localURL: localURL, fileName: fileName,
            contentType: response.headerValue("Content-Type") ?? "text/csv",
            sizeBytes: response.data.count
        )
    }
    private static func fileName(fromContentDisposition value: String?) -> String? {
        guard let value else { return nil }
        for part in value.split(separator: ";").map({ $0.trimmingCharacters(in: .whitespacesAndNewlines) }) {
            let lower = part.lowercased()
            if lower.hasPrefix("filename*=utf-8''") {
                let encoded = String(part.dropFirst("filename*=utf-8''".count))
                return encoded.removingPercentEncoding ?? encoded
            }
            if lower.hasPrefix("filename=") {
                return String(part.dropFirst("filename=".count))
                    .trimmingCharacters(in: CharacterSet(charactersIn: "\""))
            }
        }
        return nil
    }
    private static func safeFileName(_ value: String) -> String {
        let component = value.replacingOccurrences(of: "\\", with: "/")
            .split(separator: "/").last.map(String.init) ?? value
        let safe = component.replacingOccurrences(
            of: "[^A-Za-z0-9_.-]", with: "_", options: .regularExpression
        )
        return safe.isEmpty ? "nexo_kardex_operativo.csv" : safe
    }

}

private extension AdminInventoryStockItemDTO {
    func toDomain() -> AdminInventoryItem {
        AdminInventoryItem(
            id: id,
            catalogItemId: catalogItemId,
            branchId: branchId,
            warehouseId: warehouseId,
            name: name,
            sku: sku,
            barcode: barcode,
            catalogStatus: catalogStatus,
            quantityOnHand: quantityOnHand,
            quantityReserved: quantityReserved,
            quantityAvailable: quantityAvailable,
            quantityDamaged: quantityDamaged,
            quantityInTransit: quantityInTransit,
            stockUnit: stockUnit,
            lowStockThreshold: lowStockThreshold,
            status: status,
            tracksInventory: tracksInventory,
            hasStockProfile: hasStockProfile,
            allowNegativeStock: allowNegativeStock,
            blockSaleWhenInsufficientStock: blockSaleWhenInsufficientStock,
            averageCost: averageCost,
            lastCost: lastCost,
            referenceValue: referenceValue,
            lastMovementAt: lastMovementAt,
            updatedAt: updatedAt
        )
    }
}

private extension AdminInventoryMovementDTO {
    func toDomain() -> AdminInventoryMovement {
        AdminInventoryMovement(
            id: id,
            branchId: branchId,
            catalogItemId: catalogItemId,
            warehouseId: warehouseId,
            type: type,
            direction: direction,
            quantity: quantity,
            quantityDelta: quantityDelta,
            quantityBefore: quantityBefore,
            quantityAfter: quantityAfter,
            unitCode: unitCode,
            reason: reason,
            reasonCode: reasonCode,
            sourceType: sourceType,
            sourceId: sourceId,
            occurredAt: occurredAt,
            createdBy: createdBy
        )
    }
}
