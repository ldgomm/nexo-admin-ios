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

        XCTAssertEqual(viewModel.actionErrorMessage, "No tienes permiso para reintentar autorización.")
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
}
