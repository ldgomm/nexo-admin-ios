//
//  AdminBusinessPackagesDiagnosticsPresentationTests.swift
//  Nexo AdminTests
//
//  Created by Nexo on 22/6/26.
//

import XCTest
@testable import Nexo_Admin

final class AdminBusinessPackagesDiagnosticsPresentationTests: XCTestCase {
    func testSeparatesRecommendedAvailableFutureAndRegulated() {
        let presentation = AdminBusinessPackagesDiagnosticsPresentation(response: .fixture())

        XCTAssertEqual(presentation.recommendedPresets.map(\.code), ["restaurant"])
        XCTAssertEqual(presentation.availablePresets.map(\.code), ["retail_general"])
        XCTAssertEqual(presentation.futurePresets.map(\.code), ["tourism_experiences"])
        XCTAssertEqual(Set(presentation.regulatedPresets.map(\.code)), ["health_office_future", "pharmacy_basic_future", "clinical_lab_future"])
    }

    func testRegulatedPresetsAreNotShownAsAvailableNow() {
        let response = AdminBusinessPackageCatalogResponse(
            capabilityPackages: [],
            verticalPresets: [
                .fixture(
                    code: "pharmacy_basic_future",
                    displayName: "Farmacia básica futura",
                    status: .availableNow,
                    regulated: true,
                    capabilityCodes: []
                )
            ],
            recommendedPresetCodes: [],
            activeModuleCodes: [],
            activityTypeCodes: [],
            warnings: []
        )

        let presentation = AdminBusinessPackagesDiagnosticsPresentation(response: response)

        XCTAssertEqual(presentation.availablePresets, [])
        XCTAssertEqual(presentation.regulatedPresets.map(\.code), ["pharmacy_basic_future"])
    }

    func testCapabilitiesAreGroupedByCategory() {
        let presentation = AdminBusinessPackagesDiagnosticsPresentation(response: .fixture())

        XCTAssertTrue(presentation.capabilitySections.contains { $0.title == "Core Operations" })
        XCTAssertTrue(presentation.capabilitySections.contains { $0.title == "Restaurant" })
        XCTAssertTrue(presentation.capabilitySections.contains { $0.title == "Regulated" })
        XCTAssertEqual(presentation.totalCapabilities, 4)
    }
}
