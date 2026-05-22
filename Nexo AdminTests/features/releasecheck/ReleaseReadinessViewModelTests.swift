//
//  ReleaseReadinessViewModelTests.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import XCTest
@testable import Nexo_Admin

@MainActor
final class ReleaseReadinessViewModelTests: XCTestCase {
    func testReportFailsWhenAPIIsLocal() throws {
        let sessionStore = AuthSessionStore(
            tokenStore: InMemoryAuthTokenStore(),
            organizationSelectionStore: InMemoryOrganizationSelectionStore()
        )

        let viewModel = ReleaseReadinessViewModel(
            sessionStore: sessionStore,
            buildInfoProvider: {
                BuildInfo(
                    appName: "Nexo Admin",
                    bundleIdentifier: "com.nexo.admin",
                    version: "1.0.0",
                    build: "1",
                    configuration: .debug,
                    apiBaseURL: "http://localhost:8080"
                )
            },
            now: { Date(timeIntervalSince1970: 0) }
        )

        viewModel.load()

        let report = try XCTUnwrap(viewModel.report)
        XCTAssertFalse(report.isReadyForInternalTestFlight)
        XCTAssertGreaterThan(report.failedRequiredCount, 0)
    }

    func testReportPassesRequiredAutomaticChecksWhenAPIIsRemote() throws {
        let sessionStore = AuthSessionStore(
            tokenStore: InMemoryAuthTokenStore(),
            organizationSelectionStore: InMemoryOrganizationSelectionStore()
        )

        let viewModel = ReleaseReadinessViewModel(
            sessionStore: sessionStore,
            buildInfoProvider: {
                BuildInfo(
                    appName: "Nexo Admin",
                    bundleIdentifier: "com.nexo.admin",
                    version: "1.0.0",
                    build: "1",
                    configuration: .staging,
                    apiBaseURL: "https://staging-api.example.com"
                )
            },
            now: { Date(timeIntervalSince1970: 0) }
        )

        viewModel.load()

        let report = try XCTUnwrap(viewModel.report)
        XCTAssertTrue(report.isReadyForInternalTestFlight)
        XCTAssertEqual(report.failedRequiredCount, 0)
    }
}
