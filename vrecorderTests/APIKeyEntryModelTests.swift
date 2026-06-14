//  APIKeyEntryModelTests.swift
//  Purpose: Validation, masking, save/clear, and error-state coverage for the
//  key-entry view-model (feature #2). No UI, no real Keychain.

import Foundation
import Testing
@testable import vrecorder

@MainActor
@Suite("APIKeyEntryModel")
struct APIKeyEntryModelTests {
    private func model(_ seed: String? = nil, fail: Bool = false) -> (APIKeyEntryModel, InMemoryAPIKeyStore) {
        let store = InMemoryAPIKeyStore(seed.map { [APIProvider.openAI: $0] } ?? [:])
        store.failNextWrite = fail
        return (APIKeyEntryModel(store: store), store)
    }

    // MARK: validation

    @Test func isValidRejectsEmptyAndTooShort() {
        #expect(!APIKeyEntryModel.isValid(""))
        #expect(!APIKeyEntryModel.isValid("   "))
        #expect(!APIKeyEntryModel.isValid("sk-1234"))          // 7 chars
        #expect(APIKeyEntryModel.isValid("sk-12345"))          // 8 chars
    }

    @Test func isValidRejectsTooLong() {
        #expect(APIKeyEntryModel.isValid(String(repeating: "a", count: 500)))
        #expect(!APIKeyEntryModel.isValid(String(repeating: "a", count: 501)))
    }

    @Test func isValidRejectsInternalWhitespaceControlAndNonASCII() {
        #expect(!APIKeyEntryModel.isValid("sk-12 345678"))     // internal space
        #expect(!APIKeyEntryModel.isValid("sk-1234\n5678"))    // newline
        #expect(!APIKeyEntryModel.isValid("sk-1234😀5678"))    // emoji
        #expect(!APIKeyEntryModel.isValid("密钥key-12345"))    // CJK
    }

    @Test func isValidAcceptsPlainProjAndNonSkKeys() {
        #expect(APIKeyEntryModel.isValid("  sk-abcDEF123456  "))    // trims, ok
        #expect(APIKeyEntryModel.isValid("sk-proj-abcDEF_12-345"))  // project key
        #expect(APIKeyEntryModel.isValid("api_someProviderKey_99"))  // no sk- prefix
    }

    // MARK: masking

    @Test func maskRules() {
        #expect(APIKeyEntryModel.mask(nil) == nil)
        #expect(APIKeyEntryModel.mask("") == nil)
        #expect(APIKeyEntryModel.mask("short") == "已配置")        // < 12, never reveal
        #expect(APIKeyEntryModel.mask("sk-abcdefghAB12") == "…AB12") // last 4
    }

    // MARK: save / clear

    @Test func saveTrimsPersistsAndClearsDraft() {
        let (m, store) = model()
        m.draft = "  sk-abcDEF123456  "
        #expect(m.canSave)
        #expect(m.save())
        #expect(store.key(for: APIProvider.openAI) == "sk-abcDEF123456")
        #expect(m.draft.isEmpty)
        #expect(m.hasExistingKey)
        #expect(m.maskedExisting == "…3456")
        #expect(m.errorMessage == nil)
    }

    @Test func saveGuardsOnValidity() {
        let (m, store) = model()
        m.draft = "short"            // invalid
        #expect(!m.canSave)
        #expect(!m.save())           // direct call is a no-op
        #expect(store.key(for: APIProvider.openAI) == nil)
    }

    @Test func saveFailurePreservesPreviousKeyAndSetsError() {
        let (m, store) = model("sk-oldoldold111", fail: true)
        m.draft = "sk-newnewnew222"
        #expect(!m.save())
        #expect(store.key(for: APIProvider.openAI) == "sk-oldoldold111")  // old preserved
        #expect(m.errorMessage?.contains("保存失败") == true)
    }

    @Test func clearRemovesKeyAndUpdatesState() {
        let (m, store) = model("sk-abcdefghAB12")
        #expect(m.hasExistingKey)
        #expect(m.clear())
        #expect(store.key(for: APIProvider.openAI) == nil)
        #expect(!m.hasExistingKey)
        #expect(m.maskedExisting == nil)
    }

    @Test func clearFailureRetainsConfiguredStateAndSetsError() {
        let (m, _) = model("sk-abcdefghAB12", fail: true)
        #expect(!m.clear())
        #expect(m.hasExistingKey)                       // not flipped to 未配置
        #expect(m.errorMessage?.contains("清除失败") == true)
    }

    @Test func editingDraftClearsError() {
        let (m, _) = model("sk-oldoldold111", fail: true)
        m.draft = "sk-newnewnew222"; _ = m.save()       // sets error
        #expect(m.errorMessage != nil)
        m.draft = "sk-newnewnew333"                      // editing clears it
        #expect(m.errorMessage == nil)
    }

    @Test func initReflectsExistingKey() {
        let (withKey, _) = model("sk-abcdefghAB12")
        #expect(withKey.hasExistingKey)
        #expect(withKey.maskedExisting == "…AB12")
        let (empty, _) = model()
        #expect(!empty.hasExistingKey)
        #expect(empty.maskedExisting == nil)
    }
}
