//
//  AdminInventoryAPI.swift
//  Nexo Admin
//
//  Created by José Ruiz on 29/7/26.
//

import Foundation

protocol AdminInventoryAPI: Sendable {
    func listInventory(branchId: String?, activityId: String, query: String?) async throws -> AdminInventoryStockResponseDTO
    func listMovements(branchId: String, catalogItemId: String, warehouseId: String?) async throws -> AdminInventoryMovementsResponseDTO
    func updatePolicy(catalogItemId: String, request: AdminInventoryPolicyRequestDTO) async throws -> AdminInventoryPolicyResponseDTO
    func adjust(_ request: AdminInventoryAdjustmentRequestDTO) async throws -> AdminInventoryAdjustmentResponseDTO
    func downloadConsolidatedKardex(
        branchId: String, activityId: String, from: String, to: String,
        warehouseId: String?, movementType: String?
    ) async throws -> APIDataResponse
}
extension AdminInventoryAPI {
    func downloadConsolidatedKardex(
        branchId: String, activityId: String, from: String, to: String,
        warehouseId: String?, movementType: String?
    ) async throws -> APIDataResponse {
        throw AppError.transport("El cliente de inventario no soporta descarga de archivos.")
    }
}

struct RemoteAdminInventoryAPI: AdminInventoryAPI {
    let apiClient: APIClient

    func listInventory(branchId: String?, activityId: String, query: String?) async throws -> AdminInventoryStockResponseDTO {
        var queryItems = [URLQueryItem(name: "limit", value: "100")]
        append(&queryItems, name: "branchId", value: branchId)
        append(&queryItems, name: "activityId", value: activityId)
        append(&queryItems, name: "q", value: query)
        return try await apiClient.send(
            APIEndpoint(
                path: "/api/v1/business/inventory/stock",
                method: .get,
                queryItems: queryItems,
                requiresOrganization: true
            )
        )
    }

    func listMovements(branchId: String, catalogItemId: String, warehouseId: String?) async throws -> AdminInventoryMovementsResponseDTO {
        var queryItems = [
            URLQueryItem(name: "branchId", value: branchId),
            URLQueryItem(name: "limit", value: "100"),
        ]
        append(&queryItems, name: "warehouseId", value: warehouseId)
        return try await apiClient.send(
            APIEndpoint(
                path: "/api/v1/business/inventory/stock/\(pathComponent(catalogItemId))/movements",
                method: .get,
                queryItems: queryItems,
                requiresOrganization: true
            )
        )
    }

    func updatePolicy(catalogItemId: String, request: AdminInventoryPolicyRequestDTO) async throws -> AdminInventoryPolicyResponseDTO {
        try await apiClient.send(
            APIEndpoint(
                path: "/api/v1/business/products/\(pathComponent(catalogItemId))/inventory-settings",
                method: .patch,
                requiresOrganization: true
            ),
            body: request
        )
    }

    func adjust(_ request: AdminInventoryAdjustmentRequestDTO) async throws -> AdminInventoryAdjustmentResponseDTO {
        try await apiClient.send(
            APIEndpoint(
                path: "/api/v1/business/inventory/adjustments",
                method: .post,
                requiresOrganization: true
            )
            .withIdempotencyKey(request.requestId),
            body: request
        )
    }

    func downloadConsolidatedKardex(
        branchId: String, activityId: String, from: String, to: String,
        warehouseId: String?, movementType: String?
    ) async throws -> APIDataResponse {
        guard let dataClient = apiClient as? any APIDataClient else {
            throw AppError.transport("El cliente HTTP no soporta descarga de archivos.")
        }
        var queryItems = [
            URLQueryItem(name: "branchId", value: branchId),
            URLQueryItem(name: "activityId", value: activityId),
            URLQueryItem(name: "from", value: from),
            URLQueryItem(name: "to", value: to),
            URLQueryItem(name: "timezone", value: "America/Guayaquil"),
        ]
        append(&queryItems, name: "warehouseId", value: warehouseId)
        append(&queryItems, name: "movementType", value: movementType)
        return try await dataClient.sendData(APIEndpoint(
            path: "/api/v1/business/exports/inventory/kardex.csv",
            method: .get, queryItems: queryItems, requiresOrganization: true
        ))
    }

    private func append(_ items: inout [URLQueryItem], name: String, value: String?) {
        guard let value = value?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty else { return }
        items.append(URLQueryItem(name: name, value: value))
    }

    private func pathComponent(_ raw: String) -> String {
        raw.addingPercentEncoding(withAllowedCharacters: .urlPathComponentAllowed) ?? raw
    }
}

struct AdminInventoryStockResponseDTO: Decodable, Sendable {
    let stock: [AdminInventoryStockItemDTO]
}

