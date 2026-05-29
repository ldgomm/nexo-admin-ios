//
//  AdminBusinessAppReadinessEvaluator.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import Foundation

struct AdminBusinessAppReadinessEvaluator: Sendable {
    var generatedAt: () -> Date = Date.init

    func evaluate(snapshot: AdminFoundationSnapshot) -> AdminBusinessAppReadinessReport {
        let context = snapshot.context
        let modules = Set(context.activeModules.map { $0.nexoNormalizedKey })
        let readinessByCode = snapshot.readinessByCode
        let blockedReadiness = snapshot.readiness.filter { !$0.ready && $0.active && (!$0.blockers.isEmpty || !$0.missingDependencies.isEmpty) }

        let sections = [
            AdminBusinessAppReadinessSection(
                id: "organization",
                title: "Organización y operación",
                checks: [
                    check(
                        id: "organization.active",
                        title: "Organización activa",
                        passed: !context.organization.id.isEmpty,
                        required: true,
                        detailReady: "Organización \(context.displayName) disponible en Business Context.",
                        detailBlocked: "Business Context no devolvió organización activa.",
                        actionTitle: "Revisar negocio",
                        destinationKey: "business"
                    ),
                    check(
                        id: "branch.active",
                        title: "Sucursal activa",
                        passed: context.activeBranch != nil,
                        required: true,
                        detailReady: "Sucursal activa: \(context.activeBranch?.name ?? "—").",
                        detailBlocked: "No existe sucursal activa para operar caja, ventas y documentos.",
                        actionTitle: "Configurar sucursal",
                        destinationKey: "branches"
                    ),
                    check(
                        id: "activities.active",
                        title: "Actividades configuradas",
                        passed: context.activities.contains { $0.status.nexoNormalizedKey == "active" },
                        required: true,
                        detailReady: "Hay \(context.activities.count) actividades devueltas por Business Context.",
                        detailBlocked: "Business App necesita al menos una actividad activa.",
                        actionTitle: "Configurar actividades",
                        destinationKey: "activities"
                    )
                ]
            ),
            AdminBusinessAppReadinessSection(
                id: "modules",
                title: "Módulos core",
                checks: requiredModuleChecks(
                    modules: modules,
                    readinessByCode: readinessByCode,
                    requiredModules: [
                        "core.sales",
                        "core.cash",
                        "core.catalog",
                        "core.customers",
                        "core.documents",
                        "core.receivables",
                        "core.reports"
                    ],
                    required: true
                )
            ),
            AdminBusinessAppReadinessSection(
                id: "foundations",
                title: "Foundations v2.4",
                checks: requiredModuleChecks(
                    modules: modules,
                    readinessByCode: readinessByCode,
                    requiredModules: [
                        "foundation.idempotency",
                        "foundation.catalog_revision",
                        "foundation.outbox",
                        "foundation.realtime_events"
                    ],
                    required: true
                ) + requiredModuleChecks(
                    modules: modules,
                    readinessByCode: readinessByCode,
                    requiredModules: [
                        "foundation.device_registry",
                        "foundation.observability",
                        "foundation.public_projection"
                    ],
                    required: false
                )
            ),
            AdminBusinessAppReadinessSection(
                id: "revisions",
                title: "Revisiones críticas",
                checks: [
                    check(
                        id: "catalog.revision",
                        title: "CatalogRevision disponible",
                        passed: context.catalogRevision.nexoIsUsefulRevision,
                        required: true,
                        detailReady: "Catalog revision actual: \(context.catalogRevision).",
                        detailBlocked: "Business App no debe vender con catálogo sin revision confiable.",
                        actionTitle: "Revisar catálogo",
                        destinationKey: "catalog"
                    ),
                    check(
                        id: "tax.revision",
                        title: "TaxConfigurationRevision disponible",
                        passed: context.taxConfigurationRevision.nexoIsUsefulRevision,
                        required: true,
                        detailReady: "Tax revision actual: \(context.taxConfigurationRevision).",
                        detailBlocked: "Business App necesita configuración tributaria versionada.",
                        actionTitle: "Revisar tributario",
                        destinationKey: "tax"
                    )
                ]
            ),
            AdminBusinessAppReadinessSection(
                id: "events",
                title: "Eventos y realtime progresivo",
                checks: [
                    check(
                        id: "realtime.sse-url",
                        title: "SSE URL preparada",
                        passed: !context.realtime.sseUrl.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                        required: false,
                        detailReady: "Endpoint configurado: \(context.realtime.sseUrl).",
                        detailBlocked: "Realtime puede esperar, pero el contrato debe quedar preparado.",
                        actionTitle: "Revisar foundation",
                        destinationKey: "modules"
                    ),
                    AdminBusinessAppReadinessCheck(
                        id: "readiness.module-blockers",
                        title: "Readiness modular sin bloqueos activos",
                        detail: blockedReadiness.isEmpty ? "No hay módulos activos con dependencias rotas." : "Hay \(blockedReadiness.count) módulos activos con bloqueos o dependencias faltantes.",
                        status: blockedReadiness.isEmpty ? .ready : .blocked,
                        required: true,
                        actionTitle: "Ver módulos",
                        destinationKey: "modules"
                    )
                ]
            )
        ]

        return AdminBusinessAppReadinessReport(
            organizationName: context.displayName,
            generatedAt: generatedAt(),
            sections: sections
        )
    }

    private func requiredModuleChecks(
        modules: Set<String>,
        readinessByCode: [String: AdminModuleReadinessItem],
        requiredModules: [String],
        required: Bool
    ) -> [AdminBusinessAppReadinessCheck] {
        requiredModules.map { moduleCode in
            let normalized = moduleCode.nexoNormalizedKey
            let readiness = readinessByCode[moduleCode] ?? readinessByCode[normalized]
            let active = modules.contains(normalized) || readiness?.active == true
            let ready = readiness?.ready ?? active
            let blockers = (readiness?.missingDependencies ?? []) + (readiness?.blockers ?? [])
            let warnings = readiness?.warnings ?? []
            let status: AdminBusinessAppReadinessStatus = {
                if active && ready && blockers.isEmpty { return warnings.isEmpty ? .ready : .warning }
                return required ? .blocked : .warning
            }()
            let detail: String = {
                if active && blockers.isEmpty { return warnings.isEmpty ? "Activo y listo." : warnings.joined(separator: " · ") }
                if !blockers.isEmpty { return blockers.joined(separator: " · ") }
                return "No activo en Business Context."
            }()
            return AdminBusinessAppReadinessCheck(
                id: "module.\(moduleCode)",
                title: moduleCode.nexoReadableKey,
                detail: detail,
                status: status,
                required: required,
                actionTitle: "Ver módulo",
                destinationKey: "modules"
            )
        }
    }

    private func check(
        id: String,
        title: String,
        passed: Bool,
        required: Bool,
        detailReady: String,
        detailBlocked: String,
        actionTitle: String?,
        destinationKey: String?
    ) -> AdminBusinessAppReadinessCheck {
        AdminBusinessAppReadinessCheck(
            id: id,
            title: title,
            detail: passed ? detailReady : detailBlocked,
            status: passed ? .ready : (required ? .blocked : .warning),
            required: required,
            actionTitle: actionTitle,
            destinationKey: destinationKey
        )
    }
}

extension String {
    var nexoIsUsefulRevision: Bool {
        let value = trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return !value.isEmpty && value != "unknown" && value != "none" && value != "null"
    }
}
