//
//  AdminRoleTemplateRepository.swift
//  Nexo Admin
//
//  Created by José Ruiz on 2/6/26.
//

import Foundation

protocol AdminRoleTemplateRepository: Sendable {
    func listBusinessRoleTemplates(vertical: String?) async throws -> [AdminRoleTemplate]
    func createBusinessRoleFromTemplate(_ input: AdminCreateRoleFromTemplateInput) async throws
}
