//
//  AdminProcurementReadinessContractTests.swift
//  Nexo AdminTests
//
//  Created by José Ruiz on 29/7/26.
//

import XCTest
@testable import Nexo_Admin

class AdminProcurementReadinessContractTests: XCTestCase {
    func testRoutesStayInsideExactAdminProcurementNamespace() {
        XCTAssertEqual(AdminProcurementRoutes.reportCatalog, "/api/v1/admin/procurement/reports")
        XCTAssertEqual(AdminProcurementRoutes.report("open_overdue_payables"), "/api/v1/admin/procurement/reports/open_overdue_payables")
        XCTAssertEqual(AdminProcurementRoutes.financeFacts, "/api/v1/admin/procurement/finance-facts")
        XCTAssertEqual(
            AdminProcurementRoutes.financeFactsV1ReplayReadiness,
            "/api/v1/admin/procurement/finance-facts/v1/readiness"
        )
        XCTAssertEqual(
            AdminProcurementRoutes.accountingCompleteness,
            "/api/v1/admin/procurement/accounting-completeness"
        )
        XCTAssertFalse(AdminProcurementRoutes.reportCatalog.contains("/business/"))
    }

    func testRequiredReportSetMatchesAcceptedServerCatalog() {
        XCTAssertEqual(AdminProcurementReadinessEvaluator.requiredReportTypes.count, 10)
        XCTAssertTrue(AdminProcurementReadinessEvaluator.requiredReportTypes.contains("supplier_statement"))
        XCTAssertTrue(AdminProcurementReadinessEvaluator.requiredReportTypes.contains("open_overdue_payables"))
        XCTAssertTrue(AdminProcurementReadinessEvaluator.requiredReportTypes.contains("procurement_evidence"))
    }

    func testPermissionConstantsMatchServerWireContract() {
        XCTAssertEqual(PermissionCatalog.suppliersView, "suppliers.view")
        XCTAssertEqual(PermissionCatalog.purchaseOrdersView, "purchase_orders.view")
        XCTAssertEqual(PermissionCatalog.purchaseOrdersCostView, "purchase_orders.cost_view")
        XCTAssertEqual(PermissionCatalog.purchaseReceiptsView, "purchase_receipts.view")
        XCTAssertEqual(PermissionCatalog.supplierDocumentsView, "supplier_documents.view")
        XCTAssertEqual(PermissionCatalog.payablesAgingView, "payables.aging_view")
        XCTAssertEqual(PermissionCatalog.supplierPaymentsVoid, "supplier_payments.void")
        XCTAssertEqual(PermissionCatalog.supplierStatementsExport, "supplier_statements.export")
        XCTAssertEqual(PermissionCatalog.procurementAttachmentsUpload, "procurement.attachments_upload")
        XCTAssertEqual(PermissionCatalog.procurementAttachmentsDelete, "procurement.attachments_delete")
        XCTAssertEqual(PermissionCatalog.procurementAuditView, "procurement.audit_view")
        XCTAssertEqual(PermissionCatalog.reportsExport, "reports.export")
    }

    func testHealthAccessRequiresEveryBackendReadPermission() {
        XCTAssertTrue(AdminProcurementReadinessAccess.allows([PermissionCatalog.all]))
        XCTAssertTrue(AdminProcurementReadinessAccess.allows(AdminProcurementReadinessAccess.requiredPermissions))
        let manageInsteadOfView = AdminProcurementReadinessAccess.requiredPermissions
            .subtracting([PermissionCatalog.modulesView])
            .union([PermissionCatalog.modulesManage])
        XCTAssertTrue(AdminProcurementReadinessAccess.allows(manageInsteadOfView))
        XCTAssertFalse(AdminProcurementReadinessAccess.allows([PermissionCatalog.reportsDashboardView]))
    }

