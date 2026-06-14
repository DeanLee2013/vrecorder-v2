//  AppleSpeechRecognizer.swift
//  Purpose: On-device SpeechRecognizing via SFSpeechRecognizer + AVAudioEngine.
//  The audio engine runs continuously for the whole session; recognition
//  requests ROTATE on each final so one session interprets many utterances
//  (the recognizer's own endpointing segments them). Recognition errors finish
//  the stream with a mapped PipelineError; `stop` tears down tap, engine,
//  request and task so nothing keeps recognizing. rules/50 §2-3, DIMENSIONS §2-3,6.

import AVFoundation
import Speech

@MainActor
final class AppleSpeechRecognizer: SpeechRecognizing {
    /// Reported from the actual recognizer, not assumed (audit-4 #3).
    nonisolated var capabilities: SpeechCapabilities {
        let onDevice = SFSpeechRecognizer(locale: Locale(identifier: "zh-CN"))?.supportsOnDeviceRecognition ?? false
        return SpeechCapabilities(
            supportsOnDevice: onDevice, latency: onDevice ? .onDevice : .cloud,
            supportedLocales: [Locale(identifier: "zh-CN"), Locale(identifier: "en-US")])
    }

    private let audioEngine = AVAudioEngine()
    private let tapBridge = AudioTapBridge()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private var recognizer: SFSpeechRecognizer?
    private var continuation: AsyncThrowingStream<TranscriptEvent, Error>.Continuation?
    private var running = false

    /// Request speech + mic permission. Throws distinct errors so the UI can give
    /// the right recovery instruction (DIMENSIONS §6).
    func requestAuthorization() async throws {
        let speech = await withCheckedContinuation { c in
            SFSpeechRecognizer.requestAuthorization { c.resume(returning: $0) }
        }
        guard speech == .authorized else { throw PipelineError.speechPermissionDenied }
        let mic = await AVAudioApplication.requestRecordPermission()
        guard mic else { throw PipelineError.micPermissionDenied }
    }

    func start(locale: Locale) throws -> AsyncThrowingStream<TranscriptEvent, Error> {
        // Bounded buffer (bug #4): a stalled consumer can't grow the queue without
        // limit. Partials are replaceable (the consumer coalesces them), so
        // dropping the oldest is harmless; 64 is far above the rare final cadence,
        // so finals are preserved in practice.
        AsyncThrowingStream(TranscriptEvent.self, bufferingPolicy: .bufferingNewest(64)) { continuation in
            do {
                try self.begin(locale: locale, continuation: continuation)
            } catch {
                continuation.finish(throwing: error)
                return
            }
            continuation.onTermination = { [weak self] _ in
                Task { @MainActor in self?.stop() }
            }
        }
    }

    private func begin(locale: Locale,
                       continuation: AsyncThrowingStream<TranscriptEvent, Error>.Continuation) throws {
        guard let recognizer = SFSpeechRecognizer(locale: locale), recognizer.isAvailable else {
            throw PipelineError.recognizerUnavailable
        }
        self.recognizer = recognizer
        self.continuation = continuation
        self.running = true

        let input = audioEngine.inputNode
        let format = input.outputFormat(forBus: 0)
        // The tap appends to the Sendable bridge only — never to main-actor state.
        input.installTap(onBus: 0, bufferSize: 1024, format: format) { [tapBridge] buffer, _ in
            tapBridge.append(buffer)
        }
        audioEngine.prepare()
        try audioEngine.start()
        startSegment()
    }

    /// Begin recognizing the next utterance on the still-running audio engine.
    /// The bridge's VAD calls `endAudio()` on a pause → the recognizer emits a
    /// final → we rotate here to the next segment.
    private func startSegment() {
        guard running, let recognizer, let continuation else { return }
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        // Honor the declared on-device/privacy capability (audit-4 #3).
        if recognizer.supportsOnDeviceRecognition { request.requiresOnDeviceRecognition = true }
        self.request = request
        tapBridge.setRequest(request)
        task = recognizer.recognitionTask(with: request) { [weak self] result, error in
            // Runs off the main actor. Yield DIRECTLY to the (Sendable) continuation
            // — no per-callback main-actor Task — so frequent partials can't pile up
            // unbounded Tasks (bug #4). Yields after finish() are safe no-ops. Only
            // the rare rotate-on-final / error paths hop to the main actor.
            if let result {
                let text = result.bestTranscription.formattedString
                if result.isFinal {
                    if !text.isEmpty { continuation.yield(.final(text)) }
                    Task { @MainActor in self?.rotateAfterFinal() }
                } else {
                    continuation.yield(.partial(text))
                }
            } else if let error {
                Task { @MainActor in self?.finish(throwing: error) }
            }
        }
    }

    /// On the main actor after a final: drop the closed request/task and rotate to
    /// the next segment (keeps interpreting). No-op once stopped.
    private func rotateAfterFinal() {
        guard running else { return }
        task = nil
        request = nil
        startSegment()
    }

    /// Finish the stream with the mapped error EXACTLY once. Tears down audio
    /// without finishing the continuation first (a normal finish would swallow
    /// the error — audit Medium).
    private func finish(throwing error: Error) {
        let mapped: PipelineError = (error as? PipelineError) ?? .recognitionFailed
        teardownAudio()
        let cont = continuation
        continuation = nil
        cont?.finish(throwing: mapped)
    }

    /// Stop audio + recognition without finishing the stream. Idempotent.
    private func teardownAudio() {
        guard running else { return }
        running = false
        audioEngine.inputNode.removeTap(onBus: 0)
        if audioEngine.isRunning { audioEngine.stop() }
        tapBridge.setRequest(nil)
        request?.endAudio()
        task?.cancel()
        task = nil
        request = nil
    }

    func stop() {
        teardownAudio()
        let cont = continuation
        continuation = nil
        cont?.finish()
    }
}
