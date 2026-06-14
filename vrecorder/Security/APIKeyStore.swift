//  APIKeyStore.swift
//  Purpose: Keychain-backed storage for provider API keys. The key is the only
//  secret in the app and must never live in UserDefaults or the bundle.
//  A protocol lets tests substitute an in-memory store.

import Foundation
import Security

protocol APIKeyStoring: Sendable {
    func key(for provider: String) -> String?
    func setKey(_ value: String?, for provider: String)
}

/// Real Keychain implementation (generic password, one item per provider).
struct KeychainAPIKeyStore: APIKeyStoring {
    private let service = "com.vrecorder.app.apikeys"

    func key(for provider: String) -> String? {
        var query = baseQuery(provider)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data, let s = String(data: data, encoding: .utf8) else { return nil }
        return s
    }

    func setKey(_ value: String?, for provider: String) {
        SecItemDelete(baseQuery(provider) as CFDictionary)
        guard let value, let data = value.data(using: .utf8) else { return }
        var attrs = baseQuery(provider)
        attrs[kSecValueData as String] = data
        SecItemAdd(attrs as CFDictionary, nil)
    }

    private func baseQuery(_ provider: String) -> [String: Any] {
        [kSecClass as String: kSecClassGenericPassword,
         kSecAttrService as String: service,
         kSecAttrAccount as String: provider]
    }
}

/// In-memory store for tests and previews.
final class InMemoryAPIKeyStore: APIKeyStoring, @unchecked Sendable {
    private var storage: [String: String] = [:]
    private let lock = NSLock()
    init(_ seed: [String: String] = [:]) { storage = seed }
    func key(for provider: String) -> String? { lock.withLock { storage[provider] } }
    func setKey(_ value: String?, for provider: String) {
        lock.withLock { storage[provider] = value }
    }
}

enum APIProvider {
    static let openAI = "openai"
    static let claude = "claude"
}
