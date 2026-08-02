//
//  AdminInventoryRepository.swift
//  Nexo Admin
//
//  Created by José Ruiz on 29/7/26.
//

import Foundation

protocol AdminInventoryRepository: Sendable {
    func listInventory(branchId: String?, activityId: String, query: String?) async throws -> [AdminInventoryItem]
    func listMovements(branchId: String, catalogItemId: String, warehouseId: String?) async throws -> [AdminInventoryMovement]
    func updatePolicy(catalogItemId: String, input: AdminInventoryPolicyInput) async throws
    func adjust(_ input: AdminInventoryAdjustmentInput) async throws -> AdminInventoryAdjustmentResult
    func downloadConsolidatedKardex(
        branchId: String, activityId: String, from: String, to: String,
        warehouseId: String?, movementType: String?
    ) async throws -> AdminInventoryDownloadedFile
}
extension AdminInventoryRepository {
    func downloadConsolidatedKardex(
        branchId: String, activityId: String, from: String, to: String,
        warehouseId: String?, movementType: String?
    ) async throws -> AdminInventoryDownloadedFile {
        throw AppError.transport("La exportación consolidada de Kardex no está disponible.")
    }
}
struct AdminInventoryDownloadedFile: Identifiable, Equatable, Sendable {
    let id: String
    let localURL: URL
    let fileName: String
    let contentType: String
    let sizeBytes: Int
    init(localURL: URL, fileName: String, contentType: String, sizeBytes: Int) {
        id = localURL.absoluteString
        self.localURL = localURL
        self.fileName = fileName
        self.contentType = contentType
        self.sizeBytes = sizeBytes
    }
}
