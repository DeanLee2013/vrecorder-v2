//  AppEnvironment.swift
//  Purpose: Composition root. Builds the live-session model with real engines
//  (on-device STT + OpenAI translation, Keychain-backed key) and seeds the key
//  from a bundled config/openai-key.txt on first DEBUG launch. This is the only
//  place concrete providers are chosen; everything downstream sees protocols.

import SwiftUI

@MainActor
final class AppEnvironment {
    let keyStore: APIKeyStoring
    let session: LiveSessionModel

    /// `uiTesting`: when launched with `-uiTesting`, use a seeded in-memory key
    /// store and SKIP the Keychain bootstrap, so XCUITests never touch the real
    /// Keychain and are order-independent (feature #6). A `-seedKey <value>` arg
    /// pre-configures a key; absent = unconfigured.
    init(uiTesting: Bool = false) {
        let store: any APIKeyStoring
        if uiTesting {
            let args = ProcessInfo.processInfo.arguments
            var seed: [String: String] = [:]
            if let i = args.firstIndex(of: "-seedKey"), i + 1 < args.count {
                seed[APIProvider.openAI] = args[i + 1]
            }
            store = InMemoryAPIKeyStore(seed)
        } else {
            let keychain = KeychainAPIKeyStore()
            APIKeyBootstrap.seedIfNeeded(store: keychain)
            store = keychain
        }
        self.keyStore = store

        let translator = OpenAITranslationEngine(keyProvider: { store.key(for: APIProvider.openAI) })
        self.session = LiveSessionModel(
            recognizer: AppleSpeechRecognizer(),
            translator: translator,
            audio: AudioSessionController()
        )
    }
}
