//
//  AdminProcurementReadinessUseCases.swift
//  Nexo Admin
//
//  27R.N.1B — Evidence-driven procurement readiness evaluation.
//

import Foundation

struct GetAdminProcurementReadinessReportUseCase: Sendable {
    let foundationRepository: any AdminFoundationRepository
    let procurementRepository: any AdminProcurementRepository
    let evaluator: AdminProcurementReadinessEvaluator

    init(
        foundationRepository: any AdminFoundationRepository,
        procurementRepository: any AdminProcurementRepository,
        evaluator: AdminProcurementReadinessEvaluator = AdminProcurementReadinessEvaluator()
    ) {
        self.foundationRepository = foundationRepository
        self.procurementRepository = procurementRepository
        self.evaluator = evaluator
    }

    func execute() async throws -> AdminProcurementReadinessReport {
        let foundation = try await GetAdminFoundationSnapshotUseCase(repository: foundationRepository).execute()
        let currency = foundation.context.organization.defaultCurrency
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()

        guard currency.count == 3 else {
            throw AppError.validation("La moneda predeterminada del negocio no es válida para consultar compras.")
        }

        guard evaluator.canQueryBackend(foundation: foundation) else {
            return evaluator.evaluate(foundation: foundation, contracts: nil)
        }

        let contracts = try await procurementRepository.getReadinessSnapshot(
            currency: currency,
            branchId: foundation.context.activeBranch?.id
        )
        return evaluator.evaluate(foundation: foundation, contracts: contracts)
    }
}

struct AdminProcurementReadinessEvaluator: Sendable {
    static let requiredReportTypes: Set<String> = [
        "purchases_by_supplier",
        "open_purchase_orders",
        "pending_late_receipts",
        "partial_receipt_variance",
        "supplier_document_register",
        "open_overdue_payables",
        "payments_by_supplier",
        "supplier_cost_trend",
        "procurement_evidence",
        "supplier_statement"
    ]

    var generatedAt: @Sendable () -> Date = { Date() }

    func evaluate(
        foundation: AdminFoundationSnapshot,
        contracts: AdminProcurementContractSnapshot?
    ) -> AdminProcurementReadinessReport {
        let context = foundation.context
        let currency = context.organization.defaultCurrency.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        let permissions = PermissionSet(context.effectivePermissions)

        let sections = [
            AdminProcurementReadinessSection(
                id: "configuration",
                title: "Configuración operativa",
                checks: [
                    requiredCheck(
                        id: "organization.active",
                        title: "Organización activa",
                        passed: !context.organization.id.isEmpty,
                        ready: "\(context.displayName) está disponible en Business Context.",
                        blocked: "Business Context no devolvió una organización activa."
                    ),
                    requiredCheck(
                        id: "branch.active",
                        title: "Sucursal activa",
                        passed: context.activeBranch != nil,
                        ready: "Sucursal: \(context.activeBranch?.name ?? "—").",
                        blocked: "La consulta de compras necesita una sucursal activa."
                    ),
                    requiredCheck(
                        id: "currency.default",
                        title: "Moneda operativa",
                        passed: currency.count == 3,
                        ready: "Moneda backend: \(currency).",
                        blocked: "La moneda predeterminada no cumple el contrato ISO-4217 esperado."
                    ),
                    moduleCheck(code: "module.purchases", title: "Módulo de compras", foundation: foundation),
                    moduleCheck(code: "core.reports", title: "Módulo de reportes", foundation: foundation)
                ]
            ),
            AdminProcurementReadinessSection(
                id: "backend",
                title: "Contratos y reconciliación backend",
                checks: contracts.map {
                    backendChecks(
                        contracts: $0,
                        currency: currency,
                        organizationId: context.organization.id,
                        branchId: context.activeBranch?.id
                    )
                } ?? [
                    requiredCheck(
                        id: "backend.available",
                        title: "Contratos de compras disponibles",
                        passed: false,
                        ready: "Los contratos backend están disponibles.",
                        blocked: "Activa y deja listos module.purchases y core.reports antes de consultar saldos o hechos financieros."
                    )
                ]
            ),
            AdminProcurementReadinessSection(
                id: "permissions",
                title: "Cobertura del administrador actual",
                checks: permissionChecks(permissions: permissions)
            ),
            AdminProcurementReadinessSection(
                id: "boundary",
                title: "Frontera financiera",
                checks: [
                    requiredCheck(
                        id: "accounting.not-generated",
                        title: "Sin asientos contables automáticos",
                        passed: contracts.map {
                            !$0.catalog.accountingEntriesGenerated && !$0.financeHealth.accountingEntriesGenerated
                        } ?? false,
                        ready: "El backend declara hechos operativos para revisión futura; no genera contabilidad oficial.",
                        blocked: contracts == nil
                            ? "No se puede confirmar la frontera financiera hasta que los módulos estén listos."
                            : "El contrato cambió y pretende generar asientos dentro de 27R."
                    )
                ]
            )
        ]

        return AdminProcurementReadinessReport(
            organizationName: context.displayName,
            branchName: context.activeBranch?.name ?? "Sin sucursal",
            currency: currency,
            generatedAt: generatedAt(),
            backendGeneratedAt: contracts?.financeHealth.generatedAt ?? "No consultado",
            reportCount: contracts?.catalog.reports.count,
            matchingPayableCount: contracts?.payableHealth.matchingRowCount,
            openPayableBalance: contracts?.payableHealth.openBalance,
            financeFactCount: contracts?.financeHealth.matchingFactCount,
            sections: sections
        )
    }