struct AdminInventoryStockItemDTO: Decodable, Sendable {
    let id: String
    let branchId: String?
    let itemId: String
    let catalogItemId: String
    let quantityOnHand: String
    let quantityReserved: String
    let quantityAvailable: String
    let stockUnit: String
    let stockMin: String
    let lowStockThreshold: String
    let status: String
    let tracksInventory: Bool
    let allowNegativeStock: Bool
    let blockSaleWhenInsufficientStock: Bool
    let lastMovementAt: String?
    let updatedAt: String?
    let warehouseId: String?
    let quantityDamaged: String
    let quantityInTransit: String
    let averageCost: String?
    let lastCost: String?
    let referenceValue: String?
    let name: String?
    let sku: String?
    let barcode: String?
    let catalogStatus: String?
    let hasStockProfile: Bool

    private enum CodingKeys: String, CodingKey {
        case id, branchId, itemId, catalogItemId, quantityOnHand, quantityReserved, quantityAvailable
        case stockUnit, stockMin, lowStockThreshold, status, tracksInventory, allowNegativeStock
        case blockSaleWhenInsufficientStock, lastMovementAt, updatedAt, warehouseId, quantityDamaged
        case quantityInTransit, averageCost, lastCost, referenceValue, name, sku, barcode, catalogStatus
        case hasStockProfile
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        branchId = try container.decodeIfPresent(String.self, forKey: .branchId)
        itemId = try container.decode(String.self, forKey: .itemId)
        catalogItemId = try container.decodeIfPresent(String.self, forKey: .catalogItemId) ?? itemId
        quantityOnHand = try container.decodeIfPresent(String.self, forKey: .quantityOnHand) ?? "0"
        quantityReserved = try container.decodeIfPresent(String.self, forKey: .quantityReserved) ?? "0"
        quantityAvailable = try container.decodeIfPresent(String.self, forKey: .quantityAvailable) ?? "0"
        stockUnit = try container.decodeIfPresent(String.self, forKey: .stockUnit) ?? "unit"
        stockMin = try container.decodeIfPresent(String.self, forKey: .stockMin) ?? "0"
        lowStockThreshold = try container.decodeIfPresent(String.self, forKey: .lowStockThreshold) ?? stockMin
        status = try container.decodeIfPresent(String.self, forKey: .status) ?? "untracked"
        tracksInventory = try container.decodeIfPresent(Bool.self, forKey: .tracksInventory) ?? false
        allowNegativeStock = try container.decodeIfPresent(Bool.self, forKey: .allowNegativeStock) ?? true
        blockSaleWhenInsufficientStock = try container.decodeIfPresent(Bool.self, forKey: .blockSaleWhenInsufficientStock) ?? false
        lastMovementAt = try container.decodeIfPresent(String.self, forKey: .lastMovementAt)
        updatedAt = try container.decodeIfPresent(String.self, forKey: .updatedAt)
        warehouseId = try container.decodeIfPresent(String.self, forKey: .warehouseId)
        quantityDamaged = try container.decodeIfPresent(String.self, forKey: .quantityDamaged) ?? "0"
        quantityInTransit = try container.decodeIfPresent(String.self, forKey: .quantityInTransit) ?? "0"
        averageCost = try container.decodeIfPresent(String.self, forKey: .averageCost)
        lastCost = try container.decodeIfPresent(String.self, forKey: .lastCost)
        referenceValue = try container.decodeIfPresent(String.self, forKey: .referenceValue)
        name = try container.decodeIfPresent(String.self, forKey: .name)
        sku = try container.decodeIfPresent(String.self, forKey: .sku)
        barcode = try container.decodeIfPresent(String.self, forKey: .barcode)
        catalogStatus = try container.decodeIfPresent(String.self, forKey: .catalogStatus)
        hasStockProfile = try container.decodeIfPresent(Bool.self, forKey: .hasStockProfile) ?? true
    }
}

struct AdminInventoryMovementsResponseDTO: Decodable, Sendable {
    let movements: [AdminInventoryMovementDTO]
}

struct AdminInventoryMovementDTO: Decodable, Sendable {
    let id: String
    let branchId: String
    let itemId: String
    let catalogItemId: String
    let movementType: String
    let type: String
    let direction: String
    let quantity: String
    let quantityDelta: String
    let quantityBefore: String?
    let quantityAfter: String?
    let unitCode: String
    let sourceType: String?
    let sourceId: String?
    let reason: String?
    let occurredAt: String
    let warehouseId: String?
    let reasonCode: String?
    let createdBy: String?

