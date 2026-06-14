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
    private var coalescer: RecognitionEventCoalescer?
    private var pumpTask: Task<Void, Never>?
    private var running = false
    /// Bumped on every begin/stop. A recognition callback captures the generation
    /// at task-creation; main-actor hops validate it so a stale callback (after a
    /// restart) can't rotate or terminate the new session (bug #5 / GH #9).
    private var generation = 0

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
        AsyncThrowingStream { continuation in
            self.continuation = continuation
            continuation.onTermination = { [weak self] _ in
                Task { @MainActor in self?.stop() }
            }
            do {
                try self.begin(locale: locale)
            } catch {
                // Roll back any partial startup (tap/engine) before failing so a
                // failed begin() leaves no live audio (audit bug#2 Medium).
                self.teardownAudio()
                let cont = self.continuation
                self.continuation = nil
                cont?.finish(throwing: error)
            }
        }
    }

    private func begin(locale: Locale) throws {
        guard let recognizer = SFSpeechRecognizer(locale: locale), recognizer.isAvailable else {
            throw PipelineError.recognizerUnavailable
        }
        self.recognizer = recognizer
        self.running = true
        generation += 1          // new session — invalidate any stale callbacks

        // One pump task drains the coalescer into the output stream: partials
        // coalesce to the latest, finals are never dropped (bug #2 High). The
        // continuation is Sendable; capture it so the pump never touches self.
        let coalescer = RecognitionEventCoalescer()
        self.coalescer = coalescer
        let output = continuation
        pumpTask = Task {
            for await _ in coalescer.wakeups {
                for event in coalescer.drain() { output?.yield(event) }
            }
        }

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
        guard running, let recognizer, let coalescer else { return }
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        // Honor the declared on-device/privacy capability (audit-4 #3).
        if recognizer.supportsOnDeviceRecognition { request.requiresOnDeviceRecognition = true }
        self.request = request
        tapBridge.setRequest(request)
        let gen = generation     // capture this session's identity (bug #5)
        task = recognizer.recognitionTask(with: request) { [weak self] result, error in
            // Runs off the main actor. PUSH to the (Sendable) coalescer captured
            // for THIS session — no per-callback main-actor Task, partials coalesce,
            // finals never drop (bug #2). The rare rotate/error hops validate `gen`
            // so a stale callback can't touch a restarted session (bug #5).
            if let result {
                let text = result.bestTranscription.formattedString
                if result.isFinal {
                    if !text.isEmpty { coalescer.push(.final(text)) }
                    Task { @MainActor in self?.rotateAfterFinal(gen: gen) }
                } else {
                    coalescer.push(.partial(text))
                }
            } else if let error {
                Task { @MainActor in self?.finish(gen: gen, throwing: error) }
            }
        }
    }

    /// On the main actor after a final: drop the closed request/task and rotate to
    /// the next segment (keeps interpreting). No-op once stopped.
    private func rotateAfterFinal(gen: Int) {
        guard running, gen == generation else { return }   // ignore stale callbacks
        task = nil
        request = nil
        startSegment()
    }

    /// Finish the stream with the mapped error EXACTLY once. Tears down audio
    /// without finishing the continuation first (a normal finish would swallow
    /// the error — audit Medium). Ignores stale-session callbacks (bug #5).
    private func finish(gen: Int, throwing error: Error) {
        guard gen == generation else { return }
        let mapped = (error as? PipelineError)
            ?? Self.mapRecognitionError(error,
                                        authorized: SFSpeechRecognizer.authorizationStatus() == .authorized)
        teardownAudio()
        let cont = continuation
        continuation = nil
        cont?.finish(throwing: mapped)
    }

    /// Classify a Speech-framework error (bug #9): revoked permission and network
    /// failures (when on-device recognition falls back to cloud) get specific
    /// taxonomy instead of the generic `recognitionFailed`. Pure + nonisolated so
    /// it's unit-testable with synthetic `NSError`s.
    nonisolated static func mapRecognitionError(_ error: Error, authorized: Bool) -> PipelineError {
        if !authorized { return .speechPermissionDenied }
        let ns = error as NSError
        if ns.domain == NSURLErrorDomain {
            return ns.code == NSURLErrorTimedOut ? .timeout : .offline
        }
        return .recognitionFailed
    }

    /// Stop audio + recognition without finishing the stream. Idempotent.
    private func teardownAudio() {
        // Always tear down the pump/coalescer (even if begin() failed before
        // running flipped) so no drain task leaks.
        pumpTask?.cancel(); pumpTask = nil
        coalescer?.finish(); coalescer = nil
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
        generation += 1          // invalidate any in-flight callbacks (bug #5)
        teardownAudio()
        let cont = continuation
        continuation = nil
        cont?.finish()
    }
}
