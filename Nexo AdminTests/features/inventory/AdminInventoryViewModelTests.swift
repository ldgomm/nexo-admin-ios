//
//  AdminInventoryViewModelTests.swift
//  Nexo AdminTests
//
//  Created by José Ruiz on 29/7/26.
//

import Foundation
import XCTest
@testable import Nexo_Admin

@MainActor
class AdminInventoryViewModelTests: XCTestCase {
    func testQuantityPresentationRemovesBackendScaleWithoutLosingPrecision() {
        XCTAssertEqual(AdminInventoryNumberFormatter.format("3.000000"), "3")
        XCTAssertEqual(AdminInventoryNumberFormatter.format("3.500000"), "3,5")
        XCTAssertEqual(AdminInventoryNumberFormatter.format("0.000001"), "0,000001")
    }

    func testOverviewContractDecodesCatalogMetadataAndStockPolicy() throws {
        let data = Data(
            """
            {
              "stock": [{
                "id": "bal_1",
                "branchId": "br_main",
                "itemId": "item_1",
                "catalogItemId": "item_1",
                "quantityOnHand": "12.000000",
                "quantityReserved": "2.000000",
                "quantityAvailable": "10.000000",
                "stockUnit": "unit",
                "stockMin": "3.000000",
                "status": "available",
                "tracksInventory": true,
                "allowNegativeStock": false,
                "blockSaleWhenInsufficientStock": true,
                "name": "Cuy entero",
                "sku": "ADM-001",
                "hasStockProfile": true
              }]
            }
            """.utf8
        )

        let response = try JSONDecoder().decode(AdminInventoryStockResponseDTO.self, from: data)

        XCTAssertEqual(response.stock.first?.name, "Cuy entero")
        XCTAssertEqual(response.stock.first?.lowStockThreshold, "3.000000")
        XCTAssertEqual(response.stock.first?.allowNegativeStock, false)
        XCTAssertEqual(response.stock.first?.blockSaleWhenInsufficientStock, true)
    }

    func testLoadBuildsBranchScopedReadiness() async {
        let repository = AdminInventoryTestRepository(items: [
            inventoryItem(id: "item_1", name: "Cuy entero", quantity: "8", tracksInventory: true, hasStockProfile: true, status: "available"),
            inventoryItem(id: "item_2", name: "Medio cuy", quantity: "0", tracksInventory: false, hasStockProfile: false, status: "untracked"),
        ])
        let viewModel = makeViewModel(repository: repository)

        await viewModel.refresh()

        XCTAssertEqual(repository.listRequests.count, 1)
        XCTAssertEqual(repository.listRequests[0], "br_main")
        XCTAssertEqual(repository.activityRequests, ["retail_store"])
        XCTAssertEqual(viewModel.items.map(\.displayName), ["Cuy entero", "Medio cuy"])
        XCTAssertEqual(viewModel.readiness.total, 2)
        XCTAssertEqual(viewModel.readiness.tracked, 1)
        XCTAssertEqual(viewModel.readiness.unconfigured, 1)
        XCTAssertEqual(viewModel.readiness.statusTitle, "1 producto sin configurar")
        XCTAssertFalse(viewModel.readiness.isReady)
    }

    func testActiveRetailActivityRemainsAvailableWhenActivityPolicyDoesNotTrackInventory() async {
        let repository = AdminInventoryTestRepository(items: [])
        let viewModel = makeViewModel(repository: repository)

        await viewModel.refresh()

        XCTAssertEqual(viewModel.activities.map(\.id), ["retail_store"])
        XCTAssertEqual(viewModel.selectedActivityId, "retail_store")
        XCTAssertEqual(repository.activityRequests, ["retail_store"])
    }

    func testSearchAndStockFilterUseProductMetadataAndBackendBalance() async {
        let repository = AdminInventoryTestRepository(items: [
            inventoryItem(id: "item_1", name: "Cuy entero", sku: "ADM-001", quantity: "8", tracksInventory: true, hasStockProfile: true, status: "available"),
            inventoryItem(id: "item_2", name: "Medio cuy", sku: "ADM-002", quantity: "0", tracksInventory: true, hasStockProfile: true, status: "out_of_stock"),
        ])
        let viewModel = makeViewModel(repository: repository)
        await viewModel.refresh()

        viewModel.query = "medio"
        XCTAssertEqual(viewModel.visibleItems.map(\.catalogItemId), ["item_2"])
        XCTAssertTrue(viewModel.hasActiveFilters)
        XCTAssertEqual(viewModel.visibleResultTitle, "Productos · 1 de 2")
        XCTAssertEqual(
            viewModel.inventoryScopeMessage,
            "La salud resume los 2 productos de la actividad y sucursal; la consulta actual muestra 1."
        )
        XCTAssertEqual(viewModel.readiness.total, 2)

        viewModel.query = ""
        viewModel.selectedFilter = .outOfStock
        XCTAssertEqual(viewModel.visibleItems.map(\.catalogItemId), ["item_2"])

        viewModel.clearFilters()
        XCTAssertFalse(viewModel.hasActiveFilters)
        XCTAssertEqual(viewModel.visibleItems.count, 2)
        XCTAssertEqual(viewModel.visibleResultTitle, "Productos · 2")
    }

