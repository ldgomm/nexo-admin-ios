//
//  BuildInfo.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import Foundation

struct BuildInfo: Equatable, Sendable {
    let appName: String
    let bundleIdentifier: String
    let version: String
    let build: String
    let configuration: BuildConfiguration
    let apiBaseURL: String

    var displayVersion: String {
        "v\(version) (\(build))"
    }

    var isLocalAPI: Bool {
        apiBaseURL.contains("localhost") ||
        apiBaseURL.contains("127.0.0.1") ||
        apiBaseURL.contains("0.0.0.0")
    }

    var isTestFlightSafe: Bool {
        !isLocalAPI && !version.isEmpty && !build.isEmpty
    }

    static func current(bundle: Bundle = .main) -> BuildInfo {
        from(infoDictionary: bundle.infoDictionary ?? [:], bundleIdentifier: bundle.bundleIdentifier)
    }

    static func from(infoDictionary: [String: Any], bundleIdentifier: String?) -> BuildInfo {
        let appName = stringValue(infoDictionary["CFBundleDisplayName"])
            ?? stringValue(infoDictionary["CFBundleName"])
            ?? "Nexo Admin"

        let version = stringValue(infoDictionary["CFBundleShortVersionString"]) ?? "0.0.0"
        let build = stringValue(infoDictionary["CFBundleVersion"]) ?? "0"

        let rawConfiguration = stringValue(infoDictionary["NexoBuildConfiguration"]) ?? BuildConfiguration.debug.rawValue
        let configuration = BuildConfiguration(rawValue: rawConfiguration.lowercased()) ?? .debug

        let apiBaseURL = stringValue(infoDictionary["NexoAPIBaseURL"]) ?? AppEnvironment.debug.baseURL.absoluteString

        return BuildInfo(
            appName: appName,
            bundleIdentifier: bundleIdentifier ?? "unknown.bundle",
            version: version,
            build: build,
            configuration: configuration,
            apiBaseURL: apiBaseURL
        )
    }

    private static func stringValue(_ value: Any?) -> String? {
        guard let value = value as? String else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
