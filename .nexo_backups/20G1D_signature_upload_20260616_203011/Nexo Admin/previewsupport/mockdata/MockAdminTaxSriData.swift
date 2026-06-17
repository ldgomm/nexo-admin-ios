//
//  MockAdminTaxSriData.swift
//  Nexo Admin
//
//  Created by José Ruiz on 2/6/26.
//

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
        version: 4
    )

    static let profiles = [
        AdminTaxProfile(
            id: "tax_iva_15",
            code: "iva_current_full",
            name: "IVA vigente",
            description: "Tarifa general vigente configurada desde backend",
            status: "active",
            taxName: "IVA",
            taxKind: "IVA",
            treatment: "IVA_FULL",
            rate: 15,
            sriTaxCode: "2",
            sriRateCode: "4",
            legalBasis: "SRI vigente",
            effectiveFrom: "2026-01-01",
            effectiveTo: nil,
            editable: false,
            source: "admin_tax_configuration",
            requiresTourismEligibility: false,
            requiresConstructionMaterialAuxiliaryCode: false,
            requiresActiveWindow: false,
            eligibilityWindowCode: nil
        ),
        AdminTaxProfile(
            id: "tax_iva_tourism_8",
            code: "altos_staging_iva_tourism_8",
            name: "IVA turismo 8%",
            description: "Tarifa reducida temporal para servicios turísticos habilitados. Depende de decreto, Registro de Turismo, LUAF/catastro y ventana vigente.",
            status: "active",
            taxName: "IVA",
            taxKind: "IVA",
            treatment: "IVA_REDUCED_TOURISM",
            rate: 8,
            sriTaxCode: "2",
            sriRateCode: "8",
            legalBasis: "Staging: IVA diferenciado turismo; producción requiere verificación normativa vigente",
            effectiveFrom: "2026-01-01",
            effectiveTo: nil,
            editable: false,
            source: "admin_tax_configuration",
            requiresTourismEligibility: true,
            requiresConstructionMaterialAuxiliaryCode: false,
            requiresActiveWindow: true,
            eligibilityWindowCode: "tourism_window_staging"
        ),
        AdminTaxProfile(
            id: "tax_iva_construction_5",
            code: "iva_construction_materials_5",
            name: "IVA materiales construcción 5%",
            description: "Tarifa reducida para materiales de construcción. No debe mostrarse al piloto restaurante si la actividad no aplica.",
            status: "inactive",
            taxName: "IVA",
            taxKind: "IVA",
            treatment: "IVA_REDUCED_CONSTRUCTION_MATERIALS",
            rate: 5,
            sriTaxCode: "2",
            sriRateCode: "8",
            legalBasis: "Staging: código SRI sujeto a ficha técnica vigente antes de producción",
            effectiveFrom: "2026-01-01",
            effectiveTo: nil,
            editable: false,
            source: "admin_tax_configuration",
            requiresTourismEligibility: false,
            requiresConstructionMaterialAuxiliaryCode: true,
            requiresActiveWindow: false,
            eligibilityWindowCode: nil
        ),
        AdminTaxProfile(
            id: "tax_iva_0",
            code: "iva_0",
            name: "IVA 0%",
            description: "Bienes o servicios con tarifa 0%",
            status: "active",
            taxName: "IVA",
            taxKind: "IVA",
            treatment: "IVA_ZERO",
            rate: 0,
            sriTaxCode: "2",
            sriRateCode: "0",
            legalBasis: "SRI vigente",
            effectiveFrom: "2026-01-01",
            effectiveTo: nil,
            editable: false,
            source: "admin_tax_configuration",
            requiresTourismEligibility: false,
            requiresConstructionMaterialAuxiliaryCode: false,
            requiresActiveWindow: false,
            eligibilityWindowCode: nil
        ),
        AdminTaxProfile(
            id: "tax_no_internal",
            code: "altos_staging_no_tax_internal",
            name: "Solo registro interno",
            description: "Uso operativo interno; no debe generar XML SRI ni tratarse como perfil tributario facturable.",
            status: "active",
            taxName: "Interno",
            taxKind: "INTERNAL",
            treatment: "NO_TAX_INTERNAL",
            rate: 0,
            sriTaxCode: "",
            sriRateCode: "",
            legalBasis: "Nexo interno",
            effectiveFrom: "2026-01-01",
            effectiveTo: nil,
            editable: false,
            source: "admin_tax_configuration",
            requiresTourismEligibility: false,
            requiresConstructionMaterialAuxiliaryCode: false,
            requiresActiveWindow: false,
            eligibilityWindowCode: nil
        )
    ]

    static let signatures = [
        AdminElectronicSignature(
            id: "sig_main",
            organizationId: "org_altos",
            alias: "Firma principal",
            subject: "ALTOS DEL MURCO",
            issuer: "UANATACA",
            serialNumber: "ABC123",
            validFrom: "2026-01-01",
            validTo: "2027-01-01",
            status: "VALID",
            effectiveStatus: "VALID",
            usable: true,
            expiresInDays: 225,
            expiresSoon: false,
            uploadedBy: "usr_admin",
            uploadedAt: "2026-05-01T00:00:00Z",
            lastUsedAt: nil,
            lastValidatedAt: "2026-05-21T00:00:00Z",
            createdAt: "2026-05-01T00:00:00Z"
        )
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
            AdminSriReadinessItem(id: "tax", code: "tax_settings", title: "Configuración tributaria", description: "Régimen y perfiles cargados, incluido IVA turismo 8% en staging", status: "ok", required: true, actionLabel: nil),
            AdminSriReadinessItem(id: "signature", code: "active_signature", title: "Firma activa", description: "Existe firma electrónica activa y válida", status: "ok", required: true, actionLabel: nil),
            AdminSriReadinessItem(id: "homologation", code: "homologation", title: "Homologación", description: "Falta ejecutar homologación técnica", status: "blocked", required: true, actionLabel: "Ejecutar")
        ],
        blockers: ["Falta homologación técnica aprobada"],
        warnings: ["IVA turismo 8% requiere validar decreto y elegibilidad antes de producción"]
    )

    static let runs = [
        AdminSriHomologationRun(id: "homologation_run_001", status: "failed", environment: "test", startedAt: "2026-05-20T10:00:00Z", finishedAt: "2026-05-20T10:01:00Z", invoiceAccessKey: nil, authorizationNumber: nil, errorMessage: "Firma no validada en ambiente de pruebas", checklist: readiness.items)
    ]
}