    func testPolicyRequiresAuditReasonBeforeCallingBackend() async {
        let repository = AdminInventoryTestRepository(items: [])
        let viewModel = makeViewModel(repository: repository)

        let saved = await viewModel.savePolicy(
            catalogItemId: "item_1",
            input: policyInput(reason: "   ")
        )

        XCTAssertFalse(saved)
        XCTAssertTrue(repository.policyRequests.isEmpty)
        XCTAssertEqual(viewModel.errorMessage, "Indica el motivo del cambio de política.")
    }

    func testPolicyPersistsStrictSaleGuardAndRefreshesInventory() async {
        let repository = AdminInventoryTestRepository(items: [
            inventoryItem(id: "item_1", name: "Cuy entero", quantity: "0", tracksInventory: false, hasStockProfile: false, status: "untracked"),
        ])
        let viewModel = makeViewModel(repository: repository)
        await viewModel.refresh()

        let saved = await viewModel.savePolicy(
            catalogItemId: "item_1",
            input: policyInput(reason: "Activar control para smoke")
        )

        XCTAssertTrue(saved)
        XCTAssertEqual(repository.policyRequests.count, 1)
        XCTAssertEqual(repository.policyRequests.first?.catalogItemId, "item_1")
        XCTAssertEqual(repository.policyRequests.first?.input.allowNegativeStock, false)
        XCTAssertEqual(repository.policyRequests.first?.input.blockSaleWhenInsufficientStock, true)
        XCTAssertEqual(repository.listRequests.count, 2)
    }

    func testAdjustmentUsesSelectedBranchAndPublishesAuditedMovement() async {
        let original = inventoryItem(
            id: "item_1",
            name: "Cuy entero",
            quantity: "0",
            tracksInventory: true,
            hasStockProfile: true,
            status: "out_of_stock"
        )
        let updated = inventoryItem(
            id: "item_1",
            name: "Cuy entero",
            quantity: "12",
            tracksInventory: true,
            hasStockProfile: true,
            status: "available"
        )
        let movement = inventoryMovement(catalogItemId: "item_1", before: "0", after: "12")
        let repository = AdminInventoryTestRepository(
            items: [original],
            adjustmentResult: AdminInventoryAdjustmentResult(
                balance: updated,
                movement: movement,
                idempotencyReplayed: false
            )
        )
        let viewModel = makeViewModel(repository: repository)
        await viewModel.refresh()

        let adjusted = await viewModel.adjust(
            AdminInventoryAdjustmentInput(
                branchId: viewModel.selectedBranchId,
                catalogItemId: "item_1",
                kind: .set,
                quantity: "12",
                reason: "Conteo físico inicial",
                notes: nil,
                unitCode: "unit",
                allowNegativeStock: false,
                warehouseId: nil,
                reasonCode: "ADMIN_MANUAL_ADJUSTMENT",
                unitCost: "6.50",
                requestId: "request_1"
            )
        )

        XCTAssertTrue(adjusted)
        XCTAssertEqual(repository.adjustmentRequests.first?.branchId, "br_main")
        XCTAssertEqual(repository.adjustmentRequests.first?.kind, .set)
        XCTAssertEqual(repository.adjustmentRequests.first?.requestId, "request_1")
        XCTAssertEqual(viewModel.movements(catalogItemId: "item_1").first?.balanceTransitionTitle, "0 unidades → 12 unidades")
        XCTAssertEqual(viewModel.successMessage, "Stock actualizado y movimiento auditado.")
    }

    func testMissingPermissionStopsBackendCalls() async {
        let repository = AdminInventoryTestRepository(items: [])
        let viewModel = AdminInventoryViewModel(
            repository: repository,
            branches: [branch],
            activities: [activity],
            permissions: []
        )

        await viewModel.refresh()

        XCTAssertTrue(repository.listRequests.isEmpty)
        XCTAssertEqual(viewModel.errorMessage, "Tu usuario no tiene permiso para consultar inventario.")
    }

    func testMissingInventoryActivityStopsUnscopedCatalogQuery() async {
        let repository = AdminInventoryTestRepository(items: [])
        let viewModel = AdminInventoryViewModel(
            repository: repository,
            branches: [branch],
            activities: [],
            permissions: [PermissionCatalog.inventoryView]
        )

        await viewModel.refresh()

        XCTAssertTrue(repository.listRequests.isEmpty)
        XCTAssertTrue(repository.activityRequests.isEmpty)
        XCTAssertEqual(
            viewModel.errorMessage,
            "Activa al menos una actividad antes de administrar inventario."
        )
    }

