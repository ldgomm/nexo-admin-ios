import Foundation

protocol AdminRoleTemplateRepository: Sendable {
    func listBusinessRoleTemplates(vertical: String?) async throws -> [AdminRoleTemplate]
    func createBusinessRoleFromTemplate(_ input: AdminCreateRoleFromTemplateInput) async throws
}
