import Foundation

struct AdminRoleTemplate: Identifiable, Equatable, Decodable, Sendable {
    let templateCode: String
    let vertical: String
    let roleCode: String
    let name: String
    let description: String
    let permissionKeys: Set<String>
    let requiredModules: Set<String>
    let assignableByBusiness: Bool
    let editableByBusiness: Bool
    let critical: Bool
    let rank: Int

    var id: String { templateCode }
}

struct AdminRoleTemplatesResponse: Decodable, Equatable, Sendable {
    let templates: [AdminRoleTemplate]
}

struct AdminCreateRoleFromTemplateInput: Encodable, Equatable, Sendable {
    let templateCode: String
    let code: String?
    let name: String?
    let description: String?
    let reason: String
}
