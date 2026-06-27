//
//  MockAdminBusinessRepository.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import Foundation

final class MockAdminBusinessRepository: AdminBusinessRepository, @unchecked Sendable {
    private var business: AdminBusinessProfile
    private var activities: [AdminBusinessActivity]
    private var branches: [AdminBusinessBranch]
    private var emissionPoints: [AdminEmissionPoint]

    init(
        business: AdminBusinessProfile = MockAdminBusinessData.business,
        activities: [AdminBusinessActivity] = MockAdminBusinessData.activities,
        branches: [AdminBusinessBranch] = MockAdminBusinessData.branches,
        emissionPoints: [AdminEmissionPoint] = MockAdminBusinessData.emissionPoints
    ) {
        self.business = business
        self.activities = activities
        self.branches = branches
        self.emissionPoints = emissionPoints
    }

    func getOverview() async throws -> AdminBusinessOverview { makeOverview() }
    func getBusiness() async throws -> AdminBusinessProfile { business }
    func getReadiness() async throws -> AdminBusinessReadiness { makeReadiness() }
    func getRestaurantReadiness(branchId: String?) async throws -> AdminRestaurantReadiness { makeRestaurantReadiness(branchId: branchId) }

    func updateBusiness(_ input: UpdateAdminBusinessProfileInput) async throws -> AdminBusinessProfile {
        business = AdminBusinessProfile(
            id: business.id,
            countryCode: input.countryCode?.trimmedOrNil ?? business.countryCode,
            taxId: input.taxId?.trimmedOrNil ?? business.taxId,
            legalName: input.legalName?.trimmedOrNil ?? business.legalName,
            commercialName: input.commercialName?.trimmedOrNil ?? business.commercialName,
            status: business.status,
            ownerUserId: business.ownerUserId,
            defaultCurrency: input.defaultCurrency?.trimmedOrNil ?? business.defaultCurrency,
            timezone: input.timezone?.trimmedOrNil ?? business.timezone,
            createdAt: business.createdAt,
            updatedAt: "now",
            version: business.version + 1
        )
        return business
    }

    func listActivities() async throws -> [AdminBusinessActivity] { activities }

    func createActivity(_ input: SaveAdminActivityInput) async throws -> AdminBusinessActivity {
        let created = AdminBusinessActivity(
            id: "act_\(activities.count + 1)",
            organizationId: business.id,
            code: input.code,
            name: input.name,
            description: input.description,
            activityType: input.activityType,
            workflowMode: input.workflowMode,
            status: AdminActivityStatus(apiValue: input.status),
            requiresScheduling: input.requiresScheduling,
            tracksInventory: input.tracksInventory,
            allowsReceivables: input.allowsReceivables,
            sortOrder: input.sortOrder,
            createdAt: "now",
            updatedAt: nil
        )
        activities.append(created)
        return created
    }

    func updateActivity(_ input: SaveAdminActivityInput) async throws -> AdminBusinessActivity {
        guard let id = input.id, let index = activities.firstIndex(where: { $0.id == id }) else { throw AppError.notFound }
        let updated = AdminBusinessActivity(
            id: id,
            organizationId: activities[index].organizationId,
            code: input.code,
            name: input.name,
            description: input.description,
            activityType: input.activityType,
            workflowMode: input.workflowMode,
            status: AdminActivityStatus(apiValue: input.status),
            requiresScheduling: input.requiresScheduling,
            tracksInventory: input.tracksInventory,
            allowsReceivables: input.allowsReceivables,
            sortOrder: input.sortOrder,
            createdAt: activities[index].createdAt,
            updatedAt: "now"
        )
        activities[index] = updated
        return updated
    }

    func activateActivity(id: String, reason: String) async throws -> AdminBusinessActivity { try updateActivityStatus(id: id, status: .active) }
    func deactivateActivity(id: String, reason: String) async throws -> AdminBusinessActivity { try updateActivityStatus(id: id, status: .paused) }

