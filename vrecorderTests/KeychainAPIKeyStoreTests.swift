//  KeychainAPIKeyStoreTests.swift
//  Purpose: Exercise the atomic update→add→preserve logic with scripted OSStatus
//  via the injected KeychainOps seam (feature #2, audit-2 #3). The real Keychain
//  round-trip runs in Gate-5 simulator verification, not here.

import Foundation
import Security
import Testing
@testable import vrecorder

@Suite("KeychainAPIKeyStore (scripted OSStatus)")
struct KeychainAPIKeyStoreTests {

    // Records which ops fired so we can assert "add not called", etc.
    final class Calls: @unchecked Sendable {
        let lock = NSLock()
        var updated = false, added = false, deleted = false
        func mark(_ kp: ReferenceWritableKeyPath<Calls, Bool>) { lock.withLock { self[keyPath: kp] = true } }
    }

    private func store(update: OSStatus, add: OSStatus = errSecSuccess,
                       delete: OSStatus = errSecSuccess, calls: Calls) -> KeychainAPIKeyStore {
        let ops = KeychainOps(
            update: { _, _ in calls.mark(\.updated); return update },
            add:    { _, _ in calls.mark(\.added);   return add },
            delete: { _ in   calls.mark(\.deleted);  return delete },
            copy:   { _, _ in errSecSuccess })
        return KeychainAPIKeyStore(ops: ops)
    }

    @Test func updateSuccessReturnsTrueWithoutAdd() {
        let calls = Calls()
        let s = store(update: errSecSuccess, calls: calls)
        #expect(s.setKey("sk-newkey12345", for: APIProvider.openAI))
        #expect(calls.updated)
        #expect(!calls.added)            // update sufficed; no add
    }

    @Test func updateNotFoundFallsBackToAdd() {
        let calls = Calls()
        let s = store(update: errSecItemNotFound, add: errSecSuccess, calls: calls)
        #expect(s.setKey("sk-newkey12345", for: APIProvider.openAI))
        #expect(calls.updated)
        #expect(calls.added)
    }

    @Test func addFailureReturnsFalse() {
        let calls = Calls()
        let s = store(update: errSecItemNotFound, add: errSecDuplicateItem, calls: calls)
        #expect(!s.setKey("sk-newkey12345", for: APIProvider.openAI))
    }

    @Test func updateFailureOtherThanNotFoundPreservesOldKeyNoAdd() {
        let calls = Calls()
        // e.g. errSecAuthFailed on update — must NOT delete or add (old key intact).
        let s = store(update: errSecAuthFailed, calls: calls)
        #expect(!s.setKey("sk-newkey12345", for: APIProvider.openAI))
        #expect(calls.updated)
        #expect(!calls.added)
        #expect(!calls.deleted)
    }

    @Test func clearSuccessAndNotFoundBothCountAsCleared() {
        let calls = Calls()
        #expect(store(update: errSecSuccess, delete: errSecSuccess, calls: calls)
            .setKey(nil, for: APIProvider.openAI))
        #expect(store(update: errSecSuccess, delete: errSecItemNotFound, calls: Calls())
            .setKey(nil, for: APIProvider.openAI))
    }

    @Test func clearFailureReturnsFalse() {
        let s = store(update: errSecSuccess, delete: errSecAuthFailed, calls: Calls())
        #expect(!s.setKey(nil, for: APIProvider.openAI))
    }
}
