//  EngineProtocols.swift
//  Purpose: Boundary protocols for swappable STT / translation providers.
//  UI and session code depend on these, never on concrete providers
//  (Apple SFSpeechRecognizer, OpenAI, …). See AGENTS.md › Engine abstraction.

import Foundation

/// Streaming speech-to-text. `start` returns a stream of partial/final events
/// for the active session; `stop` tears the whole chain down (no orphan tasks).
/// MainActor-isolated: on-device recognizers own AVAudioEngine + recognition
/// tasks, which are not safe to drive off the main actor.
@MainActor
protocol SpeechRecognizing {
    nonisolated var capabilities: SpeechCapabilities { get }
    /// Request mic + speech permission; throws distinct PipelineError cases.
    func requestAuthorization() async throws
    func start(locale: Locale) throws -> AsyncThrowingStream<TranscriptEvent, Error>
    func stop()
}

/// Translation engine. MVP translates a finalized segment in one call;
/// streaming partial translation is a later capability behind the same type.
protocol TranslationEngine: Sendable {
    var capabilities: TranslationCapabilities { get }
    func translate(_ text: String, from source: Locale, to target: Locale) async throws -> String
}