    private enum CodingKeys: String, CodingKey {
        case id, branchId, itemId, catalogItemId, movementType, type, direction, quantity, quantityDelta
        case quantityBefore, quantityAfter, unitCode, sourceType, sourceId, reason, occurredAt, warehouseId
        case reasonCode, createdBy
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        branchId = try container.decode(String.self, forKey: .branchId)
        itemId = try container.decode(String.self, forKey: .itemId)
        catalogItemId = try container.decodeIfPresent(String.self, forKey: .catalogItemId) ?? itemId
        movementType = try container.decodeIfPresent(String.self, forKey: .movementType) ?? "movement"
        type = try container.decodeIfPresent(String.self, forKey: .type) ?? movementType
        direction = try container.decodeIfPresent(String.self, forKey: .direction) ?? "neutral"
        quantity = try container.decodeIfPresent(String.self, forKey: .quantity) ?? "0"
        quantityDelta = try container.decodeIfPresent(String.self, forKey: .quantityDelta) ?? quantity
        quantityBefore = try container.decodeIfPresent(String.self, forKey: .quantityBefore)
        quantityAfter = try container.decodeIfPresent(String.self, forKey: .quantityAfter)
        unitCode = try container.decodeIfPresent(String.self, forKey: .unitCode) ?? "unit"
        sourceType = try container.decodeIfPresent(String.self, forKey: .sourceType)
        sourceId = try container.decodeIfPresent(String.self, forKey: .sourceId)
        reason = try container.decodeIfPresent(String.self, forKey: .reason)
        occurredAt = try container.decode(String.self, forKey: .occurredAt)
        warehouseId = try container.decodeIfPresent(String.self, forKey: .warehouseId)
        reasonCode = try container.decodeIfPresent(String.self, forKey: .reasonCode)
        createdBy = try container.decodeIfPresent(String.self, forKey: .createdBy)
    }
}

struct AdminInventoryPolicyRequestDTO: Encodable, Sendable {
    let tracksInventory: Bool
    let stockUnit: String
    let lowStockThreshold: String
    let allowNegativeStock: Bool
    let blockSaleWhenInsufficientStock: Bool
    let reason: String
    let defaultWarehouseId: String?
    let valuationMode: String?
    let referenceCost: String?
}

struct AdminInventoryPolicyResponseDTO: Decodable, Sendable {
    let itemId: String
    let catalogItemId: String
    let branchId: String?
    let tracksInventory: Bool
    let stockUnit: String
    let lowStockThreshold: String
    let allowNegativeStock: Bool
    let blockSaleWhenInsufficientStock: Bool
    let updatedAt: String
    let defaultWarehouseId: String?
    let valuationMode: String?
    let referenceCost: String?

    private enum CodingKeys: String, CodingKey {
        case itemId, catalogItemId, branchId, tracksInventory, stockUnit, stockMin, lowStockThreshold
        case allowNegativeStock, blockSaleWhenInsufficientStock, updatedAt, defaultWarehouseId
        case valuationMode, referenceCost
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        itemId = try container.decode(String.self, forKey: .itemId)
        catalogItemId = try container.decodeIfPresent(String.self, forKey: .catalogItemId) ?? itemId
        branchId = try container.decodeIfPresent(String.self, forKey: .branchId)
        tracksInventory = try container.decode(Bool.self, forKey: .tracksInventory)
        stockUnit = try container.decodeIfPresent(String.self, forKey: .stockUnit) ?? "unit"
        lowStockThreshold = try container.decodeIfPresent(String.self, forKey: .lowStockThreshold)
            ?? (try container.decodeIfPresent(String.self, forKey: .stockMin))
            ?? "0"
        allowNegativeStock = try container.decodeIfPresent(Bool.self, forKey: .allowNegativeStock) ?? true
        blockSaleWhenInsufficientStock = try container.decodeIfPresent(Bool.self, forKey: .blockSaleWhenInsufficientStock) ?? false
        updatedAt = try container.decode(String.self, forKey: .updatedAt)
        defaultWarehouseId = try container.decodeIfPresent(String.self, forKey: .defaultWarehouseId)
        valuationMode = try container.decodeIfPresent(String.self, forKey: .valuationMode)
        referenceCost = try container.decodeIfPresent(String.self, forKey: .referenceCost)
    }
}

struct AdminInventoryAdjustmentRequestDTO: Encodable, Sendable {
    let branchId: String
    let catalogItemId: String
    let adjustmentType: String
    let quantity: String
    let reason: String
    let notes: String?
    let unitCode: String
    let requestId: String
    let allowNegativeStock: Bool
    let warehouseId: String?
    let reasonCode: String?
    let unitCost: String?
}

struct AdminInventoryAdjustmentResponseDTO: Decodable, Sendable {
    let balance: AdminInventoryStockItemDTO
    let movement: AdminInventoryMovementDTO
    let idempotencyReplayed: Bool
}

private extension CharacterSet {
    static let urlPathComponentAllowed: CharacterSet = {
        var set = CharacterSet.urlPathAllowed
        set.remove(charactersIn: "/?#")
        return set
    }()
}
