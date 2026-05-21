import Foundation

enum MockAdminTaxSriData {
    static let taxSettings = AdminTaxSettings(
        organizationId: "org_altos",
        regimeCode: "rimpe_emprendedor",
        regimeName: "RIMPE Emprendedor",
        defaultTaxProfileId: "tax_iva_15",
        defaultCurrency: "USD",
        obligatedToKeepAccounting: false,
        specialTaxpayerNumber: nil,
        rimpeLegend: "CONTRIBUYENTE RÉGIMEN RIMPE",
        withholdingAgentResolution: nil,
        updatedAt: "2026-05-21T00:00:00Z",
        version: 3
    )

    static let profiles = [
        AdminTaxProfile(id: "tax_iva_15", code: "iva_current_full", name: "IVA vigente", description: "Tarifa general vigente configurada desde backend", status: "active", taxName: "IVA", rate: 15, sriTaxCode: "2", sriRateCode: "4", legalBasis: "SRI vigente", effectiveFrom: "2026-01-01", effectiveTo: nil, editable: false),
        AdminTaxProfile(id: "tax_iva_0", code: "iva_0", name: "IVA 0%", description: "Bienes o servicios con tarifa 0%", status: "active", taxName: "IVA", rate: 0, sriTaxCode: "2", sriRateCode: "0", legalBasis: "SRI vigente", effectiveFrom: "2026-01-01", effectiveTo: nil, editable: false)
    ]

    static let signatures = [
        AdminElectronicSignature(id: "sig_main", organizationId: "org_altos", alias: "Firma principal", subject: "ALTOS DEL MURCO", issuer: "UANATACA", serialNumber: "ABC123", validFrom: "2026-01-01", validTo: "2027-01-01", status: "valid", isActive: true, expiresInDays: 225, lastValidatedAt: "2026-05-21T00:00:00Z", createdAt: "2026-05-01T00:00:00Z")
    ]

    static let sriSettings = AdminSriSettings(
        organizationId: "org_altos",
        environment: "test",
        emissionType: "normal",
        authorizationMode: "offline",
        establishmentCode: "001",
        emissionPointCode: "001",
        productionEnabled: false,
        productionRequestedAt: nil,
        productionEnabledAt: nil,
        lastReadinessStatus: "blocked",
        updatedAt: "2026-05-21T00:00:00Z"
    )

    static let readiness = AdminSriReadiness(
        status: "blocked",
        score: 78,
        checkedAt: "2026-05-21T00:00:00Z",
        items: [
            AdminSriReadinessItem(id: "tax", code: "tax_settings", title: "Configuración tributaria", description: "Régimen y perfiles cargados", status: "ok", required: true, actionLabel: nil),
            AdminSriReadinessItem(id: "signature", code: "active_signature", title: "Firma activa", description: "Existe firma electrónica activa y válida", status: "ok", required: true, actionLabel: nil),
            AdminSriReadinessItem(id: "homologation", code: "homologation", title: "Homologación", description: "Falta ejecutar homologación técnica", status: "blocked", required: true, actionLabel: "Ejecutar")
        ],
        blockers: ["Falta homologación técnica aprobada"],
        warnings: []
    )

    static let runs = [
        AdminSriHomologationRun(id: "homologation_run_001", status: "failed", environment: "test", startedAt: "2026-05-20T10:00:00Z", finishedAt: "2026-05-20T10:01:00Z", invoiceAccessKey: nil, authorizationNumber: nil, errorMessage: "Firma no validada en ambiente de pruebas", checklist: readiness.items)
    ]
}
