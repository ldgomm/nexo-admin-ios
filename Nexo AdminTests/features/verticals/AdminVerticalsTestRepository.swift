//
//  AdminVerticalsTestRepository.swift
//  Nexo AdminTests
//
//  Created by Nexo on 26/6/26.
//

import Foundation
@testable import Nexo_Admin

final class AdminVerticalsTestRepository: AdminVerticalsRepository, @unchecked Sendable {
    var packages: AdminVerticalPackagesResult
    var activations: AdminVerticalActivationsResult
    var readiness: AdminVerticalReadinessResult
    var error: Error?

    private(set) var listPackagesCount = 0
    private(set) var listActivationsCount = 0
    private(set) var readinessCount = 0
    private(set) var activateCount = 0
    private(set) var deactivateCount = 0
    private(set) var lastActivationRequest: AdminVerticalActivationRequest?
    private(set) var lastDeactivationReason: String?

    init(
        packages: AdminVerticalPackagesResult = .fixture(),
        activations: AdminVerticalActivationsResult = .fixture(active: false),
        readiness: AdminVerticalReadinessResult = .fixture(),
        error: Error? = nil
    ) {
        self.packages = packages
        self.activations = activations
        self.readiness = readiness
        self.error = error
    }

    func listPackages() async throws -> AdminVerticalPackagesResult {
        listPackagesCount += 1
        if let error { throw error }
        return packages
    }

    func listActivations() async throws -> AdminVerticalActivationsResult {
        listActivationsCount += 1
        if let error { throw error }
        return activations
    }

    func activate(verticalCode: String, request: AdminVerticalActivationRequest) async throws -> AdminVerticalActivation {
        activateCount += 1
        lastActivationRequest = request
        if let error { throw error }
        let activation = AdminVerticalActivation.fixture(active: true)
        activations = AdminVerticalActivationsResult(activations: [activation])
        return activation
    }

    func deactivate(verticalCode: String, reason: String) async throws -> AdminVerticalActivation {
        deactivateCount += 1
        lastDeactivationReason = reason
        if let error { throw error }
        let activation = AdminVerticalActivation.fixture(active: false)
        activations = AdminVerticalActivationsResult(activations: [activation])
        return activation
    }

    func readiness(verticalCode: String) async throws -> AdminVerticalReadinessResult {
        readinessCount += 1
        if let error { throw error }
        return readiness
    }


    func restaurantTablesReadiness(branchId: String?) async throws -> AdminRestaurantTablesReadiness {
        if let error { throw error }
        return .fixture(branchId: branchId ?? "br_staging_matriz")
    }
}

extension AdminVerticalPackagesResult {
    static func fixture() -> AdminVerticalPackagesResult {
        AdminVerticalPackagesResult(packages: [.restaurantFixture()])
    }
}

extension AdminVerticalActivationsResult {
    static func fixture(active: Bool) -> AdminVerticalActivationsResult {
        AdminVerticalActivationsResult(activations: active ? [.fixture(active: true)] : [])
    }
}

extension AdminVerticalPackage {
    static func restaurantFixture() -> AdminVerticalPackage {
        AdminVerticalPackage(
            packageId: "vertical_restaurant_v1",
            code: AdminVerticalCode.restaurant,
            displayName: "Restaurante v1",
            version: "1.0.0",
            status: .active,
            capabilities: [
                AdminVerticalCapability(code: "restaurant.menu_attributes", displayName: "Atributos de menú", description: "Catálogo con atributos restaurante", defaultEnabled: true),
                AdminVerticalCapability(code: "restaurant.service_type", displayName: "Tipo de servicio", description: "Dine-in/takeaway/evento", defaultEnabled: true),
                AdminVerticalCapability(code: "restaurant.event_service", displayName: "Eventos", description: "Eventos ligeros", defaultEnabled: true),
                AdminVerticalCapability(code: "restaurant.tables_optional", displayName: "Mesas", description: "Futuro 22F", defaultEnabled: false)
            ],
            workModes: [
                AdminVerticalWorkMode(code: "quick_sale", displayName: "Venta rápida", description: "Core", defaultMode: true),
                AdminVerticalWorkMode(code: "restaurant_counter", displayName: "Mostrador", description: "Futuro", defaultMode: false)
            ],
            surfaces: [
                AdminVerticalSurface(code: "admin.verticals.activation", description: "Activación Admin"),
                AdminVerticalSurface(code: "admin.verticals.readiness", description: "Readiness Admin")
            ],
            readinessChecks: [
                AdminVerticalReadinessDefinition(code: "catalog_has_items", displayName: "Catálogo", blocking: true)
            ],
            seedRefs: [
                AdminVerticalSeedRef(code: "altos_menu_seed", displayName: "Menú Altos", phase: "22H")
            ]
        )
    }
}

