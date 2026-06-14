//  APIKeyBootstrap.swift
//  Purpose: DEBUG-only convenience — on first launch, if config/openai-key.txt was
//  bundled into the app (dev builds only) and the Keychain has no OpenAI key yet,
//  copy it into the Keychain once. Release builds never read a file; the key is
//  entered through Settings. See AGENTS.md › AI coding tool auth / rules/50 §7.

import Foundation

enum APIKeyBootstrap {
    /// Seed the Keychain from a bundled `openai-key.txt` resource if present and unset.
    static func seedIfNeeded(store: APIKeyStoring) {
        #if DEBUG
        guard store.key(for: APIProvider.openAI) == nil else { return }
        guard let url = Bundle.main.url(forResource: "openai-key", withExtension: "txt"),
              let raw = try? String(contentsOf: url, encoding: .utf8) else { return }
        let key = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty else { return }
        store.setKey(key, for: APIProvider.openAI)
        #endif
    }
}