    func listBranches() async throws -> [AdminBusinessBranch] { branches }

    func createBranch(_ input: SaveAdminBranchInput) async throws -> AdminBusinessBranch {
        let created = AdminBusinessBranch(
            id: "br_\(branches.count + 1)",
            organizationId: business.id,
            code: input.code,
            name: input.name,
            type: input.type,
            status: AdminBranchStatus(apiValue: input.status),
            location: input.location,
            businessHoursId: input.businessHoursId?.trimmedOrNil,
            createdAt: "now",
            updatedAt: nil
        )
        branches.append(created)
        return created
    }

    func updateBranch(_ input: SaveAdminBranchInput) async throws -> AdminBusinessBranch {
        guard let id = input.id, let index = branches.firstIndex(where: { $0.id == id }) else { throw AppError.notFound }
        let current = branches[index]
        let updated = AdminBusinessBranch(
            id: id,
            organizationId: current.organizationId,
            code: input.code,
            name: input.name,
            type: input.type,
            status: AdminBranchStatus(apiValue: input.status),
            location: input.clearLocation ? nil : input.location,
            businessHoursId: input.clearBusinessHoursId ? nil : input.businessHoursId?.trimmedOrNil,
            createdAt: current.createdAt,
            updatedAt: "now"
        )
        branches[index] = updated
        return updated
    }

    func activateBranch(id: String, reason: String) async throws -> AdminBusinessBranch { try updateBranchStatus(id: id, status: .active) }
    func deactivateBranch(id: String, reason: String) async throws -> AdminBusinessBranch { try updateBranchStatus(id: id, status: .inactive) }

    func listEmissionPoints() async throws -> [AdminEmissionPoint] { emissionPoints }

    func createEmissionPoint(_ input: SaveAdminEmissionPointInput) async throws -> AdminEmissionPoint {
        let created = AdminEmissionPoint(
            id: "ep_\(emissionPoints.count + 1)",
            organizationId: business.id,
            branchId: input.branchId,
            establishmentCode: input.establishmentCode.leftPaddedSriCode,
            emissionPointCode: input.emissionPointCode.leftPaddedSriCode,
            fullCode: "\(input.establishmentCode.leftPaddedSriCode)-\(input.emissionPointCode.leftPaddedSriCode)",
            displayName: input.displayName,
            status: AdminEmissionPointStatus(apiValue: input.status),
            createdAt: "now",
            updatedAt: nil
        )
        emissionPoints.append(created)
        return created
    }

    func updateEmissionPoint(_ input: SaveAdminEmissionPointInput) async throws -> AdminEmissionPoint {
        guard let id = input.id, let index = emissionPoints.firstIndex(where: { $0.id == id }) else { throw AppError.notFound }
        let updated = AdminEmissionPoint(
            id: id,
            organizationId: emissionPoints[index].organizationId,
            branchId: input.branchId,
            establishmentCode: input.establishmentCode.leftPaddedSriCode,
            emissionPointCode: input.emissionPointCode.leftPaddedSriCode,
            fullCode: "\(input.establishmentCode.leftPaddedSriCode)-\(input.emissionPointCode.leftPaddedSriCode)",
            displayName: input.displayName,
            status: AdminEmissionPointStatus(apiValue: input.status),
            createdAt: emissionPoints[index].createdAt,
            updatedAt: "now"
        )
        emissionPoints[index] = updated
        return updated
    }

