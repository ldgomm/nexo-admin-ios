//
//  AdminBusinessPackagesTestRepository.swift
//  Nexo AdminTests
//
//  Created by Nexo on 22/6/26.
//

import Foundation
@testable import Nexo_Admin

final class AdminBusinessPackagesTestRepository: AdminBusinessPackagesRepository, @unchecked Sendable {
    var result: AdminBusinessPackageCatalogResponse
    var error: Error?
    private(set) var loadCount = 0

    init(result: AdminBusinessPackageCatalogResponse = .fixture(), error: Error? = nil) {
        self.result = result
        self.error = error
    }

    func loadBusinessPackages() async throws -> AdminBusinessPackageCatalogResponse {
        loadCount += 1
        if let error { throw error }
        return result
    }
}

extension AdminBusinessPackageCatalogResponse {
    static func fixture() -> AdminBusinessPackageCatalogResponse {
        AdminBusinessPackageCatalogResponse(
            capabilityPackages: [
                .fixture(code: "capability.quick_sales", displayName: "Venta rápida", category: "core_operations", status: .availableNow),
                .fixture(code: "capability.customer_management", displayName: "Clientes", category: "core_operations", status: .availableNow),
                .fixture(code: "capability.menu", displayName: "Menú", category: "restaurant", status: .metadataOnly),
                .fixture(code: "capability.clinical_records_future", displayName: "Historias clínicas", category: "regulated", status: .regulatedFuture)
            ],
            verticalPresets: [
                .fixture(
                    code: "restaurant",
                    displayName: "Restaurante / comida preparada",
                    status: .metadataOnly,
                    regulated: false,
                    capabilityCodes: ["capability.quick_sales", "capability.customer_management", "capability.menu"]
                ),
                .fixture(
                    code: "retail_general",
                    displayName: "Tienda / comercio general",
                    status: .availableNow,
                    regulated: false,
                    capabilityCodes: ["capability.quick_sales"]
                ),
                .fixture(
                    code: "tourism_experiences",
                    displayName: "Turismo / experiencias",
                    status: .future,
                    regulated: false,
                    capabilityCodes: ["capability.reservations"]
                ),
                .fixture(
                    code: "health_office_future",
                    displayName: "Consultorio de salud futuro",
                    status: .regulatedFuture,
                    regulated: true,
                    capabilityCodes: ["capability.clinical_records_future"]
                ),
                .fixture(
                    code: "pharmacy_basic_future",
                    displayName: "Farmacia básica futura",
                    status: .regulatedFuture,
                    regulated: true,
                    capabilityCodes: ["capability.pharmacy_retail_future"]
                ),
                .fixture(
                    code: "clinical_lab_future",
                    displayName: "Laboratorio clínico futuro",
                    status: .regulatedFuture,
                    regulated: true,
                    capabilityCodes: ["capability.lab_orders_future"]
                )
            ],
            recommendedPresetCodes: ["restaurant"],
            activeModuleCodes: ["core.sales", "core.cash"],
            activityTypeCodes: ["restaurant"],
            warnings: ["tourism_experiences is metadata only"]
        )
    }
}

extension AdminCapabilityPackage {
    static func fixture(
        code: String,
        displayName: String,
        category: String,
        status: AdminBusinessPackageStatus
    ) -> AdminCapabilityPackage {
        AdminCapabilityPackage(
            code: code,
            displayName: displayName,
            description: "Descripción de \(displayName)",
            category: category,
            status: status,
            coreModuleCodes: ["core.sales"],
            recommendedPermissionCodes: ["sales.view"],
            dependsOnCapabilityCodes: [],
            readinessHints: [],
            notes: []
        )
    }
}

extension AdminVerticalPreset {
    static func fixture(
        code: String,
        displayName: String,
        status: AdminBusinessPackageStatus,
        regulated: Bool,
        capabilityCodes: [String]
    ) -> AdminVerticalPreset {
        AdminVerticalPreset(
            code: code,
            displayName: displayName,
            description: "Descripción de \(displayName)",
            targetBusinessTypes: [code],
            capabilityCodes: capabilityCodes,
            defaultModuleCodes: ["core.sales"],
            optionalCapabilityCodes: [],
            status: status,
            regulated: regulated,
            notes: regulated ? ["Requiere revisión normativa."] : []
        )
    }
}
