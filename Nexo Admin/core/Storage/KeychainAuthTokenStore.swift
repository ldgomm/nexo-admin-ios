//
//  KeychainAuthTokenStore.swift
//  Nexo Admin
//
//  Created by José Ruiz on 20/5/26.
//

import Foundation

protocol AuthTokenStorage: Sendable {
    func saveTokens(_ tokens: SessionTokens) throws
    func readTokens() throws -> SessionTokens?
    func clearTokens() throws
}

final class KeychainAuthTokenStore: AuthTokenStorage, @unchecked Sendable {
    private let keychain: SecureKeyValueStore
    private let key = "nexo.auth.tokens"
    private let encoder = JSONEncoder.nexo
    private let decoder = JSONDecoder.nexo

    init(keychain: SecureKeyValueStore) {
        self.keychain = keychain
    }

    func saveTokens(_ tokens: SessionTokens) throws {
        let data = try encoder.encode(tokens)
        try keychain.set(data, for: key)
    }

    func readTokens() throws -> SessionTokens? {
        guard let data = try keychain.get(key) else { return nil }
        return try decoder.decode(SessionTokens.self, from: data)
    }

    func clearTokens() throws {
        try keychain.delete(key)
    }
}

final class InMemoryAuthTokenStore: AuthTokenStorage, @unchecked Sendable {
    private var tokens: SessionTokens?

    init(tokens: SessionTokens? = nil) {
        self.tokens = tokens
    }

    func saveTokens(_ tokens: SessionTokens) throws {
        self.tokens = tokens
    }

    func readTokens() throws -> SessionTokens? {
        tokens
    }

    func clearTokens() throws {
        tokens = nil
    }
}
