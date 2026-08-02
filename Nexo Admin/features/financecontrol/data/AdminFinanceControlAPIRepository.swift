//
//  AdminFinanceControlAPIRepository.swift
//  Nexo Admin
//
//  Created by José Ruiz on 30/7/26.
//

import Foundation

final class AdminFinanceControlAPIRepository:
    AdminFinanceControlRepository,
    @unchecked Sendable
{
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func loadSnapshot() async throws -> AdminFinanceControlSnapshot {
        try await apiClient.send(
            APIEndpoint(
                path: "/api/v1/admin/finance/control/snapshot",
                method: .get,
                requiresOrganization: true
            )
        )
    }

    func reviewImportBatch(
        id: String,
        reason: String,
        expectedSourceRevision: String
    ) async throws -> AdminFinanceControlActionReceipt {
        try await sendCommand(
            path: "/api/v1/admin/finance/control/imports/\(id)/review",
            reason: reason,
            expectedSourceRevision: expectedSourceRevision
        )
    }

    func reviewReconciliationException(
        id: String,
        reason: String,
        expectedSourceRevision: String
    ) async throws -> AdminFinanceControlActionReceipt {
        try await sendCommand(
            path: "/api/v1/admin/finance/control/reconciliation-exceptions/\(id)/review",
            reason: reason,
            expectedSourceRevision: expectedSourceRevision
        )
    }

    func approveCutover(
        reason: String,
        expectedSourceRevision: String
    ) async throws -> AdminFinanceControlActionReceipt {
        try await sendCommand(
            path: "/api/v1/admin/finance/control/cutover/approve",
            reason: reason,
            expectedSourceRevision: expectedSourceRevision
        )
    }

    private func sendCommand(
        path: String,
        reason: String,
        expectedSourceRevision: String
    ) async throws -> AdminFinanceControlActionReceipt {
        let identity = APIRequestIdentity.new()
        let endpoint = APIEndpoint(
            path: path,
            method: .post,
            requiresOrganization: true,
            idempotencyKey: identity.idempotencyKey,
            correlationId: identity.correlationId
        )
        return try await apiClient.send(
            endpoint,
            body: AdminFinanceControlCommandBody(
                reason: reason,
                expectedSourceRevision: expectedSourceRevision
            )
        )
    }
}

private struct AdminFinanceControlCommandBody: Encodable, Sendable {
    let reason: String
    let expectedSourceRevision: String
}
