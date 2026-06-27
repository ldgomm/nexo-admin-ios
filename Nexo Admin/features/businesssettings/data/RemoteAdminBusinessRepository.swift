//
//  RemoteAdminBusinessRepository.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import Foundation

final class RemoteAdminBusinessRepository: AdminBusinessRepository, @unchecked Sendable {
    private let api: AdminBusinessAPI

    init(api: AdminBusinessAPI) {
        self.api = api
    }

    func getOverview() async throws -> AdminBusinessOverview {
        try await AdminBusinessMapper.map(api.getOverview())
    }

    func getBusiness() async throws -> AdminBusinessProfile {
        try await AdminBusinessMapper.map(api.getBusiness().business)
    }

    func updateBusiness(_ input: UpdateAdminBusinessProfileInput) async throws -> AdminBusinessProfile {
        try await AdminBusinessMapper.map(api.updateBusiness(AdminBusinessMapper.request(input)).business)
    }

    func getReadiness() async throws -> AdminBusinessReadiness {
        try await AdminBusinessMapper.map(api.getReadiness())
    }

    func getRestaurantReadiness(branchId: String?) async throws -> AdminRestaurantReadiness {
        try await AdminBusinessMapper.map(api.getRestaurantReadiness(branchId: branchId))
    }

    func listActivities() async throws -> [AdminBusinessActivity] {
        try await api.listActivities().activities.map(AdminBusinessMapper.map(_:))
    }

    func createActivity(_ input: SaveAdminActivityInput) async throws -> AdminBusinessActivity {
        try await AdminBusinessMapper.map(api.createActivity(AdminBusinessMapper.createRequest(input)).activity)
    }

    func updateActivity(_ input: SaveAdminActivityInput) async throws -> AdminBusinessActivity {
        guard let id = input.id?.trimmedOrNil else { throw AppError.validation("Activity id is required.") }
        return try await AdminBusinessMapper.map(api.updateActivity(id: id, request: AdminBusinessMapper.updateRequest(input)).activity)
    }

    func activateActivity(id: String, reason: String) async throws -> AdminBusinessActivity {
        try await AdminBusinessMapper.map(api.activateActivity(id: id, request: AdminBusinessActionRequestDTO(reason: reason)).activity)
    }

    func deactivateActivity(id: String, reason: String) async throws -> AdminBusinessActivity {
        try await AdminBusinessMapper.map(api.deactivateActivity(id: id, request: AdminBusinessActionRequestDTO(reason: reason)).activity)
    }

    func listBranches() async throws -> [AdminBusinessBranch] {
        try await api.listBranches().branches.map(AdminBusinessMapper.map(_:))
    }

    func createBranch(_ input: SaveAdminBranchInput) async throws -> AdminBusinessBranch {
        try await AdminBusinessMapper.map(api.createBranch(AdminBusinessMapper.createRequest(input)).branch)
    }

    func updateBranch(_ input: SaveAdminBranchInput) async throws -> AdminBusinessBranch {
        guard let id = input.id?.trimmedOrNil else { throw AppError.validation("Branch id is required.") }
        return try await AdminBusinessMapper.map(api.updateBranch(id: id, request: AdminBusinessMapper.updateRequest(input)).branch)
    }

    func activateBranch(id: String, reason: String) async throws -> AdminBusinessBranch {
        try await AdminBusinessMapper.map(api.activateBranch(id: id, request: AdminBusinessActionRequestDTO(reason: reason)).branch)
    }

    func deactivateBranch(id: String, reason: String) async throws -> AdminBusinessBranch {
        try await AdminBusinessMapper.map(api.deactivateBranch(id: id, request: AdminBusinessActionRequestDTO(reason: reason)).branch)
    }

    func listEmissionPoints() async throws -> [AdminEmissionPoint] {
        try await api.listEmissionPoints().emissionPoints.map(AdminBusinessMapper.map(_:))
    }

    func createEmissionPoint(_ input: SaveAdminEmissionPointInput) async throws -> AdminEmissionPoint {
        try await AdminBusinessMapper.map(api.createEmissionPoint(AdminBusinessMapper.createRequest(input)).emissionPoint)
    }

    func updateEmissionPoint(_ input: SaveAdminEmissionPointInput) async throws -> AdminEmissionPoint {
        guard let id = input.id?.trimmedOrNil else { throw AppError.validation("Emission point id is required.") }
        return try await AdminBusinessMapper.map(api.updateEmissionPoint(id: id, request: AdminBusinessMapper.updateRequest(input)).emissionPoint)
    }

    func activateEmissionPoint(id: String, reason: String) async throws -> AdminEmissionPoint {
        try await AdminBusinessMapper.map(api.activateEmissionPoint(id: id, request: AdminBusinessActionRequestDTO(reason: reason)).emissionPoint)
    }

    func deactivateEmissionPoint(id: String, reason: String) async throws -> AdminEmissionPoint {
        try await AdminBusinessMapper.map(api.deactivateEmissionPoint(id: id, request: AdminBusinessActionRequestDTO(reason: reason)).emissionPoint)
    }
}
