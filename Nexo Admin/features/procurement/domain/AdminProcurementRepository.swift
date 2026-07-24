//
//  AdminProcurementRepository.swift
//  Nexo Admin
//
//  27R.N.1B–N.4 — Procurement readiness, supplier, order and receipt review boundary.
//

import Foundation

protocol AdminProcurementRepository: Sendable {
    func getReadinessSnapshot(currency: String, branchId: String?) async throws -> AdminProcurementContractSnapshot
    func listSuppliers(query: AdminSupplierListQuery) async throws -> AdminSupplierPage
    func getSupplier(id: String) async throws -> AdminSupplier
    func createSupplier(_ input: AdminSupplierWriteInput) async throws -> AdminSupplierMutationResult
    func updateSupplier(id: String, input: AdminSupplierWriteInput) async throws -> AdminSupplierMutationResult
    func changeSupplierStatus(id: String, input: AdminSupplierStatusInput) async throws -> AdminSupplierMutationResult
    func listPurchaseOrders(query: AdminPurchaseOrderListQuery) async throws -> AdminPurchaseOrderPage
    func getPurchaseOrder(id: String) async throws -> AdminPurchaseOrder
    func listPurchaseReceipts(query: AdminPurchaseReceiptListQuery) async throws -> AdminPurchaseReceiptPage
    func getPurchaseReceipt(id: String) async throws -> AdminPurchaseReceipt
    func getPurchaseReceiptInventoryEffects(id: String) async throws -> AdminPurchaseReceiptInventoryEffects
}

struct RemoteAdminProcurementRepository: AdminProcurementRepository {
    let api: any AdminProcurementAPI

    func getReadinessSnapshot(
        currency: String,
        branchId: String?
    ) async throws -> AdminProcurementContractSnapshot {
        async let catalogTask = api.getReportCatalog()
        async let payableTask = api.getOpenOverduePayables(currency: currency, branchId: branchId)
        async let financeTask = api.getFinanceFacts(currency: currency, branchId: branchId)

        let catalog = try await catalogTask
        let payable = try await payableTask
        let finance = try await financeTask

        return AdminProcurementContractSnapshot(
            catalog: catalog.toDomain(),
            payableHealth: try payable.toDomain(),
            financeHealth: finance.toDomain()
        )
    }

    func listSuppliers(query: AdminSupplierListQuery) async throws -> AdminSupplierPage {
        try await api.listSuppliers(query.toDTO()).toDomain()
    }

    func getSupplier(id: String) async throws -> AdminSupplier {
        try await api.getSupplier(id: id).toDomain().supplier
    }

    func createSupplier(_ input: AdminSupplierWriteInput) async throws -> AdminSupplierMutationResult {
        try await api.createSupplier(
            input.toDTO(),
            idempotencyKey: input.idempotencyKey
        ).toDomain()
    }

    func updateSupplier(
        id: String,
        input: AdminSupplierWriteInput
    ) async throws -> AdminSupplierMutationResult {
        try await api.updateSupplier(id: id, request: input.toDTO()).toDomain()
    }

    func changeSupplierStatus(
        id: String,
        input: AdminSupplierStatusInput
    ) async throws -> AdminSupplierMutationResult {
        try await api.changeSupplierStatus(
            id: id,
            request: input.toDTO(),
            idempotencyKey: input.idempotencyKey
        ).toDomain()
    }

    func listPurchaseOrders(query: AdminPurchaseOrderListQuery) async throws -> AdminPurchaseOrderPage {
        try await api.listPurchaseOrders(query.toDTO()).toDomain()
    }

    func getPurchaseOrder(id: String) async throws -> AdminPurchaseOrder {
        try await api.getPurchaseOrder(id: id).toDomain().purchaseOrder
    }

    func listPurchaseReceipts(query: AdminPurchaseReceiptListQuery) async throws -> AdminPurchaseReceiptPage {
        try await api.listPurchaseReceipts(query.toDTO()).toDomain()
    }

    func getPurchaseReceipt(id: String) async throws -> AdminPurchaseReceipt {
        try await api.getPurchaseReceipt(id: id).toDomain().receipt
    }

    func getPurchaseReceiptInventoryEffects(
        id: String
    ) async throws -> AdminPurchaseReceiptInventoryEffects {
        try await api.getPurchaseReceiptInventoryEffects(id: id).toDomain()
    }
}
