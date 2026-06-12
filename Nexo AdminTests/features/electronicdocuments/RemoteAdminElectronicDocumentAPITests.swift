import XCTest
@testable import Nexo_Admin

final class RemoteAdminElectronicDocumentAPITests: XCTestCase {
    func testAdminElectronicDocumentRoutesUseCanonicalNamespace() {
        XCTAssertEqual(AdminElectronicDocumentRoutes.list(), "/api/v1/admin/electronic-documents")
        XCTAssertEqual(AdminElectronicDocumentRoutes.detail(documentId: "edoc_1"), "/api/v1/admin/electronic-documents/edoc_1")
        XCTAssertEqual(AdminElectronicDocumentRoutes.timeline(documentId: "edoc_1"), "/api/v1/admin/electronic-documents/edoc_1/timeline")
        XCTAssertEqual(AdminElectronicDocumentRoutes.retryReception(documentId: "edoc_1"), "/api/v1/admin/electronic-documents/edoc_1/retry-reception")
        XCTAssertEqual(AdminElectronicDocumentRoutes.retryAuthorization(documentId: "edoc_1"), "/api/v1/admin/electronic-documents/edoc_1/retry-authorization")
        XCTAssertEqual(AdminElectronicDocumentRoutes.resendEmail(documentId: "edoc_1"), "/api/v1/admin/electronic-documents/edoc_1/resend-email")
        XCTAssertEqual(AdminElectronicDocumentRoutes.ride(documentId: "edoc_1"), "/api/v1/admin/electronic-documents/edoc_1/ride")
        XCTAssertEqual(AdminElectronicDocumentRoutes.regenerateRide(documentId: "edoc_1"), "/api/v1/admin/electronic-documents/edoc_1/ride")
        XCTAssertEqual(AdminElectronicDocumentRoutes.rideFile(documentId: "edoc_1"), "/api/v1/admin/electronic-documents/edoc_1/ride/file")
        XCTAssertEqual(AdminElectronicDocumentRoutes.xml(documentId: "edoc_1"), "/api/v1/admin/electronic-documents/edoc_1/xml")
        XCTAssertEqual(AdminElectronicDocumentRoutes.xmlFile(documentId: "edoc_1"), "/api/v1/admin/electronic-documents/edoc_1/xml/file")
    }

    func testAdminElectronicDocumentRoutesDoNotUseLegacyElectronicInvoicesNamespace() {
        let routes = [
            AdminElectronicDocumentRoutes.list(),
            AdminElectronicDocumentRoutes.detail(documentId: "edoc_1"),
            AdminElectronicDocumentRoutes.timeline(documentId: "edoc_1"),
            AdminElectronicDocumentRoutes.retryReception(documentId: "edoc_1"),
            AdminElectronicDocumentRoutes.retryAuthorization(documentId: "edoc_1"),
            AdminElectronicDocumentRoutes.resendEmail(documentId: "edoc_1"),
            AdminElectronicDocumentRoutes.ride(documentId: "edoc_1"),
            AdminElectronicDocumentRoutes.rideFile(documentId: "edoc_1"),
            AdminElectronicDocumentRoutes.xml(documentId: "edoc_1"),
            AdminElectronicDocumentRoutes.xmlFile(documentId: "edoc_1")
        ]

        for route in routes {
            XCTAssertFalse(route.contains("/api/v1/admin/electronic-invoices"))
            XCTAssertFalse(route.contains("/electronic-invoices"))
        }
    }
}
