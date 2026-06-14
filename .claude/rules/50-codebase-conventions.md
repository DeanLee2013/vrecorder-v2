# 50 - Codebase Conventions

Project conventions for vrecorder (iOS simultaneous-interpretation app). Follow these for consistency.

## 1. Actor Isolation

- Swift 6 strict concurrency (`SWIFT_STRICT_CONCURRENCY=complete`).
- ViewModels and observable stores are `@MainActor @Observable final class`.
- Pipeline stages (capture, VAD, ASR, translation, TTS) are actors or actor-isolated services. Cross-actor calls use `await`. No `assumeIsolated` except in narrow `App.init` contexts.
- Never pass `@Model` instances across actor boundaries — use value-type DTOs (`SessionRecord`, `TranscriptSegmentRecord`, etc.).

## 2. Streaming Pipeline Semantics

- Stages communicate via explicit streaming protocols emitting `partial` / `final` events.
- **Partials are replaceable, not append-only**: a later partial replaces the previous partial for the same segment; a `final` freezes it. Consumers must implement replacement.
- Every stage supports cancellation; cancelling a session must tear down the whole chain (no orphaned recognition tasks or network streams).
- Backpressure: stages must not buffer unboundedly; drop or coalesce partials when the consumer is slow.

## 3. Engine Abstraction

- ASR, translation, and TTS providers sit behind protocols (e.g. `SpeechRecognizing`, `TranslationEngine`, `SpeechSynthesizing`).
- Concrete providers (on-device SFSpeechRecognizer / Apple Translation vs cloud streaming APIs) are selected via a capabilities object (offline support, language pairs, latency class) — never hard-coded at call sites.
- UI code never calls a concrete provider directly.

## 4. Audio Session

- All `AVAudioSession` configuration, interruption handling, and route-change handling is centralized in one audio session controller.
- Interruptions (phone call, Siri, alarm) and route changes (AirPods connect/disconnect) must pause/resume the pipeline gracefully and are test-covered via simulated notifications.

## 5. Persistence

- All SwiftData mutations go through a single persistence actor.
- Sessions, transcripts, and translations persist as value-type DTO round-trips.

## 6. Logging & Errors

- No bare `print()` in production — `Logger(subsystem: "com.vrecorder.app", category: "...")`.
- Error types are domain-specific; user-presentable errors must distinguish: offline, timeout, rate-limited, permission-denied, provider-error. Never mislabel a timeout as "offline".

## 7. DEBUG Gating

- DEBUG-only code (fixtures, debug bridges, test seams) wrapped in `#if DEBUG` at file scope, never inline in production code paths.

## 8. File Size & Structure

- Code files stay under ~300 lines; split proactively.
- Features stay local; avoid cross-feature imports unless truly shared.

## 9. Testing

- Swift Testing is the default (`import Testing`, `@Test`, `#expect`); XCTest only for `XCTestExpectation` / notification-timing tests.
- Audio tests use recorded fixture clips (speech / silence / noise / CJK) and recorded transcript-event sequences — never live mic input.
