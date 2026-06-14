//  AppleSpeechRecognizer.swift
//  Purpose: On-device SpeechRecognizing via SFSpeechRecognizer + AVAudioEngine.
//  Emits partial results as text accrues and a final when the recognizer
//  finalizes. `stop` tears down the tap, audio engine and recognition task so
//  no orphan recognition continues. See rules/50 §2-3.

import AVFoundation
import Speech

/// MainActor-bound because it owns AVAudioEngine + SFSpeechRecognitionTask,
/// which are not safe to drive from arbitrary threads.
@MainActor
final class AppleSpeechRecognizer: SpeechRecognizing {
    nonisolated let capabilities = SpeechCapabilities(
        supportsOnDevice: true, latency: .onDevice,
        supportedLocales: [Locale(identifier: "zh-CN"), Locale(identifier: "en-US")])

    private let audioEngine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private var recognizer: SFSpeechRecognizer?
    private var continuation: AsyncThrowingStream<TranscriptEvent, Error>.Continuation?

    /// Request mic + speech permission. Throws PipelineError.permissionDenied.
    static func requestAuthorization() async throws {
        let speech = await withCheckedContinuation { c in
            SFSpeechRecognizer.requestAuthorization { c.resume(returning: $0) }
        }
        guard speech == .authorized else { throw PipelineError.permissionDenied }
        let mic = await AVAudioApplication.requestRecordPermission()
        guard mic else { throw PipelineError.permissionDenied }
    }

    func start(locale: Locale) throws -> AsyncThrowingStream<TranscriptEvent, Error> {
        AsyncThrowingStream { continuation in
            do { try self.begin(locale: locale, continuation: continuation) }
            catch { continuation.finish(throwing: error) }
        }
    }

    private func begin(locale: Locale, continuation: AsyncThrowingStream<TranscriptEvent, Error>.Continuation) throws {
        guard let recognizer = SFSpeechRecognizer(locale: locale), recognizer.isAvailable else {
            throw PipelineError.providerError("recognizer unavailable for \(locale.identifier)")
        }
        self.recognizer = recognizer
        self.continuation = continuation

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        self.request = request

        let input = audioEngine.inputNode
        let format = input.outputFormat(forBus: 0)
        input.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak request] buffer, _ in
            request?.append(buffer)
        }
        audioEngine.prepare()
        try audioEngine.start()

        task = recognizer.recognitionTask(with: request) { [weak self] result, error in
            Task { @MainActor in
                if let result {
                    let text = result.bestTranscription.formattedString
                    continuation.yield(result.isFinal ? .final(text) : .partial(text))
                    if result.isFinal { self?.stop() }
                }
                if error != nil { self?.stop() }
            }
        }

        continuation.onTermination = { [weak self] _ in
            Task { @MainActor in self?.stop() }
        }
    }

    func stop() {
        audioEngine.inputNode.removeTap(onBus: 0)
        if audioEngine.isRunning { audioEngine.stop() }
        request?.endAudio()
        task?.cancel()
        task = nil
        request = nil
        continuation?.finish()
        continuation = nil
    }
}
