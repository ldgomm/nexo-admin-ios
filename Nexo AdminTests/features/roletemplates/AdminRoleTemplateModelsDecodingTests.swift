//
//  AdminRoleTemplateModelsDecodingTests.swift
//  Nexo Admin
//
//  Created by José Ruiz on 2/6/26.
//

import XCTest
@testable import Nexo_Admin

final class AdminRoleTemplateModelsDecodingTests: XCTestCase {
    func testDecodesRoleTemplatesResponse() throws {
        let json = Data(
            """
            {
              "templates": [
                {
                  "templateCode": "core.cashier",
                  "vertical": "CORE",
                  "roleCode": "cajero",
                  "name": "Cajero",
                  "description": "Puede vender y cobrar.",
                  "permissionKeys": ["sales.create", "payments.collect"],
                  "requiredModules": ["core.sales", "core.cash"],
                  "assignableByBusiness": true,
                  "editableByBusiness": true,
                  "critical": false,
                  "rank": 300
                }
              ]
            }
            """.utf8
        )

        let response = try JSONDecoder().decode(AdminRoleTemplatesResponse.self, from: json)

        XCTAssertEqual(response.templates.count, 1)
        XCTAssertEqual(response.templates.first?.id, "core.cashier")
        XCTAssertEqual(response.templates.first?.permissionKeys, ["sales.create", "payments.collect"])
        XCTAssertEqual(response.templates.first?.requiredModules, ["core.sales", "core.cash"])
    }

    func testEncodesCreateRoleFromTemplateInput() throws {
        let input = AdminCreateRoleFromTemplateInput(
            templateCode: "core.cashier",
            code: nil,
            name: nil,
            description: nil,
            reason: "Provisionar cajero"
        )

        let data = try JSONEncoder().encode(input)
        let object = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        XCTAssertEqual(object?["templateCode"] as? String, "core.cashier")
        XCTAssertEqual(object?["reason"] as? String, "Provisionar cajero")
        XCTAssertFalse(object?.keys.contains("code") ?? true)
    }
}
