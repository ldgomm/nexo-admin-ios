//
//  AdminElectronicDocumentsViewModelTests.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import XCTest
@testable import Nexo_Admin

@MainActor
final class AdminElectronicDocumentsViewModelTests: XCTestCase {
    func testLoadDocumentsWithPermissionLoadsList() async {
        let repository = MockAdminElectronicDocumentRepository()
        let viewModel = AdminElectronicDocumentsViewModel(
            repository: repository,
            permissions: [PermissionCatalog.documentsView]
        )

        await viewModel.load()

        guard case .loaded(let documents) = viewModel.documentsState else {
            XCTFail("Expected loaded documents")
            return
        }
        XCTAssertEqual(documents.count, 2)
    }

    func testLoadDocumentsWithoutPermissionFails() async {
        let repository = MockAdminElectronicDocumentRepository()
        let viewModel = AdminElectronicDocumentsViewModel(
            repository: repository,
            permissions: []
        )

        await viewModel.load()

        guard case .failed(let message) = viewModel.documentsState else {
            XCTFail("Expected failed state")
            return
        }
        XCTAssertTrue(message.contains("permiso"))
    }

    func testFilterDocumentsReturnsEmptyWhenNoMatches() async {
        let repository = MockAdminElectronicDocumentRepository()
        let viewModel = AdminElectronicDocumentsViewModel(
            repository: repository,
            permissions: [PermissionCatalog.documentsView]
        )
        viewModel.filter.query = "no-existe"

        await viewModel.load()

        guard case .empty(let message) = viewModel.documentsState else {
            XCTFail("Expected empty state")
            return
        }
        XCTAssertTrue(message.contains("filtros"))
    }

    func testSelectDocumentLoadsDetail() async {
        let repository = MockAdminElectronicDocumentRepository()
        let viewModel = AdminElectronicDocumentsViewModel(
            repository: repository,
            permissions: [PermissionCatalog.documentsView]
        )

        await viewModel.select(document: MockAdminElectronicDocumentData.authorized)

        XCTAssertEqual(viewModel.selectedDocumentId, MockAdminElectronicDocumentData.authorized.id)
        XCTAssertEqual(viewModel.selectedDetail?.summary.displayNumber, "001-001-000000123")
    }

    func testRetryRequiresPermission() async {
        let repository = MockAdminElectronicDocumentRepository()
        let viewModel = AdminElectronicDocumentsViewModel(
            repository: repository,
            permissions: [PermissionCatalog.documentsView]
        )

        await viewModel.select(document: MockAdminElectronicDocumentData.rejected)
        await viewModel.retrySelectedAuthorization()

        XCTAssertEqual(viewModel.actionErrorMessage, "No puedes reintentar autorización en el estado actual.")
    }

    func testRetryWithPermissionSetsMessage() async {
        let repository = MockAdminElectronicDocumentRepository()
        let viewModel = AdminElectronicDocumentsViewModel(
            repository: repository,
            permissions: [PermissionCatalog.documentsView, PermissionCatalog.documentsRetryAuthorization]
        )

        await viewModel.select(document: MockAdminElectronicDocumentData.rejected)
        await viewModel.retrySelectedAuthorization()

        XCTAssertEqual(viewModel.lastActionMessage, "Reintento encolado correctamente.")
    }

    func testResendEmailWithPermissionSetsMessage() async {
        let repository = MockAdminElectronicDocumentRepository()
        let viewModel = AdminElectronicDocumentsViewModel(
            repository: repository,
            permissions: [PermissionCatalog.documentsView, PermissionCatalog.documentsResendEmail]
        )

        await viewModel.select(document: MockAdminElectronicDocumentData.authorized)
        await viewModel.resendSelectedEmail()

        XCTAssertEqual(viewModel.lastActionMessage, "Email encolado correctamente.")
    }

    func testVisibleActionsComeFromBackendAvailableActions() async {
        let repository = MockAdminElectronicDocumentRepository()
        let viewModel = AdminElectronicDocumentsViewModel(
            repository: repository,
            permissions: [
                PermissionCatalog.documentsView,
                PermissionCatalog.documentsDownloadRide,
                PermissionCatalog.documentsDownloadXML,
                PermissionCatalog.documentsResendEmail,
                PermissionCatalog.documentsRetryAuthorization
            ]
        )

        await viewModel.select(document: MockAdminElectronicDocumentData.rejected)

        let actions = viewModel.selectedDetail.map { viewModel.visibleActions(on: $0) } ?? []
        XCTAssertTrue(actions.contains(.retryReception))
        XCTAssertTrue(actions.contains(.retryAuthorization))
        XCTAssertTrue(actions.contains(.downloadXml))
        XCTAssertFalse(actions.contains(.downloadRide))
        XCTAssertFalse(actions.contains(.regenerateRide))
    }

    func testRefreshTimelineRequiresBackendAction() async {
        let detailWithoutTimeline = AdminElectronicDocumentDetail(
            id: MockAdminElectronicDocumentData.detail.id,
            summary: MockAdminElectronicDocumentData.detail.summary,
            branchName: MockAdminElectronicDocumentData.detail.branchName,
            emissionPointName: MockAdminElectronicDocumentData.detail.emissionPointName,
            legalName: MockAdminElectronicDocumentData.detail.legalName,
            commercialName: MockAdminElectronicDocumentData.detail.commercialName,
            taxId: MockAdminElectronicDocumentData.detail.taxId,
            totals: MockAdminElectronicDocumentData.detail.totals,
            lines: MockAdminElectronicDocumentData.detail.lines,
            sri: MockAdminElectronicDocumentData.detail.sri,
            artifacts: MockAdminElectronicDocumentData.detail.artifacts,
            email: MockAdminElectronicDocumentData.detail.email,
            timeline: MockAdminElectronicDocumentData.detail.timeline,
            errors: MockAdminElectronicDocumentData.detail.errors,
            warnings: MockAdminElectronicDocumentData.detail.warnings,
            availableActions: [.viewDetail],
            retrySummary: MockAdminElectronicDocumentData.detail.retrySummary
        )
        let repository = MockAdminElectronicDocumentRepository(details: [detailWithoutTimeline.id: detailWithoutTimeline])
        let viewModel = AdminElectronicDocumentsViewModel(
            repository: repository,
            permissions: [PermissionCatalog.documentsView]
        )

        await viewModel.select(document: MockAdminElectronicDocumentData.authorized)
        await viewModel.refreshSelectedTimeline()

        XCTAssertEqual(viewModel.actionErrorMessage, "No puedes actualizar el timeline en el estado actual.")
    }

}
