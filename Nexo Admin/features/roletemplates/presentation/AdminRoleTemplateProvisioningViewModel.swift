//
//  AdminRoleTemplateProvisioningViewModel.swift
//  Nexo Admin
//
//  Created by José Ruiz on 2/6/26.
//

import Foundation
import Observation

@MainActor
@Observable
final class AdminRoleTemplateProvisioningViewModel {
    enum State: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    private let repository: AdminRoleTemplateRepository

    var state: State = .idle
    var templates: [AdminRoleTemplate] = []
    var selectedVertical: String? = nil
    var reason = "Provisionar rol base desde Admin"
    var infoMessage: String?
    var errorMessage: String?
    var isMutating = false

    init(repository: AdminRoleTemplateRepository) {
        self.repository = repository
    }

    func load() async {
        state = .loading
        errorMessage = nil
        do {
            templates = try await repository.listBusinessRoleTemplates(vertical: selectedVertical)
            state = .loaded
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    func createRole(from template: AdminRoleTemplate) async {
        guard !isMutating else { return }
        isMutating = true
        errorMessage = nil
        infoMessage = nil
        defer { isMutating = false }

        do {
            try await repository.createBusinessRoleFromTemplate(
                AdminCreateRoleFromTemplateInput(
                    templateCode: template.templateCode,
                    code: nil,
                    name: nil,
                    description: nil,
                    reason: reason.isEmpty ? "Provisionar rol \(template.name) desde Admin" : reason
                )
            )
            infoMessage = "Rol \(template.name) creado para la organización seleccionada."
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
