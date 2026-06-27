//
//  AdminBusinessTestRepository.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import Foundation
@testable import Nexo_Admin

final class AdminBusinessTestRepository: AdminBusinessRepository, @unchecked Sendable {
    var business = AdminBusinessProfile(
        id: "org_1",
        countryCode: "EC",
        taxId: "1790012345001",
        legalName: "Nexo Demo S.A.S.",
        commercialName: "Nexo Demo",
        status: .active,
        ownerUserId: "usr_1",
        defaultCurrency: "USD",
        timezone: "America/Guayaquil",
        createdAt: nil,
        updatedAt: nil,
        version: 1
    )
    var activities: [AdminBusinessActivity] = [
        AdminBusinessActivity(
            id: "act_1",
            organizationId: "org_1",
            code: "retail",
            name: "Tienda",
            description: nil,
            activityType: "retail",
            workflowMode: "quick_sale",
            status: .active,
            requiresScheduling: false,
            tracksInventory: true,
            allowsReceivables: true,
            sortOrder: 1,
            createdAt: nil,
            updatedAt: nil
        )
    ]
    var branches: [AdminBusinessBranch] = [
        AdminBusinessBranch(
            id: "br_1",
            organizationId: "org_1",
            code: "001",
            name: "Matriz",
            type: "main",
            status: .active,
            location: AdminBranchLocation(countryCode: "EC", province: "Pichincha", city: "Quito", sector: nil, addressLine: "Centro", latitude: nil, longitude: nil, privacyMode: "private"),
            businessHoursId: nil,
            createdAt: nil,
            updatedAt: nil
        )
    ]
    var emissionPoints: [AdminEmissionPoint] = []

    func getOverview() async throws -> AdminBusinessOverview { makeOverview() }
    func getBusiness() async throws -> AdminBusinessProfile { business }
    func getReadiness() async throws -> AdminBusinessReadiness { makeReadiness() }
    func getRestaurantReadiness(branchId: String?) async throws -> AdminRestaurantReadiness { makeRestaurantReadiness(branchId: branchId) }

    func updateBusiness(_ input: UpdateAdminBusinessProfileInput) async throws -> AdminBusinessProfile {
        business = AdminBusinessProfile(
            id: business.id,
            countryCode: input.countryCode ?? business.countryCode,
            taxId: input.taxId ?? business.taxId,
            legalName: input.legalName ?? business.legalName,
            commercialName: input.commercialName ?? business.commercialName,
            status: business.status,
            ownerUserId: business.ownerUserId,
            defaultCurrency: input.defaultCurrency ?? business.defaultCurrency,
            timezone: input.timezone ?? business.timezone,
            createdAt: business.createdAt,
            updatedAt: "now",
            version: business.version + 1
        )
        return business
    }

    func listActivities() async throws -> [AdminBusinessActivity] { activities }
    func createActivity(_ input: SaveAdminActivityInput) async throws -> AdminBusinessActivity {
        let created = AdminBusinessActivity(id: "act_new", organizationId: business.id, code: input.code, name: input.name, description: input.description, activityType: input.activityType, workflowMode: input.workflowMode, status: AdminActivityStatus(apiValue: input.status), requiresScheduling: input.requiresScheduling, tracksInventory: input.tracksInventory, allowsReceivables: input.allowsReceivables, sortOrder: input.sortOrder, createdAt: nil, updatedAt: nil)
        activities.append(created)
        return created
    }
    func updateActivity(_ input: SaveAdminActivityInput) async throws -> AdminBusinessActivity { try await createActivity(input) }
    func activateActivity(id: String, reason: String) async throws -> AdminBusinessActivity { try setActivity(id: id, status: .active) }
    func deactivateActivity(id: String, reason: String) async throws -> AdminBusinessActivity { try setActivity(id: id, status: .paused) }

    func listBranches() async throws -> [AdminBusinessBranch] { branches }
    func createBranch(_ input: SaveAdminBranchInput) async throws -> AdminBusinessBranch {
        let created = AdminBusinessBranch(id: "br_new", organizationId: business.id, code: input.code, name: input.name, type: input.type, status: AdminBranchStatus(apiValue: input.status), location: input.location, businessHoursId: input.businessHoursId, createdAt: nil, updatedAt: nil)
        branches.append(created)
        return created
    }
    func updateBranch(_ input: SaveAdminBranchInput) async throws -> AdminBusinessBranch { try await createBranch(input) }
    func activateBranch(id: String, reason: String) async throws -> AdminBusinessBranch { try setBranch(id: id, status: .active) }
    func deactivateBranch(id: String, reason: String) async throws -> AdminBusinessBranch { try setBranch(id: id, status: .inactive) }

    func listEmissionPoints() async throws -> [AdminEmissionPoint] { emissionPoints }
    func createEmissionPoint(_ input: SaveAdminEmissionPointInput) async throws -> AdminEmissionPoint {
        let created = AdminEmissionPoint(id: "ep_new", organizationId: business.id, branchId: input.branchId, establishmentCode: input.establishmentCode, emissionPointCode: input.emissionPointCode, fullCode: "\(input.establishmentCode)-\(input.emissionPointCode)", displayName: input.displayName, status: AdminEmissionPointStatus(apiValue: input.status), createdAt: nil, updatedAt: nil)
        emissionPoints.append(created)
        return created
    }
    func updateEmissionPoint(_ input: SaveAdminEmissionPointInput) async throws -> AdminEmissionPoint { try await createEmissionPoint(input) }
    func activateEmissionPoint(id: String, reason: String) async throws -> AdminEmissionPoint { try setEmissionPoint(id: id, status: .active) }
    func deactivateEmissionPoint(id: String, reason: String) async throws -> AdminEmissionPoint { try setEmissionPoint(id: id, status: .inactive) }