    func canQueryBackend(foundation: AdminFoundationSnapshot) -> Bool {
        foundation.context.activeBranch != nil &&
        moduleIsReady(code: "module.purchases", foundation: foundation) &&
        moduleIsReady(code: "core.reports", foundation: foundation)
    }

    private func backendChecks(
        contracts: AdminProcurementContractSnapshot,
        currency: String,
        organizationId: String,
        branchId: String?
    ) -> [AdminProcurementReadinessCheck] {
        let catalogTypes = Set(contracts.catalog.reports.map(\.reportType))
        let exactImplementations = contracts.catalog.reports.allSatisfy {
            $0.implementation == ($0.reportType == "supplier_statement" ? "27R.J.v1" : "27R.L.v1")
        }
        let exactAdminPaths = contracts.catalog.reports.allSatisfy { entry in
            let expectedJSON = entry.reportType == "supplier_statement"
                ? "/api/v1/admin/procurement/suppliers/{supplierId}/statement"
                : "/api/v1/admin/procurement/reports/\(entry.reportType)"
            let expectedCSV = entry.reportType == "supplier_statement"
                ? "/api/v1/admin/procurement/suppliers/{supplierId}/statement.csv"
                : "/api/v1/admin/procurement/reports/\(entry.reportType)/export.csv"
            return entry.jsonPath == expectedJSON && entry.csvPath == expectedCSV
        }
        let payableChecks = contracts.payableHealth.reconciliationChecks
        let financeChecks = contracts.financeHealth.reconciliationChecks

        return [
            requiredCheck(
                id: "catalog.version",
                title: "Contrato de reportes v1",
                passed: contracts.catalog.contractVersion == 1,
                ready: "Contrato backend 27R.L.v1 disponible.",
                blocked: "La versión del catálogo no coincide con el contrato aceptado."
            ),
            requiredCheck(
                id: "catalog.complete",
                title: "Catálogo operativo completo",
                passed: catalogTypes == Self.requiredReportTypes &&
                    contracts.catalog.reports.count == Self.requiredReportTypes.count &&
                    exactImplementations,
                ready: "Nueve reportes operativos y estado de cuenta están disponibles.",
                blocked: "Faltan reportes o aparecieron tipos no reconocidos."
            ),
            requiredCheck(
                id: "catalog.admin-paths",
                title: "Rutas Admin aisladas",
                passed: exactAdminPaths &&
                    contracts.catalog.financeFactsPath == "/api/v1/admin/procurement/finance-facts" &&
                    contracts.catalog.financeFactsCsvPath == "/api/v1/admin/procurement/finance-facts/export.csv",
                ready: "La superficie usa exclusivamente el namespace Admin de compras.",
                blocked: "El catálogo expone una ruta fuera del contrato Admin esperado."
            ),
            requiredCheck(
                id: "payables.contract",
                title: "Salud de cuentas por pagar",
                passed: contracts.payableHealth.reportType == "open_overdue_payables" &&
                    contracts.payableHealth.branchId == branchId &&
                    contracts.payableHealth.currency == currency &&
                    contracts.payableHealth.totalAmount.currency == currency &&
                    contracts.payableHealth.openBalance.currency == currency &&
                    contracts.payableHealth.matchingRowCount >= 0,
                ready: "Conteo y saldo abierto provienen del reporte backend canónico.",
                blocked: "El reporte de cuentas por pagar no coincide con moneda o tipo esperado."
            ),
            requiredCheck(
                id: "payables.reconciled",
                title: "Cuentas por pagar reconciliadas",
                passed: !payableChecks.isEmpty && payableChecks.allSatisfy(\.passed),
                ready: "Todas las comprobaciones del reporte backend pasaron.",
                blocked: "El backend reportó una diferencia o no devolvió comprobaciones de reconciliación."
            ),
            requiredCheck(
                id: "finance-facts.contract",
                title: "FinanceSourceFact disponible",
                passed: contracts.financeHealth.organizationId == organizationId &&
                    contracts.financeHealth.branchId == branchId &&
                    contracts.financeHealth.currency == currency &&
                    contracts.financeHealth.matchingFactCount >= 0,
                ready: "Los hechos financieros versionados están disponibles para el futuro handoff.",
                blocked: "La página de hechos no coincide con organización o moneda."
            ),
            requiredCheck(
                id: "finance-facts.reconciled",
                title: "FinanceSourceFact reconciliado",
                passed: !financeChecks.isEmpty && financeChecks.allSatisfy(\.passed),
                ready: "Las comprobaciones backend de hechos financieros pasaron.",
                blocked: "Los hechos financieros no reconciliaron o no devolvieron comprobaciones."
            )
        ]
    }

