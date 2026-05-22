import XCTest
@testable import Nexo_Admin

final class BuildInfoTests: XCTestCase {
    func testBuildInfoReadsInfoDictionary() {
        let info: [String: Any] = [
            "CFBundleDisplayName": "Nexo Admin",
            "CFBundleShortVersionString": "1.2.3",
            "CFBundleVersion": "45",
            "NexoBuildConfiguration": "staging",
            "NexoAPIBaseURL": "https://staging-api.example.com"
        ]

        let buildInfo = BuildInfo.from(infoDictionary: info, bundleIdentifier: "com.nexo.admin")

        XCTAssertEqual(buildInfo.appName, "Nexo Admin")
        XCTAssertEqual(buildInfo.bundleIdentifier, "com.nexo.admin")
        XCTAssertEqual(buildInfo.version, "1.2.3")
        XCTAssertEqual(buildInfo.build, "45")
        XCTAssertEqual(buildInfo.configuration, .staging)
        XCTAssertEqual(buildInfo.apiBaseURL, "https://staging-api.example.com")
        XCTAssertFalse(buildInfo.isLocalAPI)
        XCTAssertTrue(buildInfo.isTestFlightSafe)
    }

    func testBuildInfoDetectsLocalAPI() {
        let info: [String: Any] = [
            "CFBundleShortVersionString": "1.0.0",
            "CFBundleVersion": "1",
            "NexoAPIBaseURL": "http://localhost:8080"
        ]

        let buildInfo = BuildInfo.from(infoDictionary: info, bundleIdentifier: "com.nexo.admin")

        XCTAssertTrue(buildInfo.isLocalAPI)
        XCTAssertFalse(buildInfo.isTestFlightSafe)
    }
}
