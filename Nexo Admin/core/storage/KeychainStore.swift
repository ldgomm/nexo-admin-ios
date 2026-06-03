//
//  KeychainStore.swift
//  Nexo Admin
//
//  Created by José Ruiz on 20/5/26.
//

import Foundation
import Security

protocol SecureKeyValueStore: Sendable {
    func set(_ data: Data, for key: String) throws
    func get(_ key: String) throws -> Data?
    func delete(_ key: String) throws
}

final class KeychainStore: SecureKeyValueStore, @unchecked Sendable {
    private let service: String

    init(service: String) {
        self.service = service
    }

    func set(_ data: Data, for key: String) throws {
        try delete(key)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw AppError.keychain("No se pudo guardar \(key). Código: \(status).")
        }
    }

    func get(_ key: String) throws -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess else {
            throw AppError.keychain("No se pudo leer \(key). Código: \(status).")
        }
        return item as? Data
    }

    func delete(_ key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw AppError.keychain("No se pudo eliminar \(key). Código: \(status).")
        }
    }
}