extension AdminVerticalActivation {
    static func fixture(active: Bool) -> AdminVerticalActivation {
        AdminVerticalActivation(
            id: "vertical_org_altos_del_murco_staging_restaurant",
            organizationId: "org_altos_del_murco_staging",
            verticalCode: AdminVerticalCode.restaurant,
            packageVersion: "1.0.0",
            status: active ? .active : .disabled,
            enabledCapabilities: active ? ["restaurant.event_service", "restaurant.menu_attributes", "restaurant.service_type"] : [],
            defaultWorkMode: "quick_sale",
            branchOverrides: [:],
            readinessSnapshot: AdminVerticalReadinessSnapshot(checkedAt: "2026-06-26T14:05:52Z", checks: AdminVerticalReadinessResult.fixture().checks),
            activatedAt: active ? "2026-06-26T14:05:52Z" : nil,
            activatedBy: active ? "usr_staging_owner" : nil,
            deactivatedAt: active ? nil : "2026-06-26T14:06:52Z",
            deactivatedBy: active ? nil : "usr_staging_owner",
            lastReason: "test",
            createdAt: "2026-06-26T14:05:52Z",
            updatedAt: "2026-06-26T14:05:52Z"
        )
    }
}

extension AdminVerticalReadinessResult {
    static func fixture() -> AdminVerticalReadinessResult {
        AdminVerticalReadinessResult(
            organizationId: "org_altos_del_murco_staging",
            verticalCode: AdminVerticalCode.restaurant,
            checks: [
                AdminVerticalReadinessCheck(code: "catalog_has_items", status: .pass, message: "Catálogo tiene items.", details: ["catalogItems": "12"]),
                AdminVerticalReadinessCheck(code: "roles_ready", status: .warn, message: "Revisar roles en 22B.", details: [:]),
                AdminVerticalReadinessCheck(code: "restaurant_seed_applied", status: .warn, message: "Seeds quedan para 22H.", details: ["phase": "22H"])
            ]
        )
    }
}

extension AdminRestaurantTablesReadiness {
    static func fixture(branchId: String = "br_staging_matriz") -> AdminRestaurantTablesReadiness {
        AdminRestaurantTablesReadiness(
            organizationId: "org_altos_del_murco_staging",
            branchId: branchId,
            restaurantTablesOptionalActive: true,
            businessUiReady: true,
            warnings: [],
            summary: AdminRestaurantTablesReadinessSummary(total: 2, available: 1, occupied: 1, disabled: 0, openSessions: 1),
            tables: [
                AdminRestaurantTableReadiness(
                    tableId: "tbl_1",
                    code: "M1",
                    name: "Mesa 1",
                    area: "Salón",
                    capacity: 4,
                    status: "available",
                    activeSessionId: nil,
                    linkedSaleId: nil,
                    openedAt: nil,
                    canOpen: true,
                    canClose: false,
                    canCancel: false,
                    canLinkSale: false,
                    reasonIfBlocked: nil
                ),
                AdminRestaurantTableReadiness(
                    tableId: "tbl_2",
                    code: "M2",
                    name: "Mesa 2",
                    area: "Salón",
                    capacity: 4,
                    status: "occupied",
                    activeSessionId: "ts_1",
                    linkedSaleId: "sale_1",
                    openedAt: "2026-06-26T20:00:00Z",
                    canOpen: false,
                    canClose: true,
                    canCancel: true,
                    canLinkSale: true,
                    reasonIfBlocked: nil
                )
            ]
        )
    }
}