    func activateEmissionPoint(id: String, reason: String) async throws -> AdminEmissionPoint { try updateEmissionPointStatus(id: id, status: .active) }
    func deactivateEmissionPoint(id: String, reason: String) async throws -> AdminEmissionPoint { try updateEmissionPointStatus(id: id, status: .inactive) }

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
                archivedActivities: activities.filter { $0.status == .archived }.count,
                totalBranches: branches.count,
                activeBranches: branches.filter { $0.status == .active }.count,
                inactiveBranches: branches.filter { $0.status == .inactive }.count,
                archivedBranches: branches.filter { $0.status == .archived }.count,
                totalEmissionPoints: emissionPoints.count,
                activeEmissionPoints: emissionPoints.filter { $0.status == .active }.count,
                inactiveEmissionPoints: emissionPoints.filter { $0.status == .inactive }.count,
                archivedEmissionPoints: emissionPoints.filter { $0.status == .archived }.count,
                readinessChecks: readiness.checks.count,
                readyChecks: readiness.checks.filter { $0.status == .ready }.count,
                warningChecks: readiness.checks.filter { $0.status == .warning }.count,
                blockedChecks: readiness.checks.filter { $0.status == .blocked }.count
            ),
            nextActions: readiness.checks.filter { $0.status != .ready && $0.action != nil }.map {
                AdminBusinessNextAction(code: $0.code, status: $0.status, required: $0.required, action: $0.action ?? "")
            },
            activities: activities,
            branches: branches,
            emissionPoints: emissionPoints
        )
    }

    private func makeReadiness() -> AdminBusinessReadiness {
        let checks = [
            AdminBusinessReadinessCheck(code: "BUSINESS_PROFILE", status: business.taxId.isEmpty ? .blocked : .ready, required: true, message: business.taxId.isEmpty ? "Falta RUC." : "Datos del negocio completos.", action: business.taxId.isEmpty ? "Completa datos del negocio." : nil),
            AdminBusinessReadinessCheck(code: "ACTIVE_ACTIVITY", status: activities.contains(where: { $0.status == .active }) ? .ready : .blocked, required: true, message: "Debe existir al menos una actividad activa.", action: activities.contains(where: { $0.status == .active }) ? nil : "Crea o activa una actividad."),
            AdminBusinessReadinessCheck(code: "ACTIVE_BRANCH", status: branches.contains(where: { $0.status == .active }) ? .ready : .blocked, required: true, message: "Debe existir al menos una sucursal activa.", action: branches.contains(where: { $0.status == .active }) ? nil : "Crea o activa una sucursal."),
            AdminBusinessReadinessCheck(code: "EMISSION_POINT", status: emissionPoints.contains(where: { $0.status == .active }) ? .ready : .warning, required: false, message: "Punto de emisión recomendado para documentos.", action: emissionPoints.contains(where: { $0.status == .active }) ? nil : "Configura un punto de emisión.")
        ]
        let ready = checks.filter(\.required).allSatisfy { $0.status == .ready }
        return AdminBusinessReadiness(organizationId: business.id, overallStatus: ready ? .ready : .blocked, ready: ready, generatedAt: "now", checks: checks)
    }

    private func makeRestaurantReadiness(branchId: String?) -> AdminRestaurantReadiness {
        AdminRestaurantReadiness(
            organizationId: business.id,
            branchId: branchId ?? branches.first?.id,
            status: .warn,
            overallStatus: .warn,
            ready: true,
            surface: "admin",
            capabilities: ["restaurant.menu_attributes", "restaurant.service_type", "restaurant.tables_optional"],
            supportMode: "support_only_no_table_operations",
            warnings: ["restaurant_tables_have_open_sessions"],
            blockers: [],
            checks: [
                AdminRestaurantReadinessCheck(code: "restaurant_active", status: .pass, message: "Restaurante v1 está activo para la organización.", blocking: true, details: [:]),
                AdminRestaurantReadinessCheck(code: "quick_sale_ready", status: .pass, message: "Venta rápida sigue como modo operativo base.", blocking: true, details: ["workMode": "quick_sale"]),
                AdminRestaurantReadinessCheck(code: "tables_optional_ready", status: .pass, message: "Mesas opcionales activas y con mesas configuradas.", blocking: false, details: ["total": "5"]),
                AdminRestaurantReadinessCheck(code: "restaurant_tables_have_open_sessions", status: .warn, message: "Hay mesas/sesiones abiertas; puede ser normal en operación.", blocking: false, details: ["openSessions": "1"]),
                AdminRestaurantReadinessCheck(code: "admin_readiness_support_only", status: .pass, message: "Admin readiness está declarado como superficie de diagnóstico.", blocking: false, details: ["supportMode": "support_only_no_table_operations"])
            ],
            components: [
                AdminRestaurantReadinessComponent(code: "business_context", status: .pass, path: "/api/v1/business/context", supportOnly: false, details: [:]),
                AdminRestaurantReadinessComponent(code: "vertical_readiness", status: .pass, path: "/api/v1/admin/verticals/restaurant/readiness", supportOnly: true, details: [:]),
                AdminRestaurantReadinessComponent(code: "tables_readiness", status: .pass, path: "/api/v1/admin/restaurant/tables/readiness", supportOnly: true, details: ["openSessions": "1"])
            ],
            tables: AdminRestaurantTableSummary(total: 5, available: 4, occupied: 1, disabled: 0, openSessions: 1),
            supportLinks: [
                AdminRestaurantSupportLink(label: "Business context", method: "GET", path: "/api/v1/business/context", supportOnly: false),
                AdminRestaurantSupportLink(label: "Restaurant tables readiness", method: "GET", path: "/api/v1/admin/restaurant/tables/readiness", supportOnly: true)
            ]
        )
    }

    private func updateActivityStatus(id: String, status: AdminActivityStatus) throws -> AdminBusinessActivity {
        guard let index = activities.firstIndex(where: { $0.id == id }) else { throw AppError.notFound }
        let current = activities[index]
        let updated = AdminBusinessActivity(
            id: current.id,
            organizationId: current.organizationId,
            code: current.code,
            name: current.name,
            description: current.description,
            activityType: current.activityType,
            workflowMode: current.workflowMode,
            status: status,
            requiresScheduling: current.requiresScheduling,
            tracksInventory: current.tracksInventory,
            allowsReceivables: current.allowsReceivables,
            sortOrder: current.sortOrder,
            createdAt: current.createdAt,
            updatedAt: "now"
        )
        activities[index] = updated
        return updated
    }

    private func updateBranchStatus(id: String, status: AdminBranchStatus) throws -> AdminBusinessBranch {
        guard let index = branches.firstIndex(where: { $0.id == id }) else { throw AppError.notFound }
        let current = branches[index]
        let updated = AdminBusinessBranch(
            id: current.id,
            organizationId: current.organizationId,
            code: current.code,
            name: current.name,
            type: current.type,
            status: status,
            location: current.location,
            businessHoursId: current.businessHoursId,
            createdAt: current.createdAt,
            updatedAt: "now"
        )
        branches[index] = updated
        return updated
    }

    private func updateEmissionPointStatus(id: String, status: AdminEmissionPointStatus) throws -> AdminEmissionPoint {
        guard let index = emissionPoints.firstIndex(where: { $0.id == id }) else { throw AppError.notFound }
        let current = emissionPoints[index]
        let updated = AdminEmissionPoint(
            id: current.id,
            organizationId: current.organizationId,
            branchId: current.branchId,
            establishmentCode: current.establishmentCode,
            emissionPointCode: current.emissionPointCode,
            fullCode: current.fullCode,
            displayName: current.displayName,
            status: status,
            createdAt: current.createdAt,
            updatedAt: "now"
        )
        emissionPoints[index] = updated
        return updated
    }
}

private extension String {
    var leftPaddedSriCode: String {
        let digits = filter(\.isNumber)
        return String(digits.suffix(3)).leftPadding(toLength: 3, withPad: "0")
    }

    func leftPadding(toLength: Int, withPad character: Character) -> String {
        if count >= toLength { return self }
        return String(repeating: String(character), count: toLength - count) + self
    }
}
