//
//  AdminBusinessPackageCatalogResponseTests.swift
//  Nexo AdminTests
//
//  Created by Nexo on 22/6/26.
//

import XCTest
@testable import Nexo_Admin

final class AdminBusinessPackageCatalogResponseTests: XCTestCase {
    func testDecodesCompleteResponse() throws {
        let json = Data(
            """
            {
              "capabilityPackages": [
                {
                  "code": "capability.quick_sales",
                  "displayName": "Venta rápida",
                  "description": "Venta rápida core.",
                  "category": "CORE_OPERATIONS",
                  "status": "AVAILABLE_NOW",
                  "coreModuleCodes": ["core.sales"],
                  "recommendedPermissionCodes": ["sales.view"],
                  "dependsOnCapabilityCodes": [],
                  "readinessHints": [
                    {
                      "code": "cash_required",
                      "severity": "WARNING",
                      "title": "Caja recomendada",
                      "description": "Conviene tener caja activa.",
                      "blocking": false
                    }
                  ],
                  "notes": ["No duplica ventas."]
                }
              ],
              "verticalPresets": [
                {
                  "code": "restaurant",
                  "displayName": "Restaurante / comida preparada",
                  "description": "Para restaurantes pequeños.",
                  "targetBusinessTypes": ["restaurant"],
                  "capabilityCodes": ["capability.quick_sales"],
                  "defaultModuleCodes": ["core.sales"],
                  "optionalCapabilityCodes": ["capability.kitchen_optional"],
                  "status": "METADATA_ONLY",
                  "regulated": false,
                  "notes": ["Sin cocina full todavía."]
                }
              ],
              "recommendedPresetCodes": ["restaurant"],
              "activeModuleCodes": ["core.sales"],
              "activityTypeCodes": ["restaurant"],
              "warnings": ["Diagnóstico read-only"]
            }
            """.utf8
        )

        let response = try JSONDecoder().decode(AdminBusinessPackageCatalogResponseDTO.self, from: json)

        XCTAssertEqual(response.capabilityPackages.count, 1)
        XCTAssertEqual(response.capabilityPackages.first?.status, .availableNow)
        XCTAssertEqual(response.capabilityPackages.first?.readinessHints.first?.severity, .warning)
        XCTAssertEqual(response.verticalPresets.first?.status, .metadataOnly)
        XCTAssertEqual(response.recommendedPresetCodes, ["restaurant"])
        XCTAssertEqual(response.warnings, ["Diagnóstico read-only"])
    }

    func testUnknownStatusDoesNotBreakDecoding() throws {
        let json = Data(
            """
            {
              "capabilityPackages": [],
              "verticalPresets": [
                {
                  "code": "custom_future",
                  "displayName": "Custom future",
                  "description": "Custom",
                  "status": "EXPERIMENTAL_STATUS"
                }
              ]
            }
            """.utf8
        )

        let response = try JSONDecoder().decode(AdminBusinessPackageCatalogResponseDTO.self, from: json)

        XCTAssertEqual(response.verticalPresets.first?.status, .unknown("EXPERIMENTAL_STATUS"))
        XCTAssertEqual(response.verticalPresets.first?.regulated, false)
        XCTAssertEqual(response.verticalPresets.first?.notes, [])
        XCTAssertEqual(response.warnings, [])
    }

    func testMissingArraysDefaultToEmpty() throws {
        let json = Data("{}".utf8)

        let response = try JSONDecoder().decode(AdminBusinessPackageCatalogResponseDTO.self, from: json)

        XCTAssertEqual(response.capabilityPackages, [])
        XCTAssertEqual(response.verticalPresets, [])
        XCTAssertEqual(response.recommendedPresetCodes, [])
        XCTAssertEqual(response.activeModuleCodes, [])
        XCTAssertEqual(response.activityTypeCodes, [])
        XCTAssertEqual(response.warnings, [])
    }

    func testRegulatedFutureStatusDecodes() throws {
        let json = Data(
            """
            {
              "verticalPresets": [
                {
                  "code": "health_office_future",
                  "displayName": "Consultorio futuro",
                  "description": "Regulado",
                  "status": "REGULATED_FUTURE",
                  "regulated": true
                }
              ]
            }
            """.utf8
        )

        let response = try JSONDecoder().decode(AdminBusinessPackageCatalogResponseDTO.self, from: json)

        XCTAssertEqual(response.verticalPresets.first?.status, .regulatedFuture)
        XCTAssertEqual(response.verticalPresets.first?.regulated, true)
    }
}
