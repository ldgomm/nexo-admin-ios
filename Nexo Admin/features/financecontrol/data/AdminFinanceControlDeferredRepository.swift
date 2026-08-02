//
//  AdminFinanceControlDeferredRepository.swift
//  Nexo Admin
//
//  Created by José Ruiz on 29/7/26.
//
//  Runtime finance endpoints are wired during 28R.P. Until then this
//  repository fails closed and never fabricates administrative finance data.
//

import Foundation

struct AdminFinanceControlDeferredRepository: AdminFinanceControlRepository {
    func loadSnapshot() async throws -> AdminFinanceControlSnapshot {
        throw AdminFinanceControlRepositoryError.runtimeEndpointUnavailable
    }

    func reviewImportBatch(
        id: String,
        reason: String,
        expectedSourceRevision: String
    ) async throws -> AdminFinanceControlActionReceipt {
        throw AdminFinanceControlRepositoryError.runtimeEndpointUnavailable
    }

    func reviewReconciliationException(
        id: String,
        reason: String,
        expectedSourceRevision: String
    ) async throws -> AdminFinanceControlActionReceipt {
        throw AdminFinanceControlRepositoryError.runtimeEndpointUnavailable
    }

    func approveCutover(
        reason: String,
        expectedSourceRevision: String
    ) async throws -> AdminFinanceControlActionReceipt {
        throw AdminFinanceControlRepositoryError.runtimeEndpointUnavailable
    }
}
