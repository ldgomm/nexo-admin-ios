//
//  AdminFoundationMapperTests.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import XCTest
@testable import Nexo_Admin

final class AdminFoundationMapperTests: XCTestCase {
    func testBusinessContextMapperPreservesCriticalRevisionsAndModules() {
        let dto = BusinessContextResponseDTO(
            user: BusinessContextUserResponseDTO(id: "usr_1", displayName: "Admin", email: "admin@nexo.test"),
            organization: BusinessContextOrganizationResponseDTO(id: "org_1", legalName: "Altos", commercialName: "Altos", countryCode: "EC", taxId: "9999999999999", defaultCurrency: "USD", timezone: "America/Guayaquil"),
            branches: [BusinessContextBranchResponseDTO(id: "br_1", code: "001", name: "Matriz", type: "main", status: "active", main: true)],
            activeBranchId: "br_1",
            activities: [BusinessContextActivityResponseDTO(id: "act_1", activityType: "restaurant", workflowMode: "quick_sale", status: "active", requiresScheduling: false)],
            activeModules: ["core.sales", "foundation.idempotency"],
            effectivePermissions: [PermissionCatalog.modulesView],
            catalogRevision: "catrev_1",
            taxConfigurationRevision: "taxrev_1",
            realtime: BusinessContextRealtimeResponseDTO(enabled: false, sseUrl: "/api/v1/realtime/events")
        )

        let domain = dto.toDomain()

        XCTAssertEqual(domain.catalogRevision, "catrev_1")
        XCTAssertEqual(domain.taxConfigurationRevision, "taxrev_1")
        XCTAssertTrue(domain.activeModuleSet.contains("core.sales"))
        XCTAssertEqual(domain.activeBranch?.id, "br_1")
    }
}
