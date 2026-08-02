//
//  AdminProcurementReadinessUseCases.swift
//  Nexo Admin
//
//  Created by José Ruiz on 29/7/26.
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

    static let accountingCompletenessPassExistingIds: Set<String> = [
        "SUPPLIER_IDENTITY",
        "ORGANIZATION_BRANCH",
        "PURCHASE_INTENT",
        "ACTUAL_RECEIPT",
        "INVENTORY_ACQUISITION",
        "SUPPLIER_DOCUMENT_IDENTITY",
        "BUSINESS_DATES",
        "EXACT_CURRENCY_MONEY",
        "ORDER_LINE_ECONOMICS",
        "DOCUMENT_LINE_ECONOMICS",
        "TAX_COMPONENT_EVIDENCE",
        "PAID_AT_SOURCE_PURCHASE",
        "PAYABLE_ORIGIN",
        "PAYABLE_BALANCE_EFFECTS",
        "SUPPLIER_PAYMENT",
        "SUPPLIER_STATEMENT",
        "ATTACHMENT_EVIDENCE",
        "IDEMPOTENCY",
        "HISTORICAL_REPLAY",
        "OPERATIONAL_REPORT_EQUIVALENCE",
    ]

    static let accountingCompletenessFutureGapIds: Set<String> = [
        "SERVICE_PERIOD",
        "FINANCIAL_CATEGORY_COST_CENTER",
        "DEDUCTIBILITY",
        "CAPITALIZATION",
        "RETENTION_EVIDENCE",
        "SUPPLIER_CREDIT_DEBIT_ADJUSTMENT",
        "NON_CASH_SETTLEMENT",
        "SUPPLIER_ADVANCE",
        "CASH_BANK_ACCOUNT_BINDING",
        "EXCHANGE_RATE_ORIGINAL_CURRENCY",
    ]

    static let accountingCompletenessNotApplicableIds: Set<String> = [
        "ACCOUNTING_POLICY_ACCOUNT_MAPPING",
        "DEBIT_CREDIT_JOURNAL",
        "POSTED_LEDGER_FINANCIAL_STATEMENTS",
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
                            !$0.catalog.accountingEntriesGenerated &&
                                !$0.financeHealth.accountingEntriesGenerated &&
                                !$0.financeSourceFactReplayReadiness.accountingEntriesGenerated &&
                                !$0.financeSourceFactReplayReadiness.postable &&
                                !$0.accountingCompletenessMatrix.accountingEntriesGenerated &&
                                !$0.accountingCompletenessMatrix.postable
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
            financeSourceFactSchemaVersion: contracts?.financeSourceFactReplayReadiness.schemaVersion,
            financeSourceFactTypeCount: contracts?.financeSourceFactReplayReadiness.supportedFactTypes.count,
            accountingCompletenessMatrix: contracts?.accountingCompletenessMatrix,
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
        let replay = contracts.financeSourceFactReplayReadiness
        let matrix = contracts.accountingCompletenessMatrix
        let matrixPassExistingIds = Set(matrix.items.filter { $0.classification == .passExisting }.map(\.id))
        let matrixFutureGapIds = Set(matrix.items.filter { $0.classification == .documentFutureGap }.map(\.id))
        let matrixNotApplicableIds = Set(matrix.items.filter { $0.classification == .notApplicable }.map(\.id))
        let supportedFactTypes = Set(replay.supportedFactTypes)
        let reservedFactTypes = Set(replay.reservedFactTypes)
        let expectedSupportedFactTypes: Set<String> = [
            "PURCHASE_ORDER_SENT",
            "PURCHASE_ORDER_CANCELLED",
            "PURCHASE_RECEIPT_CONFIRMED",
            "SUPPLIER_DOCUMENT_CONFIRMED",
            "SOURCE_PAYMENT_RECORDED",
            "PAYABLE_CREATED",
            "PAYABLE_STATUS_CHANGED",
            "SUPPLIER_PAYMENT_RECORDED",
            "SUPPLIER_PAYMENT_VOIDED"
        ]
        let expectedReservedFactTypes: Set<String> = [
            "PURCHASE_RECEIPT_REVERSED",
            "SUPPLIER_DOCUMENT_VOIDED",
            "PAYABLE_ADJUSTMENT_RECORDED",
            "PAYABLE_ADJUSTMENT_VOIDED"
        ]

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
            ),
            requiredCheck(
                id: "finance-source-facts-v1.contract",
                title: "Replay FinanceSourceFact V1",
                passed: replay.contractVersion == 1 &&
                    replay.schemaVersion == 1 &&
                    replay.organizationId == organizationId &&
                    replay.branchId == branchId &&
                    replay.supplierId == nil &&
                    replay.currency == currency &&
                    replay.effectiveFrom == nil &&
                    replay.effectiveTo == nil &&
                    replay.maxPageSize == 100 &&
                    replay.replayMode == "SNAPSHOT_KEYSET_V1" &&
                    !replay.snapshotAt.isEmpty,
                ready: "El backend expone un snapshot V1 acotado y reproducible para toda la historia de la sucursal.",
                blocked: "El replay V1 cambió de versión, filtros, scope, moneda o contrato de paginación."
            ),
            requiredCheck(
                id: "finance-source-facts-v1.families",
                title: "Familias de hechos V1",
                passed: supportedFactTypes == expectedSupportedFactTypes &&
                    replay.supportedFactTypes.count == expectedSupportedFactTypes.count &&
                    reservedFactTypes == expectedReservedFactTypes &&
                    replay.reservedFactTypes.count == expectedReservedFactTypes.count &&
                    supportedFactTypes.isDisjoint(with: reservedFactTypes),
                ready: "Nueve familias soportadas están diferenciadas de las operaciones reservadas.",
                blocked: "Faltan familias soportadas, hay duplicados o una familia reservada fue expuesta como aceptada."
            ),
            requiredCheck(
                id: "finance-source-facts-v1.cursor",
                title: "Cursor de backfill consistente",
                passed: (0...1).contains(replay.returnedFactCount) &&
                    replay.hasMore == replay.nextCursorAvailable,
                ready: "La lectura de readiness está acotada y declara correctamente si existe una página siguiente.",
                blocked: "El backend devolvió una página no acotada o un cursor inconsistente."
            ),
            requiredCheck(
                id: "finance-source-facts-v1.boundary",
                title: "Replay de solo lectura",
                passed: replay.readOnly &&
                    !replay.accountingEntriesGenerated &&
                    !replay.postable &&
                    Set(replay.limitations).isSuperset(of: [
                        "USD_ONLY",
                        "READ_ONLY",
                        "NO_ACCOUNTING_ENTRIES",
                        "NO_PAYLOAD_EXPOSURE"
                    ]),
                ready: "Admin verifica replay y backfill sin exponer payloads ni generar contabilidad.",
                blocked: "La ruta V1 dejó de ser read-only o pretende exponer/postear información fuera de 27R."
            ),
            requiredCheck(
                id: "accounting-completeness.contract",
                title: "Matriz de completitud contable",
                passed: matrix.contractVersion == 1 &&
                    matrix.matrixVersion == "27R.L0.H.v1" &&
                    matrix.acceptedStage == "27R.L.7" &&
                    matrix.organizationId == organizationId &&
                    matrix.currency == currency &&
                    matrix.scope == "PROCUREMENT_PAYABLES" &&
                    matrix.sourceDocument == "NEXO_27R_ACCOUNTING_COMPLETENESS_SOURCE_MATRIX.md" &&
                    matrix.totalItemCount == 33 &&
                    matrix.passExistingCount == 20 &&
                    matrix.futureGapCount == 10 &&
                    matrix.notApplicableCount == 3,
                ready: "La matriz runtime coincide con la fuente aceptada: 20 fuentes listas, 10 brechas futuras y 3 rubros fuera de 27R.",
                blocked: "La matriz cambió de versión, scope, moneda, fuente o conteos aceptados."
            ),
            requiredCheck(
                id: "accounting-completeness.rows",
                title: "Cobertura completa de filas",
                passed: matrix.items.count == 33 &&
                    Set(matrix.items.map(\.id)).count == 33 &&
                    matrixPassExistingIds == Self.accountingCompletenessPassExistingIds &&
                    matrixFutureGapIds == Self.accountingCompletenessFutureGapIds &&
                    matrixNotApplicableIds == Self.accountingCompletenessNotApplicableIds,
                ready: "Impuestos, fechas, periodos, clasificación, activos, retenciones y settlements quedan explícitos sin inferencias.",
                blocked: "Faltan filas, existen duplicados o una clasificación dejó de coincidir con el cierre 27R.L.7."
            ),
            requiredCheck(
                id: "accounting-completeness.boundary",
                title: "Matriz read-only y no contable",
                passed: matrix.readOnly &&
                    !matrix.accountingEntriesGenerated &&
                    !matrix.postable &&
                    Set(matrix.limitations).isSuperset(of: [
                        "USD_ONLY",
                        "READ_ONLY",
                        "NO_ACCOUNTING_ENTRIES",
                        "NO_TAX_OR_ACCOUNTING_INFERENCE"
                    ]),
                ready: "Admin muestra evidencia y brechas; no decide impuestos, cuentas, débitos, créditos ni estados financieros.",
                blocked: "La matriz intenta postear, generar contabilidad o inferir tratamiento tributario."
            )
        ]
    }

    private func permissionChecks(permissions: PermissionSet) -> [AdminProcurementReadinessCheck] {
        [
            permissionCheck(id: "reports", title: "Readiness y reportes", permissions: permissions, required: [PermissionCatalog.reportsDashboardView]),
            permissionCheck(id: "suppliers", title: "Proveedores", permissions: permissions, required: [PermissionCatalog.suppliersView]),
            permissionCheck(id: "orders", title: "Órdenes de compra y costos", permissions: permissions, required: [PermissionCatalog.purchaseOrdersView, PermissionCatalog.purchaseOrdersCostView]),
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
