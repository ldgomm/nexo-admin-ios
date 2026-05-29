//
//  AdminPermissionsViewModel.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import Combine
import Foundation

@MainActor
final class AdminPermissionsViewModel: ObservableObject {
    @Published private(set) var state: LoadableViewState<[AdminAccessPermission]> = .idle
    @Published var includeReserved = false
    @Published var searchText = ""
    @Published var selectedCategory = "Todas"

    private let listPermissions: ListAdminPermissionsUseCase

    init(repository: any AdminAccessRepository) {
        self.listPermissions = ListAdminPermissionsUseCase(repository: repository)
    }

    var permissions: [AdminAccessPermission] {
        guard case .loaded(let permissions) = state else { return [] }
        return permissions
    }

    var categories: [String] {
        ["Todas"] + Set(permissions.map(\.categoryLabel)).sorted()
    }

    var filteredPermissions: [AdminAccessPermission] {
        permissions.filter { permission in
            let categoryMatches = selectedCategory == "Todas" || permission.categoryLabel == selectedCategory
            let search = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let searchMatches = search.isEmpty ||
                permission.code.lowercased().contains(search) ||
                permission.name.lowercased().contains(search) ||
                permission.description.lowercased().contains(search)
            return categoryMatches && searchMatches
        }.sorted { lhs, rhs in
            if lhs.category == rhs.category {
                return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            }
            return lhs.category.localizedCaseInsensitiveCompare(rhs.category) == .orderedAscending
        }
    }

    func load() async {
        if case .loaded = state { return }
        await refresh()
    }

    func refresh() async {
        state = .loading
        do {
            let loaded = try await listPermissions.execute(includeReserved: includeReserved)
            state = loaded.isEmpty ? .empty("No hay permisos publicados por el backend.") : .loaded(loaded)
        } catch {
            state = .failed(error.userFriendlyMessage)
        }
    }
}
