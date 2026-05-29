//
//  MockAdminFoundationData.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import Foundation

enum MockAdminFoundationData {
    static let context = AdminBusinessContext(
        user: AdminBusinessContextUser(id: "usr_1", displayName: "Admin Nexo", email: "admin@nexo.test"),
        organization: AdminBusinessContextOrganization(
            id: "org_1",
            legalName: "Altos del Murco",
            commercialName: "Altos del Murco",
            countryCode: "EC",
            taxId: "9999999999999",
            defaultCurrency: "USD",
            timezone: "America/Guayaquil"
        ),
        branches: [
            AdminBusinessContextBranch(id: "br_1", code: "001", name: "Matriz", type: "main", status: "active", main: true)
        ],
        activeBranchId: "br_1",
        activities: [
            AdminBusinessContextActivity(id: "act_1", activityType: "restaurant", workflowMode: "quick_sale", status: "active", requiresScheduling: false),
            AdminBusinessContextActivity(id: "act_2", activityType: "tourism", workflowMode: "reservation", status: "active", requiresScheduling: true)
        ],
        activeModules: [
            "core.sales",
            "core.cash",
            "core.catalog",
            "core.customers",
            "core.documents",
            "core.receivables",
            "core.reports",
            "foundation.idempotency",
            "foundation.catalog_revision",
            "foundation.outbox",
            "foundation.realtime_events",
            "foundation.device_registry"
        ],
        effectivePermissions: [PermissionCatalog.all],
        catalogRevision: "catrev_20260527_001",
        taxConfigurationRevision: "taxrev_20260527_001",
        realtime: AdminBusinessContextRealtime(enabled: false, sseUrl: "/api/v1/realtime/events")
    )

    static let modules: [AdminResolvedModule] = context.activeModules.map {
        AdminResolvedModule(
            code: $0,
            name: $0.nexoReadableKey,
            category: $0.hasPrefix("core") ? "core" : "foundation",
            status: "enabled",
            active: true,
            source: "system",
            dependencies: [],
            compatibleActivityTypes: [],
            defaultWorkflowModes: [],
            permissions: [],
            screens: [],
            events: [],
            blockedReasons: []
        )
    }

    static let readiness: [AdminModuleReadinessItem] = context.activeModules.map {
        AdminModuleReadinessItem(
            code: $0,
            ready: true,
            active: true,
            missingDependencies: [],
            warnings: [],
            blockers: []
        )
    }
}
