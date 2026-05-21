//
//  AdminBusinessUseCases.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import Foundation

struct GetAdminBusinessOverviewUseCase: Sendable {
    let repository: any AdminBusinessRepository
    func execute() async throws -> AdminBusinessOverview { try await repository.getOverview() }
}

struct UpdateAdminBusinessProfileUseCase: Sendable {
    let repository: any AdminBusinessRepository
    func execute(_ input: UpdateAdminBusinessProfileInput) async throws -> AdminBusinessProfile {
        try await repository.updateBusiness(input)
    }
}

struct SaveAdminActivityUseCase: Sendable {
    let repository: any AdminBusinessRepository
    func execute(_ input: SaveAdminActivityInput) async throws -> AdminBusinessActivity {
        if input.id?.trimmedOrNil == nil { return try await repository.createActivity(input) }
        return try await repository.updateActivity(input)
    }
}

struct ChangeAdminActivityStatusUseCase: Sendable {
    let repository: any AdminBusinessRepository
    func activate(id: String, reason: String) async throws -> AdminBusinessActivity {
        try await repository.activateActivity(id: id, reason: reason)
    }
    func deactivate(id: String, reason: String) async throws -> AdminBusinessActivity {
        try await repository.deactivateActivity(id: id, reason: reason)
    }
}

struct SaveAdminBranchUseCase: Sendable {
    let repository: any AdminBusinessRepository
    func execute(_ input: SaveAdminBranchInput) async throws -> AdminBusinessBranch {
        if input.id?.trimmedOrNil == nil { return try await repository.createBranch(input) }
        return try await repository.updateBranch(input)
    }
}

struct ChangeAdminBranchStatusUseCase: Sendable {
    let repository: any AdminBusinessRepository
    func activate(id: String, reason: String) async throws -> AdminBusinessBranch {
        try await repository.activateBranch(id: id, reason: reason)
    }
    func deactivate(id: String, reason: String) async throws -> AdminBusinessBranch {
        try await repository.deactivateBranch(id: id, reason: reason)
    }
}

struct SaveAdminEmissionPointUseCase: Sendable {
    let repository: any AdminBusinessRepository
    func execute(_ input: SaveAdminEmissionPointInput) async throws -> AdminEmissionPoint {
        if input.id?.trimmedOrNil == nil { return try await repository.createEmissionPoint(input) }
        return try await repository.updateEmissionPoint(input)
    }
}

struct ChangeAdminEmissionPointStatusUseCase: Sendable {
    let repository: any AdminBusinessRepository
    func activate(id: String, reason: String) async throws -> AdminEmissionPoint {
        try await repository.activateEmissionPoint(id: id, reason: reason)
    }
    func deactivate(id: String, reason: String) async throws -> AdminEmissionPoint {
        try await repository.deactivateEmissionPoint(id: id, reason: reason)
    }
}