    private func permissionChecks(permissions: PermissionSet) -> [AdminProcurementReadinessCheck] {
        [
            permissionCheck(id: "reports", title: "Readiness y reportes", permissions: permissions, required: [PermissionCatalog.reportsDashboardView]),
            permissionCheck(id: "suppliers", title: "Proveedores", permissions: permissions, required: [PermissionCatalog.suppliersView]),
            permissionCheck(id: "orders", title: "Órdenes de compra", permissions: permissions, required: [PermissionCatalog.purchaseOrdersView]),
            permissionCheck(id: "receipts", title: "Recepciones", permissions: permissions, required: [PermissionCatalog.purchaseReceiptsView]),
            permissionCheck(id: "documents", title: "Documentos de proveedor", permissions: permissions, required: [PermissionCatalog.supplierDocumentsView]),
            permissionCheck(id: "payables", title: "Cuentas por pagar y vencimientos", permissions: permissions, required: [PermissionCatalog.payablesView, PermissionCatalog.payablesAgingView]),
            permissionCheck(id: "payments", title: "Pagos a proveedores", permissions: permissions, required: [PermissionCatalog.supplierPaymentsView]),
            permissionCheck(id: "statements", title: "Estados de cuenta", permissions: permissions, required: [PermissionCatalog.supplierStatementsView]),
            permissionCheck(id: "audit", title: "Evidencia y auditoría", permissions: permissions, required: [PermissionCatalog.procurementAuditView]),
            permissionCheck(id: "exports", title: "Exportaciones", permissions: permissions, required: [PermissionCatalog.reportsExport, PermissionCatalog.supplierStatementsExport])
        ]
    }

    private func moduleCheck(
        code: String,
        title: String,
        foundation: AdminFoundationSnapshot
    ) -> AdminProcurementReadinessCheck {
        let status = moduleStatus(code: code, foundation: foundation)
        return requiredCheck(
            id: "module.\(code)",
            title: title,
            passed: status.ready,
            ready: "\(code) está activo, listo y sin dependencias rotas.",
            blocked: status.problems.isEmpty
                ? "\(code) no está activo o no tiene readiness confirmado."
                : status.problems.joined(separator: " · ")
        )
    }

    private func moduleIsReady(code: String, foundation: AdminFoundationSnapshot) -> Bool {
        moduleStatus(code: code, foundation: foundation).ready
    }

    private func moduleStatus(
        code: String,
        foundation: AdminFoundationSnapshot
    ) -> (ready: Bool, problems: [String]) {
        let normalized = code.nexoNormalizedKey
        let module = foundation.modules.first { $0.code.nexoNormalizedKey == normalized }
        let readiness = foundation.readiness.first { $0.code.nexoNormalizedKey == normalized }
        let active = foundation.context.activeModules.contains { $0.nexoNormalizedKey == normalized } || module?.active == true
        let problems = (module?.blockedReasons ?? []) +
            (readiness?.missingDependencies ?? []) +
            (readiness?.blockers ?? [])
        return (active && readiness?.ready == true && problems.isEmpty, problems)
    }

    private func permissionCheck(
        id: String,
        title: String,
        permissions: PermissionSet,
        required: Set<String>
    ) -> AdminProcurementReadinessCheck {
        let available = required.allSatisfy { permissions.can($0) }
        return AdminProcurementReadinessCheck(
            id: "permission.\(id)",
            title: title,
            detail: available
                ? "El usuario actual tiene las capacidades de consulta requeridas."
                : "La plataforma puede estar sana, pero este usuario no podrá consultar esta superficie.",
            status: available ? .ready : .warning,
            required: false
        )
    }

    private func requiredCheck(
        id: String,
        title: String,
        passed: Bool,
        ready: String,
        blocked: String
    ) -> AdminProcurementReadinessCheck {
        AdminProcurementReadinessCheck(
            id: id,
            title: title,
            detail: passed ? ready : blocked,
            status: passed ? .ready : .blocked,
            required: true
        )
    }
}
