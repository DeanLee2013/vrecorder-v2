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

    init() {
        let store = KeychainAPIKeyStore()
        APIKeyBootstrap.seedIfNeeded(store: store)
        self.keyStore = store

        let translator = OpenAITranslationEngine(keyProvider: { store.key(for: APIProvider.openAI) })
        self.session = LiveSessionModel(
            recognizer: AppleSpeechRecognizer(),
            translator: translator,
            audio: AudioSessionController()
        )
    }
}
