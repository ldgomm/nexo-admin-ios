//
//  OrganizationSelectionStore.swift
//  Nexo Admin
//
//  Created by José Ruiz on 20/5/26.
//

import Foundation

protocol OrganizationSelectionStoring: Sendable {
    var selectedOrganizationId: String? { get }
    func selectOrganization(id: String?)
    func clearSelectedOrganization()
}

final class UserDefaultsOrganizationSelectionStore: OrganizationSelectionStoring, @unchecked Sendable {
    private let key = "nexo.selected.organization.id"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var selectedOrganizationId: String? {
        defaults.string(forKey: key)?.nilIfBlank
    }

    func selectOrganization(id: String?) {
        if let id = id?.trimmingCharacters(in: .whitespacesAndNewlines), !id.isEmpty {
            defaults.set(id, forKey: key)
        } else {
            defaults.removeObject(forKey: key)
        }
    }

    func clearSelectedOrganization() {
        defaults.removeObject(forKey: key)
    }
}

final class InMemoryOrganizationSelectionStore: OrganizationSelectionStoring, @unchecked Sendable {
    private var value: String?

    init(selectedOrganizationId: String? = nil) {
        self.value = selectedOrganizationId
    }

    var selectedOrganizationId: String? { value }

    func selectOrganization(id: String?) {
        value = id
    }

    func clearSelectedOrganization() {
        value = nil
    }
}
