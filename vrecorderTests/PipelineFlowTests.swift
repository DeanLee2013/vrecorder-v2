//  PipelineFlowTests.swift
//  Purpose: Deterministic end-to-end pipeline coverage using injected mock
//  engines (enabled by the `any SpeechRecognizing` / `any TranslationEngine`
//  abstraction). Verifies finals are translated and committed in source order.

import Foundation
import Testing
@testable import vrecorder

@MainActor
private final class MockRecognizer: SpeechRecognizing {
    nonisolated let capabilities = SpeechCapabilities(
        supportsOnDevice: true, latency: .onDevice, supportedLocales: [])
    private let events: [TranscriptEvent]
    init(_ events: [TranscriptEvent]) { self.events = events }
    func requestAuthorization() async throws {}
    func stop() {}
    func start(locale: Locale) throws -> AsyncThrowingStream<TranscriptEvent, Error> {
        AsyncThrowingStream { cont in
            Task { @MainActor in
                for e in events { cont.yield(e); await Task.yield() }
                // Stay open like the real continuous recognizer; the model stops it.
            }
        }
    }
}

private struct MockTranslator: TranslationEngine {
    let capabilities = TranslationCapabilities(isOffline: false, latency: .cloud, providerName: "mock")
    func translate(_ text: String, from: Locale, to: Locale) async throws -> String { "EN(\(text))" }
}

@MainActor
@Suite("Pipeline flow")
struct PipelineFlowTests {
    private func waitUntil(_ cond: @MainActor () -> Bool) async {
        for _ in 0..<2000 {
            if cond() { return }
            try? await Task.sleep(nanoseconds: 1_000_000)
        }
    }

    @Test func finalsAreTranslatedAndCommittedInOrder() async {
        let rec = MockRecognizer([.partial("你"), .final("你好"), .final("再见")])
        let model = LiveSessionModel(recognizer: rec, translator: MockTranslator())
        model.toggle()
        await waitUntil { model.partyB.contains { $0.text == "EN(再见)" } }
        #expect(model.partyB.contains { $0.text == "EN(你好)" })   // earlier final present (now history)
        #expect(model.partyB.last?.text == "EN(再见)")             // latest final committed last
        model.stop()
        #expect(!model.listening)
    }

    @Test func stopHaltsTheSession() async {
        let rec = MockRecognizer([.partial("测试")])
        let model = LiveSessionModel(recognizer: rec, translator: MockTranslator())
        model.toggle()
        #expect(model.listening)
        model.stop()
        #expect(!model.listening)
    }
}
