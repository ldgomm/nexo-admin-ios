import XCTest
@testable import Nexo_Admin

@MainActor
final class AdminRoleTemplateProvisioningViewModelTests: XCTestCase {
    func testLoadPublishesTemplates() async {
        let repository = AdminRoleTemplateRepositorySpy()
        let viewModel = AdminRoleTemplateProvisioningViewModel(repository: repository)

        await viewModel.load()

        XCTAssertEqual(viewModel.templates.map(\.templateCode), ["core.cashier", "restaurant.waiter"])
        XCTAssertEqual(viewModel.state, .loaded)
        XCTAssertEqual(repository.lastVertical, nil)
    }

    func testLoadPassesSelectedVertical() async {
        let repository = AdminRoleTemplateRepositorySpy()
        let viewModel = AdminRoleTemplateProvisioningViewModel(repository: repository)
        viewModel.selectedVertical = "RESTAURANT"

        await viewModel.load()

        XCTAssertEqual(repository.lastVertical, "RESTAURANT")
    }

    func testCreateRoleFromTemplateSendsTemplateCodeAndReason() async {
        let repository = AdminRoleTemplateRepositorySpy()
        let viewModel = AdminRoleTemplateProvisioningViewModel(repository: repository)
        let template = AdminRoleTemplate.fixture(
            templateCode: "core.cashier",
            name: "Cajero"
        )
        viewModel.reason = "Alta inicial del rol Cajero"

        await viewModel.createRole(from: template)

        XCTAssertEqual(repository.createdInputs.count, 1)
        XCTAssertEqual(repository.createdInputs.first?.templateCode, "core.cashier")
        XCTAssertEqual(repository.createdInputs.first?.reason, "Alta inicial del rol Cajero")
        XCTAssertEqual(viewModel.infoMessage, "Rol Cajero creado para la organización seleccionada.")
    }

    func testCreateRoleUsesFallbackReasonWhenReasonIsEmpty() async {
        let repository = AdminRoleTemplateRepositorySpy()
        let viewModel = AdminRoleTemplateProvisioningViewModel(repository: repository)
        let template = AdminRoleTemplate.fixture(
            templateCode: "restaurant.waiter",
            name: "Mesero"
        )
        viewModel.reason = ""

        await viewModel.createRole(from: template)

        XCTAssertEqual(repository.createdInputs.first?.reason, "Provisionar rol Mesero desde Admin")
    }
}

private final class AdminRoleTemplateRepositorySpy: AdminRoleTemplateRepository, @unchecked Sendable {
    var templates: [AdminRoleTemplate] = [
        .fixture(templateCode: "core.cashier", name: "Cajero"),
        .fixture(templateCode: "restaurant.waiter", vertical: "RESTAURANT", roleCode: "mesero", name: "Mesero")
    ]
    var lastVertical: String?
    var createdInputs: [AdminCreateRoleFromTemplateInput] = []

    func listBusinessRoleTemplates(vertical: String?) async throws -> [AdminRoleTemplate] {
        lastVertical = vertical
        return templates
    }

    func createBusinessRoleFromTemplate(_ input: AdminCreateRoleFromTemplateInput) async throws {
        createdInputs.append(input)
    }
}

private extension AdminRoleTemplate {
    static func fixture(
        templateCode: String = "core.cashier",
        vertical: String = "CORE",
        roleCode: String = "cajero",
        name: String = "Cajero"
    ) -> AdminRoleTemplate {
        AdminRoleTemplate(
            templateCode: templateCode,
            vertical: vertical,
            roleCode: roleCode,
            name: name,
            description: "Rol de prueba",
            permissionKeys: ["sales.create", "payments.collect"],
            requiredModules: ["core.sales"],
            assignableByBusiness: true,
            editableByBusiness: true,
            critical: false,
            rank: 300
        )
    }
}
