import Foundation

final class RemoteAdminRoleTemplateRepository: AdminRoleTemplateRepository, @unchecked Sendable {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func listBusinessRoleTemplates(vertical: String?) async throws -> [AdminRoleTemplate] {
        var queryItems: [URLQueryItem] = []
        if let vertical, !vertical.isEmpty {
            queryItems.append(URLQueryItem(name: "vertical", value: vertical))
        }
        let response: AdminRoleTemplatesResponse = try await apiClient.send(
            APIEndpoint(
                path: "/api/v1/business/team/role-templates",
                method: .get,
                queryItems: queryItems,
                requiresAuth: true,
                requiresOrganization: true
            )
        )
        return response.templates
    }

    func createBusinessRoleFromTemplate(_ input: AdminCreateRoleFromTemplateInput) async throws {
        let _: AdminRoleTemplateCreatedRoleEnvelope = try await apiClient.send(
            APIEndpoint(
                path: "/api/v1/business/team/roles/from-template",
                method: .post,
                requiresAuth: true,
                requiresOrganization: true
            ),
            body: input
        )
    }
}

private struct AdminRoleTemplateCreatedRoleEnvelope: Decodable, Sendable {
    let id: String?
    let role: AdminRoleTemplateCreatedRole?
}

private struct AdminRoleTemplateCreatedRole: Decodable, Sendable {
    let id: String
}
