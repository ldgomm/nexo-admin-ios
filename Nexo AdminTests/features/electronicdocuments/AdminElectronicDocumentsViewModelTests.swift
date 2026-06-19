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

    func testFilterDocumentsMatchesAuthorizationAndAmount() async {
        let repository = MockAdminElectronicDocumentRepository()
        let viewModel = AdminElectronicDocumentsViewModel(
            repository: repository,
            permissions: [PermissionCatalog.documentsView]
        )
        viewModel.filter.query = "23.50"

        await viewModel.load()

        guard case .loaded(let documents) = viewModel.documentsState else {
            XCTFail("Expected loaded documents")
            return
        }
        XCTAssertEqual(documents.map(\.displayNumber), ["001-001-000000123"])

        viewModel.filter.query = MockAdminElectronicDocumentData.authorized.authorizationNumber ?? ""
        await viewModel.load()

        guard case .loaded(let authorizedDocuments) = viewModel.documentsState else {
            XCTFail("Expected authorization search to load documents")
            return
        }
        XCTAssertEqual(authorizedDocuments.map(\.displayNumber), ["001-001-000000123"])
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
    
    func testVisibleActionsRespectBackendStateAndUserPermissions() async {
        let repository = MockAdminElectronicDocumentRepository()
        let viewModel = AdminElectronicDocumentsViewModel(
            repository: repository,
            permissions: [
                PermissionCatalog.documentsView,
                PermissionCatalog.documentsDownloadXML,
                PermissionCatalog.documentsRetryAuthorization
            ]
        )
        
        await viewModel.select(document: MockAdminElectronicDocumentData.rejected)
        
        let actions = viewModel.selectedDetail.map { viewModel.visibleActions(on: $0) } ?? []
        XCTAssertTrue(actions.contains(.retryAuthorization))
        XCTAssertTrue(actions.contains(.downloadXml))
        XCTAssertFalse(actions.contains(.retryReception))
        XCTAssertFalse(actions.contains(.downloadRide))
        XCTAssertFalse(actions.contains(.resendEmail))
        XCTAssertFalse(actions.contains(.regenerateRide))
    }

    func testVisibleActionsHideOperationalActionsForReadOnlyDocumentUser() async {
        let repository = MockAdminElectronicDocumentRepository()
        let viewModel = AdminElectronicDocumentsViewModel(
            repository: repository,
            permissions: [PermissionCatalog.documentsView]
        )
        
        await viewModel.select(document: MockAdminElectronicDocumentData.authorized)
        
        let actions = viewModel.selectedDetail.map { viewModel.visibleActions(on: $0) } ?? []
        XCTAssertTrue(actions.isEmpty)
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
            permissions: [PermissionCatalog.documentsView, PermissionCatalog.documentsViewTimeline]
        )
        
        await viewModel.select(document: MockAdminElectronicDocumentData.authorized)
        await viewModel.refreshSelectedTimeline()
        
        XCTAssertEqual(viewModel.actionErrorMessage, "El timeline no está disponible para este comprobante.")
    }
    
    func testRefreshTimelineRequiresTimelinePermission() async {
        let repository = MockAdminElectronicDocumentRepository()
        let viewModel = AdminElectronicDocumentsViewModel(
            repository: repository,
            permissions: [PermissionCatalog.documentsView]
        )
        
        await viewModel.select(document: MockAdminElectronicDocumentData.authorized)
        await viewModel.refreshSelectedTimeline()
        
        XCTAssertEqual(viewModel.actionErrorMessage, "No tienes permiso para consultar el timeline de comprobantes.")
    }

    
    
    func testPrepareRideDownloadsBinaryFileInsteadOfArtifactMetadata() async {
        let repository = MockAdminElectronicDocumentRepository()
        let viewModel = AdminElectronicDocumentsViewModel(
            repository: repository,
            permissions: [
                PermissionCatalog.documentsView,
                PermissionCatalog.documentsDownloadRide
            ]
        )
        
        await viewModel.select(document: MockAdminElectronicDocumentData.authorized)
        await viewModel.prepareRideShare()
        
        XCTAssertEqual(viewModel.previewFile?.contentType, "application/pdf")
        XCTAssertEqual(viewModel.previewFile?.kind, "ride")
        XCTAssertTrue(viewModel.previewFile?.localURL.isFileURL == true)
        XCTAssertNil(viewModel.actionErrorMessage)
    }
    
    func testPrepareXmlDownloadsBinaryFileInsteadOfArtifactMetadata() async {
        let repository = MockAdminElectronicDocumentRepository()
        let viewModel = AdminElectronicDocumentsViewModel(
            repository: repository,
            permissions: [
                PermissionCatalog.documentsView,
                PermissionCatalog.documentsDownloadXML
            ]
        )
        
        await viewModel.select(document: MockAdminElectronicDocumentData.authorized)
        await viewModel.prepareXmlShare()
        
        XCTAssertEqual(viewModel.previewFile?.contentType, "application/xml")
        XCTAssertEqual(viewModel.previewFile?.kind, "authorizedXml")
        XCTAssertTrue(viewModel.previewFile?.localURL.isFileURL == true)
        XCTAssertNil(viewModel.actionErrorMessage)
    }
    
    
    func testRegenerateRideIsVisibleForAuthorizedDocumentThatAlreadyHasRideWhenBackendAllowsIt() async {
        let repository = MockAdminElectronicDocumentRepository()
        let viewModel = AdminElectronicDocumentsViewModel(
            repository: repository,
            permissions: [
                PermissionCatalog.documentsView,
                PermissionCatalog.documentsDownloadRide,
                PermissionCatalog.taxManage
            ]
        )
        
        await viewModel.select(document: MockAdminElectronicDocumentData.authorized)
        
        let actions = viewModel.selectedDetail.map { viewModel.visibleActions(on: $0) } ?? []
        XCTAssertTrue(actions.contains(.downloadRide))
        XCTAssertTrue(actions.contains(.regenerateRide))
    }
    
    func testRegenerateRideWithPermissionFollowsBackendContractAndSetsMessage() async {
        let repository = MockAdminElectronicDocumentRepository()
        let viewModel = AdminElectronicDocumentsViewModel(
            repository: repository,
            permissions: [
                PermissionCatalog.documentsView,
                PermissionCatalog.documentsDownloadRide,
                PermissionCatalog.taxManage
            ]
        )
        
        await viewModel.select(document: MockAdminElectronicDocumentData.authorized)
        await viewModel.regenerateSelectedRide()
        
        XCTAssertEqual(viewModel.lastActionMessage, "Regeneración de RIDE encolada correctamente.")
        XCTAssertNil(viewModel.actionErrorMessage)
    }
    
    func testMapperHumanizesTechnicalTimelineEventsAndSanitizesMessages() {
        let response = AdminElectronicDocumentTimelineResponseDTO(
            documentId: "doc_1",
            events: [
                AdminElectronicDocumentTimelineEventDTO(
                    id: "evt_1",
                    type: nil,
                    action: "SRI_ACCESS_KEY_GENERATED",
                    title: "Sri access key generated",
                    message: nil,
                    actor: nil,
                    actorUserId: "usr_1",
                    createdAt: nil,
                    occurredAt: "2026-06-18T22:15:25.098Z",
                    severity: nil,
                    status: "ACCESS_KEY_GENERATED"
                ),
                AdminElectronicDocumentTimelineEventDTO(
                    id: "evt_2",
                    type: "SRI_RECEPTION_TRANSPORT_FAILED",
                    action: nil,
                    title: "technical backend title",
                    message: "falló /var/lib/nexo/electronic-invoicing/doc/sri_request.xml",
                    actor: "Sistema",
                    actorUserId: nil,
                    createdAt: "2026-06-18T22:16:25.098Z",
                    occurredAt: nil,
                    severity: nil,
                    status: "RECEPTION_TRANSPORT_FAILED"
                ),
                AdminElectronicDocumentTimelineEventDTO(
                    id: "evt_3",
                    type: "FUTURE_EVENT_TYPE",
                    action: nil,
                    title: "Evento futuro visible",
                    message: "Evento visible",
                    actor: nil,
                    actorUserId: nil,
                    createdAt: "2026-06-18T22:17:25.098Z",
                    occurredAt: nil,
                    severity: "info",
                    status: nil
                )
            ],
            timeline: nil
        )

        let events = AdminElectronicDocumentMapper.mapTimelineResponse(response)

        XCTAssertEqual(events[0].title, "Clave de acceso generada")
        XCTAssertEqual(events[0].message, "Se generó la clave de acceso del comprobante.")
        XCTAssertEqual(events[0].actor, "usr_1")
        XCTAssertEqual(events[0].createdAt, "2026-06-18T22:15:25.098Z")
        XCTAssertEqual(events[0].severity, .info)

        XCTAssertEqual(events[1].title, "No se pudo conectar con recepción SRI")
        XCTAssertEqual(events[1].message, "No se pudo completar la conexión con recepción SRI. Puedes reintentar si el estado lo permite.")
        XCTAssertEqual(events[1].severity, .warning)

        XCTAssertEqual(events[2].title, "Evento futuro visible")
        XCTAssertEqual(events[2].message, "Evento visible")
    }


}
