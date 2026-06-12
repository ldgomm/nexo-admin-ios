//
//  DeviceInfoProvider.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import Foundation
import UIKit

protocol DeviceIdentityStoring: Sendable {
    var deviceId: String { get }
}

final class UserDefaultsDeviceIdentityStore: DeviceIdentityStoring, @unchecked Sendable {
    private let key = "nexo.admin.device.id"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var deviceId: String {
        if let existing = defaults.string(forKey: key), !existing.isEmpty {
            return existing
        }
        let generated = UIDevice.current.identifierForVendor?.uuidString.lowercased()
            ?? UUID().uuidString.lowercased()
        defaults.set(generated, forKey: key)
        return generated
    }
}

protocol DeviceInfoProviding: Sendable {
    var deviceId: String { get }
    var appType: String { get }
    var appVersion: String { get }
}

struct DefaultDeviceInfoProvider: DeviceInfoProviding {
    let buildInfo: BuildInfo
    let deviceIdentityStore: DeviceIdentityStoring

    var deviceId: String {
        deviceIdentityStore.deviceId
    }

    var appType: String {
        "admin_ios"
    }

    var appVersion: String {
        buildInfo.displayVersion
    }
}