    private func makeReadiness() -> AdminBusinessReadiness {
        let checks = [
            AdminBusinessReadinessCheck(code: "BUSINESS_PROFILE", status: .ready, required: true, message: "OK", action: nil),
            AdminBusinessReadinessCheck(code: "ACTIVE_ACTIVITY", status: activities.contains { $0.status == .active } ? .ready : .blocked, required: true, message: "Activity", action: nil),
            AdminBusinessReadinessCheck(code: "ACTIVE_BRANCH", status: branches.contains { $0.status == .active } ? .ready : .blocked, required: true, message: "Branch", action: nil)
        ]
        return AdminBusinessReadiness(organizationId: business.id, overallStatus: checks.allSatisfy { $0.status == .ready } ? .ready : .blocked, ready: checks.allSatisfy { $0.status == .ready }, generatedAt: "now", checks: checks)
    }

    private func makeRestaurantReadiness(branchId: String?) -> AdminRestaurantReadiness {
        AdminRestaurantReadiness(
            organizationId: business.id,
            branchId: branchId ?? branches.first?.id,
            status: .pass,
            overallStatus: .pass,
            ready: true,
            surface: "admin",
            capabilities: ["restaurant.menu_attributes", "restaurant.service_type", "restaurant.tables_optional"],
            supportMode: "support_only_no_table_operations",
            warnings: [],
            blockers: [],
            checks: [
                AdminRestaurantReadinessCheck(code: "restaurant_active", status: .pass, message: "Restaurante v1 activo.", blocking: true, details: [:]),
                AdminRestaurantReadinessCheck(code: "quick_sale_ready", status: .pass, message: "Venta rápida operativa.", blocking: true, details: [:]),
                AdminRestaurantReadinessCheck(code: "admin_readiness_support_only", status: .pass, message: "Admin solo diagnóstico.", blocking: false, details: [:])
            ],
            components: [
                AdminRestaurantReadinessComponent(code: "business_context", status: .pass, path: "/api/v1/business/context", supportOnly: false, details: [:]),
                AdminRestaurantReadinessComponent(code: "tables_readiness", status: .pass, path: "/api/v1/admin/restaurant/tables/readiness", supportOnly: true, details: [:])
            ],
            tables: AdminRestaurantTableSummary(total: 5, available: 5, occupied: 0, disabled: 0, openSessions: 0),
            supportLinks: []
        )
    }

    private func makeOverview() -> AdminBusinessOverview {
        let readiness = makeReadiness()
        return AdminBusinessOverview(
            organizationId: business.id,
            overallStatus: readiness.overallStatus,
            ready: readiness.ready,
            generatedAt: readiness.generatedAt,
            business: business,
            readiness: readiness,
            counts: AdminBusinessFoundationCounts(
                totalActivities: activities.count,
                activeActivities: activities.filter { $0.status == .active }.count,
                pausedActivities: activities.filter { $0.status == .paused }.count,
                archivedActivities: 0,
                totalBranches: branches.count,
                activeBranches: branches.filter { $0.status == .active }.count,
                inactiveBranches: branches.filter { $0.status == .inactive }.count,
                archivedBranches: 0,
                totalEmissionPoints: emissionPoints.count,
                activeEmissionPoints: emissionPoints.filter { $0.status == .active }.count,
                inactiveEmissionPoints: emissionPoints.filter { $0.status == .inactive }.count,
                archivedEmissionPoints: 0,
                readinessChecks: readiness.checks.count,
                readyChecks: readiness.checks.filter { $0.status == .ready }.count,
                warningChecks: 0,
                blockedChecks: readiness.checks.filter { $0.status == .blocked }.count
            ),
            nextActions: [],
            activities: activities,
            branches: branches,
            emissionPoints: emissionPoints
        )
    }

    private func setActivity(id: String, status: AdminActivityStatus) throws -> AdminBusinessActivity {
        guard let index = activities.firstIndex(where: { $0.id == id }) else { throw AppError.notFound }
        let current = activities[index]
        let updated = AdminBusinessActivity(id: current.id, organizationId: current.organizationId, code: current.code, name: current.name, description: current.description, activityType: current.activityType, workflowMode: current.workflowMode, status: status, requiresScheduling: current.requiresScheduling, tracksInventory: current.tracksInventory, allowsReceivables: current.allowsReceivables, sortOrder: current.sortOrder, createdAt: current.createdAt, updatedAt: "now")
        activities[index] = updated
        return updated
    }

    private func setBranch(id: String, status: AdminBranchStatus) throws -> AdminBusinessBranch {
        guard let index = branches.firstIndex(where: { $0.id == id }) else { throw AppError.notFound }
        let current = branches[index]
        let updated = AdminBusinessBranch(id: current.id, organizationId: current.organizationId, code: current.code, name: current.name, type: current.type, status: status, location: current.location, businessHoursId: current.businessHoursId, createdAt: current.createdAt, updatedAt: "now")
        branches[index] = updated
        return updated
    }

    private func setEmissionPoint(id: String, status: AdminEmissionPointStatus) throws -> AdminEmissionPoint {
        guard let index = emissionPoints.firstIndex(where: { $0.id == id }) else { throw AppError.notFound }
        let current = emissionPoints[index]
        let updated = AdminEmissionPoint(id: current.id, organizationId: current.organizationId, branchId: current.branchId, establishmentCode: current.establishmentCode, emissionPointCode: current.emissionPointCode, fullCode: current.fullCode, displayName: current.displayName, status: status, createdAt: current.createdAt, updatedAt: "now")
        emissionPoints[index] = updated
        return updated
    }
}
