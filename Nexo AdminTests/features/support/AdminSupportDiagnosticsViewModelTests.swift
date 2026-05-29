//
//  AdminSupportDiagnosticsViewModelTests.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import XCTest
@testable import Nexo_Admin

@MainActor
final class AdminSupportDiagnosticsViewModelTests: XCTestCase {
    func testRefreshLoadsHealthAndDevices() async {
        let repository = FakeSupportRepository()
        let viewModel = AdminSupportDiagnosticsViewModel(
            repository: repository,
            permissions: [PermissionCatalog.supportDiagnosticsView],
            buildInfoProvider: { BuildInfo(appName: "Nexo Admin", bundleIdentifier: "com.nexo.admin", version: "1.0.0", build: "1", configuration: .staging, apiBaseURL: "https://staging.nexo.test") }
        )

        await viewModel.refresh()

        guard case .loaded(let snapshot) = viewModel.state else {
            return XCTFail("Expected loaded state")
        }
        XCTAssertEqual(snapshot.health?.status, "healthy")
        XCTAssertEqual(snapshot.devices.count, 1)
        XCTAssertEqual(snapshot.buildInfo.configuration, .staging)
    }

    func testRefreshFailsWithoutPermission() async {
        let viewModel = AdminSupportDiagnosticsViewModel(
            repository: FakeSupportRepository(),
            permissions: [],
            buildInfoProvider: { BuildInfo(appName: "Nexo Admin", bundleIdentifier: "com.nexo.admin", version: "1.0.0", build: "1", configuration: .staging, apiBaseURL: "https://staging.nexo.test") }
        )

        await viewModel.refresh()

        guard case .failed(let message) = viewModel.state else {
            return XCTFail("Expected failed state")
        }
        XCTAssertTrue(message.contains("permisos"))
    }
}

final class FakeSupportRepository: AdminSupportRepository, @unchecked Sendable {
    func getHealth() async throws -> AdminHealthSummary {
        AdminHealthSummary(status: "healthy", environment: "staging", version: "2.4.0", commit: "abc", database: "connected", sri: "test", outbox: "ready", generatedAt: "2026-05-27T00:00:00Z")
    }

    func listDevices() async throws -> [AdminRegisteredDevice] {
        [AdminRegisteredDevice(deviceId: "dev_1", userId: "usr_1", organizationId: "org_1", appType: "admin_ios", appVersion: "1.0.0", platform: "ios", status: "active", lastSeenAt: "2026-05-27T00:00:00Z")]
    }
}
