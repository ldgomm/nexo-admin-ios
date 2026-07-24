//
//  AdminProcurementReadinessContractTests.swift
//  Nexo AdminTests
//

import XCTest
@testable import Nexo_Admin

final class AdminProcurementReadinessContractTests: XCTestCase {
    func testRoutesStayInsideExactAdminProcurementNamespace() {
        XCTAssertEqual(AdminProcurementRoutes.reportCatalog, "/api/v1/admin/procurement/reports")
        XCTAssertEqual(AdminProcurementRoutes.report("open_overdue_payables"), "/api/v1/admin/procurement/reports/open_overdue_payables")
        XCTAssertEqual(AdminProcurementRoutes.financeFacts, "/api/v1/admin/procurement/finance-facts")
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

    func testBackendMoneyMappingRejectsInvalidAmountInsteadOfDefaulting() throws {
        XCTAssertThrowsError(try AdminProcurementMoneyDTO(amount: "not-a-number", currency: "USD").toDomain())
        let money = try AdminProcurementMoneyDTO(amount: "125.40", currency: "USD").toDomain()
        XCTAssertEqual(money.amount, Decimal(string: "125.40"))
        XCTAssertEqual(money.currency, "USD")
    }
}