    func testReplayReadinessMappingPreservesServerContract() {
        let domain = AdminProcurementFinanceSourceFactReplayReadinessDTO(
            contractVersion: 1,
            schemaVersion: 1,
            organizationId: "org_1",
            branchId: "br_1",
            supplierId: nil,
            currency: "USD",
            effectiveFrom: nil,
            effectiveTo: nil,
            snapshotAt: "2026-07-24T17:00:00Z",
            returnedFactCount: 1,
            hasMore: true,
            nextCursorAvailable: true,
            maxPageSize: 100,
            supportedFactTypes: ["PURCHASE_ORDER_SENT"],
            reservedFactTypes: ["PURCHASE_RECEIPT_REVERSED"],
            replayMode: "SNAPSHOT_KEYSET_V1",
            readOnly: true,
            accountingEntriesGenerated: false,
            postable: false,
            limitations: ["USD_ONLY", "READ_ONLY", "NO_ACCOUNTING_ENTRIES", "NO_PAYLOAD_EXPOSURE"]
        ).toDomain()

        XCTAssertEqual(domain.schemaVersion, 1)
        XCTAssertEqual(domain.snapshotAt, "2026-07-24T17:00:00Z")
        XCTAssertTrue(domain.hasMore)
        XCTAssertTrue(domain.nextCursorAvailable)
        XCTAssertTrue(domain.readOnly)
        XCTAssertFalse(domain.postable)
    }

    func testAccountingCompletenessMappingPreservesClassificationsAndCounts() throws {
        let dto = AdminProcurementAccountingCompletenessMatrixDTO(
            contractVersion: 1,
            matrixVersion: "27R.L0.H.v1",
            acceptedStage: "27R.L.7",
            organizationId: "org_1",
            currency: "USD",
            scope: "PROCUREMENT_PAYABLES",
            sourceDocument: "NEXO_27R_ACCOUNTING_COMPLETENESS_SOURCE_MATRIX.md",
            totalItemCount: 3,
            passExistingCount: 1,
            futureGapCount: 1,
            notApplicableCount: 1,
            items: [
                matrixItem(id: "TAX_COMPONENT_EVIDENCE", classification: "PASS_EXISTING"),
                matrixItem(id: "SERVICE_PERIOD", classification: "DOCUMENT_FUTURE_GAP"),
                matrixItem(id: "DEBIT_CREDIT_JOURNAL", classification: "NOT_APPLICABLE")
            ],
            readOnly: true,
            accountingEntriesGenerated: false,
            postable: false,
            limitations: ["USD_ONLY", "READ_ONLY", "NO_ACCOUNTING_ENTRIES", "NO_TAX_OR_ACCOUNTING_INFERENCE"]
        )

        let domain = try dto.toDomain()

        XCTAssertEqual(domain.totalItemCount, 3)
        XCTAssertEqual(domain.items[0].classification, .passExisting)
        XCTAssertEqual(domain.items[1].classification, .documentFutureGap)
        XCTAssertEqual(domain.items[2].classification, .notApplicable)
        XCTAssertTrue(domain.readOnly)
        XCTAssertFalse(domain.postable)
    }

    func testAccountingCompletenessMappingRejectsUnknownClassification() {
        let dto = AdminProcurementAccountingCompletenessMatrixDTO(
            contractVersion: 1,
            matrixVersion: "27R.L0.H.v1",
            acceptedStage: "27R.L.7",
            organizationId: "org_1",
            currency: "USD",
            scope: "PROCUREMENT_PAYABLES",
            sourceDocument: "NEXO_27R_ACCOUNTING_COMPLETENESS_SOURCE_MATRIX.md",
            totalItemCount: 1,
            passExistingCount: 1,
            futureGapCount: 0,
            notApplicableCount: 0,
            items: [matrixItem(id: "UNKNOWN", classification: "INVENTED")],
            readOnly: true,
            accountingEntriesGenerated: false,
            postable: false,
            limitations: []
        )

        XCTAssertThrowsError(try dto.toDomain())
    }

    func testBackendMoneyMappingRejectsInvalidAmountInsteadOfDefaulting() throws {
        XCTAssertThrowsError(try AdminProcurementMoneyDTO(amount: "not-a-number", currency: "USD").toDomain())
        let money = try AdminProcurementMoneyDTO(amount: "125.40", currency: "USD").toDomain()
        XCTAssertEqual(money.amount, Decimal(string: "125.40"))
        XCTAssertEqual(money.currency, "USD")
    }

    private func matrixItem(
        id: String,
        classification: String
    ) -> AdminProcurementAccountingCompletenessItemDTO {
        AdminProcurementAccountingCompletenessItemDTO(
            id: id,
            title: id,
            displayTitle: id,
            authoritativeEvidence: "Evidence",
            v1ReplayStatus: "Replay",
            classification: classification,
            classificationNote: nil,
            futureOwnerAction: "Future action"
        )
    }
}
