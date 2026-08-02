//
//  AdminFinanceControlRepository.swift
//  Nexo Admin
//
//  Created by José Ruiz on 29/7/26.
//

import Foundation

protocol AdminFinanceControlRepository: Sendable {
    func loadSnapshot() async throws -> AdminFinanceControlSnapshot

    func reviewImportBatch(
        id: String,
        reason: String,
        expectedSourceRevision: String
    ) async throws -> AdminFinanceControlActionReceipt

    func reviewReconciliationException(
        id: String,
        reason: String,
        expectedSourceRevision: String
    ) async throws -> AdminFinanceControlActionReceipt

    func approveCutover(
        reason: String,
        expectedSourceRevision: String
    ) async throws -> AdminFinanceControlActionReceipt
}

enum AdminFinanceControlRepositoryError: Error, Equatable, Sendable {
    case runtimeEndpointUnavailable
    case invalidResponse
    case commandRejected
}
