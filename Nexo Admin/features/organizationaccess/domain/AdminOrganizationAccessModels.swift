import Foundation

struct AdminOrganizationModuleSettings: Identifiable, Equatable, Decodable, Sendable {
    let organizationId: String
    let businessType: String
    let enabledModules: Set<String>
    let disabledModules: Set<String>
    let updatedBy: String?
    let updatedAt: Date?

    var id: String { organizationId }
}

struct AdminCreateOrganizationSuperAdminInput: Encodable, Equatable, Sendable {
    let email: String
    let displayName: String
    let phone: String?
    let temporaryPassword: String?
    let reason: String
}

struct AdminUpdateOrganizationModulesInput: Encodable, Equatable, Sendable {
    let businessType: String
    let enabledModules: Set<String>
    let disabledModules: Set<String>
    let reason: String
}

struct AdminOrganizationSuperAdminResult: Decodable, Equatable, Sendable {
    let userId: String
    let membershipId: String
    let temporaryPassword: String?
    let mustChangePassword: Bool
}
