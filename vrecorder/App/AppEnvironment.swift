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
        // The UI-test seam exists only in DEBUG — Release ALWAYS uses the real
        // Keychain (audit-WI2 #1: never ship the launch-arg bypass).
        let store: any APIKeyStoring
        #if DEBUG
        if uiTesting {
            let args = ProcessInfo.processInfo.arguments
            var seed: [String: String] = [:]
            if let i = args.firstIndex(of: "-seedKey"), i + 1 < args.count {
                seed[APIProvider.openAI] = args[i + 1]
            }
            store = InMemoryAPIKeyStore(seed)
        } else {
            store = Self.productionStore()
        }
        #else
        store = Self.productionStore()
        #endif
        self.keyStore = store

        let translator = OpenAITranslationEngine(keyProvider: { store.key(for: APIProvider.openAI) })
        self.session = LiveSessionModel(
            recognizer: AppleSpeechRecognizer(),
            translator: translator,
            audio: AudioSessionController()
        )

        #if DEBUG
        // Launch-time fixture for UI tests that need a deterministic ACTIVE session
        // at startup (e.g. the background-stop lifecycle test) without a mic or the
        // URL scheme. DEBUG + uiTesting only.
        if uiTesting, ProcessInfo.processInfo.arguments.contains("-fixtureListening") {
            session.installFixture(
                a: [TranscriptLine(status: .final, text: "测试")],
                b: [TranscriptLine(status: .final, text: "test")],
                listening: true)
        }
        #endif
    }

    /// The real Keychain-backed store (DEBUG-seeded once). The only store Release
    /// ever uses.
    private static func productionStore() -> any APIKeyStoring {
        let keychain = KeychainAPIKeyStore()
        APIKeyBootstrap.seedIfNeeded(store: keychain)
        return keychain
    }
}
