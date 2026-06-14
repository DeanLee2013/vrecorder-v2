//  APIKeyEntryModel.swift
//  Purpose: Single-owner view-model for the API key-entry sheet (feature #2).
//  Holds draft + derived UI state; validation and masking are static/pure so
//  they're unit-tested without UI. Writes go through the injected APIKeyStoring
//  (atomic — a failed write preserves the previous key). Format-agnostic
//  validation: no provider key-shape assumption (audit-4 #2).

import Foundation

@MainActor
@Observable
final class APIKeyEntryModel {
    var draft: String = "" {
        didSet { if errorMessage != nil { errorMessage = nil } }   // clear error on edit
    }
    private(set) var hasExistingKey: Bool
    private(set) var maskedExisting: String?
    private(set) var errorMessage: String?

    private let store: any APIKeyStoring
    private let provider: String

    init(store: any APIKeyStoring, provider: String = APIProvider.openAI) {
        self.store = store
        self.provider = provider
        let existing = store.key(for: provider)
        hasExistingKey = existing != nil
        maskedExisting = Self.mask(existing)
    }

    var canSave: Bool { Self.isValid(draft) }

    /// Atomic save. Guards on validity so a direct call can't bypass the disabled
    /// button. On success: refresh state, clear draft. On failure: keep state,
    /// set the save-specific error. Returns success.
    @discardableResult
    func save() -> Bool {
        let key = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard Self.isValid(key) else { return false }
        guard store.setKey(key, for: provider) else {
            errorMessage = "保存失败，请重试（已保留原密钥）"
            return false
        }
        hasExistingKey = true
        maskedExisting = Self.mask(key)
        draft = ""
        errorMessage = nil
        return true
    }

    /// Remove the key. On failure: retain configured state + set clear-specific
    /// error (a failed delete must not flip the UI to 未配置).
    @discardableResult
    func clear() -> Bool {
        guard store.setKey(nil, for: provider) else {
            errorMessage = "清除失败，请重试"
            return false
        }
        hasExistingKey = false
        maskedExisting = nil
        errorMessage = nil
        return true
    }

    // MARK: - Pure validation / masking (unit-tested)

    /// Format-agnostic: trimmed, non-empty, printable ASCII only (no control /
    /// internal whitespace / emoji / CJK), length 8…500. No `sk-` / length
    /// provider assumption (OpenAI does not guarantee key shape).
    static func isValid(_ raw: String) -> Bool {
        let key = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard (8...500).contains(key.count) else { return false }
        return key.unicodeScalars.allSatisfy { $0.value >= 0x21 && $0.value <= 0x7E }
    }

    /// Reveal `…` + last 4 only when length ≥ 12; else "已配置" (never the whole
    /// secret); nil when absent.
    static func mask(_ key: String?) -> String? {
        guard let key, !key.isEmpty else { return nil }
        guard key.count >= 12 else { return "已配置" }
        return "…" + String(key.suffix(4))
    }
}
