//
//  AdminBusinessRepository.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import Foundation

protocol AdminBusinessRepository: Sendable {
    func getOverview() async throws -> AdminBusinessOverview
    func getBusiness() async throws -> AdminBusinessProfile
    func updateBusiness(_ input: UpdateAdminBusinessProfileInput) async throws -> AdminBusinessProfile
    func getReadiness() async throws -> AdminBusinessReadiness
    func getRestaurantReadiness(branchId: String?) async throws -> AdminRestaurantReadiness

    func listActivities() async throws -> [AdminBusinessActivity]
    func createActivity(_ input: SaveAdminActivityInput) async throws -> AdminBusinessActivity
    func updateActivity(_ input: SaveAdminActivityInput) async throws -> AdminBusinessActivity
    func activateActivity(id: String, reason: String) async throws -> AdminBusinessActivity
    func deactivateActivity(id: String, reason: String) async throws -> AdminBusinessActivity

    func listBranches() async throws -> [AdminBusinessBranch]
    func createBranch(_ input: SaveAdminBranchInput) async throws -> AdminBusinessBranch
    func updateBranch(_ input: SaveAdminBranchInput) async throws -> AdminBusinessBranch
    func activateBranch(id: String, reason: String) async throws -> AdminBusinessBranch
    func deactivateBranch(id: String, reason: String) async throws -> AdminBusinessBranch

    func listEmissionPoints() async throws -> [AdminEmissionPoint]
    func createEmissionPoint(_ input: SaveAdminEmissionPointInput) async throws -> AdminEmissionPoint
    func updateEmissionPoint(_ input: SaveAdminEmissionPointInput) async throws -> AdminEmissionPoint
    func activateEmissionPoint(id: String, reason: String) async throws -> AdminEmissionPoint
    func deactivateEmissionPoint(id: String, reason: String) async throws -> AdminEmissionPoint
}