    private func makeViewModel(repository: AdminInventoryTestRepository) -> AdminInventoryViewModel {
        AdminInventoryViewModel(
            repository: repository,
            branches: [branch],
            activities: [activity],
            permissions: [PermissionCatalog.inventoryView, PermissionCatalog.inventoryAdjust]
        )
    }

    private var activity: AdminBusinessActivity {
        AdminBusinessActivity(
            id: "retail_store",
            organizationId: "org_1",
            code: "RETAIL",
            name: "Venta rápida",
            description: nil,
            activityType: "retail_store",
            workflowMode: "quick_sale",
            status: .active,
            requiresScheduling: false,
            tracksInventory: false,
            allowsReceivables: true,
            sortOrder: 0,
            createdAt: nil,
            updatedAt: nil
        )
    }

    private var branch: AdminBusinessBranch {
        AdminBusinessBranch(
            id: "br_main",
            organizationId: "org_1",
            code: "MATRIZ",
            name: "Matriz",
            type: "main",
            status: .active,
            location: nil,
            businessHoursId: nil,
            createdAt: nil,
            updatedAt: nil
        )
    }

    private func policyInput(reason: String) -> AdminInventoryPolicyInput {
        AdminInventoryPolicyInput(
            tracksInventory: true,
            stockUnit: "unit",
            lowStockThreshold: "2",
            allowNegativeStock: false,
            blockSaleWhenInsufficientStock: true,
            reason: reason,
            defaultWarehouseId: nil,
            valuationMode: "REFERENCE",
            referenceCost: "6.50"
        )
    }
}

private class AdminInventoryTestRepository: AdminInventoryRepository, @unchecked Sendable {
    var items: [AdminInventoryItem]
    var movements: [AdminInventoryMovement]
    var adjustmentResult: AdminInventoryAdjustmentResult?
    private(set) var listRequests: [String?] = []
    private(set) var activityRequests: [String] = []
    private(set) var policyRequests: [(catalogItemId: String, input: AdminInventoryPolicyInput)] = []
    private(set) var adjustmentRequests: [AdminInventoryAdjustmentInput] = []

    init(
        items: [AdminInventoryItem],
        movements: [AdminInventoryMovement] = [],
        adjustmentResult: AdminInventoryAdjustmentResult? = nil
    ) {
        self.items = items
        self.movements = movements
        self.adjustmentResult = adjustmentResult
    }

    func listInventory(branchId: String?, activityId: String, query: String?) async throws -> [AdminInventoryItem] {
        listRequests.append(branchId)
        activityRequests.append(activityId)
        return items
    }

    func listMovements(branchId: String, catalogItemId: String, warehouseId: String?) async throws -> [AdminInventoryMovement] {
        movements
    }

    func updatePolicy(catalogItemId: String, input: AdminInventoryPolicyInput) async throws {
        policyRequests.append((catalogItemId, input))
    }

    func adjust(_ input: AdminInventoryAdjustmentInput) async throws -> AdminInventoryAdjustmentResult {
        adjustmentRequests.append(input)
        guard let adjustmentResult else {
            throw AppError.server("Missing adjustment fixture")
        }
        items = [adjustmentResult.balance]
        movements = [adjustmentResult.movement]
        return adjustmentResult
    }
}

private func inventoryItem(
    id: String,
    name: String,
    sku: String? = nil,
    quantity: String,
    tracksInventory: Bool,
    hasStockProfile: Bool,
    status: String
) -> AdminInventoryItem {
    AdminInventoryItem(
        id: id,
        catalogItemId: id,
        branchId: hasStockProfile ? "br_main" : nil,
        warehouseId: nil,
        name: name,
        sku: sku,
        barcode: nil,
        catalogStatus: "active",
        quantityOnHand: quantity,
        quantityReserved: "0",
        quantityAvailable: quantity,
        quantityDamaged: "0",
        quantityInTransit: "0",
        stockUnit: "unit",
        lowStockThreshold: "2",
        status: status,
        tracksInventory: tracksInventory,
        hasStockProfile: hasStockProfile,
        allowNegativeStock: false,
        blockSaleWhenInsufficientStock: true,
        averageCost: "6.50",
        lastCost: "6.50",
        referenceValue: tracksInventory ? "52" : nil,
        lastMovementAt: nil,
        updatedAt: "2026-07-13T13:00:00Z"
    )
}

private func inventoryMovement(catalogItemId: String, before: String, after: String) -> AdminInventoryMovement {
    AdminInventoryMovement(
        id: "mov_1",
        branchId: "br_main",
        catalogItemId: catalogItemId,
        warehouseId: nil,
        type: "manual_adjustment",
        direction: "in",
        quantity: after,
        quantityDelta: after,
        quantityBefore: before,
        quantityAfter: after,
        unitCode: "unit",
        reason: "Conteo físico inicial",
        reasonCode: "ADMIN_MANUAL_ADJUSTMENT",
        sourceType: "admin_manual_adjustment",
        sourceId: "request_1",
        occurredAt: "2026-07-13T13:00:00Z",
        createdBy: "usr_admin"
    )
}
