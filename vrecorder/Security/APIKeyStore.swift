//  APIKeyStore.swift
//  Purpose: Keychain-backed storage for provider API keys. The key is the only
//  secret in the app and must never live in UserDefaults or the bundle.
//  A protocol lets tests substitute an in-memory store; an injectable KeychainOps
//  seam lets tests exercise SecItem status handling (feature #2).

import Foundation
import Security

protocol APIKeyStoring: Sendable {
    func key(for provider: String) -> String?
    /// Returns true on a confirmed write/delete. An update that fails (other than
    /// "not found") leaves the previous key untouched — never destroys it.
    @discardableResult
    func setKey(_ value: String?, for provider: String) -> Bool
}

/// Injectable Security operations so the update→add→preserve logic is testable
/// with scripted `OSStatus` (audit-3 #2: Sendable + @Sendable closures).
struct KeychainOps: Sendable {
    var update: @Sendable (CFDictionary, CFDictionary) -> OSStatus = SecItemUpdate
    var add:    @Sendable (CFDictionary, UnsafeMutablePointer<CFTypeRef?>?) -> OSStatus = SecItemAdd
    var delete: @Sendable (CFDictionary) -> OSStatus = SecItemDelete
    var copy:   @Sendable (CFDictionary, UnsafeMutablePointer<CFTypeRef?>?) -> OSStatus = SecItemCopyMatching
}

/// Real Keychain implementation (generic password, one item per provider).
struct KeychainAPIKeyStore: APIKeyStoring {
    private let service = "com.vrecorder.app.apikeys"
    private let ops: KeychainOps

    init(ops: KeychainOps = KeychainOps()) { self.ops = ops }

    func key(for provider: String) -> String? {
        var query = baseQuery(provider)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var item: CFTypeRef?
        guard ops.copy(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data, let s = String(data: data, encoding: .utf8) else { return nil }
        return s
    }

    @discardableResult
    func setKey(_ value: String?, for provider: String) -> Bool {
        let query = baseQuery(provider)
        guard let value, let data = value.data(using: .utf8) else {
            // Delete path: success or already-absent both count as cleared.
            let status = ops.delete(query as CFDictionary)
            return status == errSecSuccess || status == errSecItemNotFound
        }
        // Atomic: update first (attributes carry ONLY the new data); add only on
        // "not found". Any other update failure leaves the existing key intact.
        let attrs: [String: Any] = [kSecValueData as String: data]
        let updateStatus = ops.update(query as CFDictionary, attrs as CFDictionary)
        if updateStatus == errSecSuccess { return true }
        if updateStatus == errSecItemNotFound {
            var addAttrs = query
            addAttrs[kSecValueData as String] = data
            return ops.add(addAttrs as CFDictionary, nil) == errSecSuccess
        }
        return false
    }

    private func baseQuery(_ provider: String) -> [String: Any] {
        [kSecClass as String: kSecClassGenericPassword,
         kSecAttrService as String: service,
         kSecAttrAccount as String: provider]
    }
}

/// In-memory store for tests and previews. `failNextWrite` injects one failure.
final class InMemoryAPIKeyStore: APIKeyStoring, @unchecked Sendable {
    private var storage: [String: String] = [:]
    private var _failNextWrite = false
    private let lock = NSLock()
    init(_ seed: [String: String] = [:]) { storage = seed }
    /// All access guarded by `lock` (audit-G4 Low: was read/written off-lock).
    var failNextWrite: Bool {
        get { lock.withLock { _failNextWrite } }
        set { lock.withLock { _failNextWrite = newValue } }
    }
    func key(for provider: String) -> String? { lock.withLock { storage[provider] } }
    @discardableResult
    func setKey(_ value: String?, for provider: String) -> Bool {
        lock.withLock {
            if _failNextWrite { _failNextWrite = false; return false }   // preserve existing
            storage[provider] = value
            return true
        }
    }
}

enum APIProvider {
    static let openAI = "openai"
    static let claude = "claude"
}
