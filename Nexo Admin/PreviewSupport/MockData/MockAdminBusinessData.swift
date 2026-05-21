//
//  MockAdminBusinessData.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import Foundation

enum MockAdminBusinessData {
    static let business = AdminBusinessProfile(
        id: "org_1",
        countryCode: "EC",
        taxId: "1790012345001",
        legalName: "Altos del Murco S.A.S.",
        commercialName: "Altos del Murco",
        status: .active,
        ownerUserId: "usr_owner",
        defaultCurrency: "USD",
        timezone: "America/Guayaquil",
        createdAt: "2026-05-01T00:00:00Z",
        updatedAt: "2026-05-20T00:00:00Z",
        version: 4
    )

    static let activities = [
        AdminBusinessActivity(
            id: "act_restaurant",
            organizationId: "org_1",
            code: "restaurant",
            name: "Restaurante",
            description: "Venta de comida y bebidas.",
            activityType: "restaurant",
            workflowMode: "order",
            status: .active,
            requiresScheduling: false,
            tracksInventory: true,
            allowsReceivables: true,
            sortOrder: 1,
            createdAt: nil,
            updatedAt: nil
        ),
        AdminBusinessActivity(
            id: "act_tourism",
            organizationId: "org_1",
            code: "experiences",
            name: "Experiencias",
            description: "Reservas de actividades turísticas.",
            activityType: "tourism",
            workflowMode: "reservation",
            status: .active,
            requiresScheduling: true,
            tracksInventory: false,
            allowsReceivables: true,
            sortOrder: 2,
            createdAt: nil,
            updatedAt: nil
        )
    ]

    static let branches = [
        AdminBusinessBranch(
            id: "br_main",
            organizationId: "org_1",
            code: "001",
            name: "Matriz Tambillo",
            type: "main",
            status: .active,
            location: AdminBranchLocation(
                countryCode: "EC",
                province: "Pichincha",
                city: "Mejía",
                sector: "Tambillo",
                addressLine: "Vía al Pasochoa",
                latitude: -0.4052,
                longitude: -78.5481,
                privacyMode: "approximate_public"
            ),
            businessHoursId: "hours_weekend",
            createdAt: nil,
            updatedAt: nil
        )
    ]

    static let emissionPoints = [
        AdminEmissionPoint(
            id: "ep_001_001",
            organizationId: "org_1",
            branchId: "br_main",
            establishmentCode: "001",
            emissionPointCode: "001",
            fullCode: "001-001",
            displayName: "Caja principal",
            status: .active,
            createdAt: nil,
            updatedAt: nil
        )
    ]

    static let readiness = AdminBusinessReadiness(
        organizationId: "org_1",
        overallStatus: .ready,
        ready: true,
        generatedAt: "2026-05-21T00:00:00Z",
        checks: [
            AdminBusinessReadinessCheck(code: "BUSINESS_PROFILE", status: .ready, required: true, message: "Datos del negocio completos.", action: nil),
            AdminBusinessReadinessCheck(code: "ACTIVE_ACTIVITY", status: .ready, required: true, message: "Existe al menos una actividad activa.", action: nil),
            AdminBusinessReadinessCheck(code: "ACTIVE_BRANCH", status: .ready, required: true, message: "Existe al menos una sucursal activa.", action: nil),
            AdminBusinessReadinessCheck(code: "EMISSION_POINT", status: .ready, required: false, message: "Punto de emisión configurado.", action: nil)
        ]
    )

    static var overview: AdminBusinessOverview {
        AdminBusinessOverview(
            organizationId: "org_1",
            overallStatus: .ready,
            ready: true,
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
            nextActions: [],
            activities: activities,
            branches: branches,
            emissionPoints: emissionPoints
        )
    }
}
