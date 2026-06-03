import Foundation

protocol AdminOrganizationAccessRepository: Sendable {
    func getModuleSettings(organizationId: String) async throws -> AdminOrganizationModuleSettings
    func updateModuleSettings(organizationId: String, input: AdminUpdateOrganizationModulesInput) async throws -> AdminOrganizationModuleSettings
    func createSuperAdmin(organizationId: String, input: AdminCreateOrganizationSuperAdminInput) async throws -> AdminOrganizationSuperAdminResult
}

struct RemoteAdminOrganizationAccessRepository: AdminOrganizationAccessRepository {
    let apiClient: APIClient

    func getModuleSettings(organizationId: String) async throws -> AdminOrganizationModuleSettings {
        try await apiClient.send(APIEndpoint(path: "/api/v1/admin/organizations/\(organizationId)/modules", method: .get, requiresOrganization: false))
    }

    func updateModuleSettings(organizationId: String, input: AdminUpdateOrganizationModulesInput) async throws -> AdminOrganizationModuleSettings {
        try await apiClient.send(APIEndpoint(path: "/api/v1/admin/organizations/\(organizationId)/modules", method: .patch, requiresOrganization: false), body: input)
    }

    func createSuperAdmin(organizationId: String, input: AdminCreateOrganizationSuperAdminInput) async throws -> AdminOrganizationSuperAdminResult {
        try await apiClient.send(APIEndpoint(path: "/api/v1/admin/organizations/\(organizationId)/super-admin", method: .post, requiresOrganization: false), body: input)
    }
}
