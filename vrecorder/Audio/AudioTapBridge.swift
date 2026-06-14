//  AudioTapBridge.swift
//  Purpose: Thread-safe boundary between the AVAudioEngine render-thread tap and
//  the main-actor recognizer. The tap appends buffers HERE (never to main-actor
//  state — audit-3 #2), and this bridge runs lightweight RMS voice-activity
//  detection: after speech is followed by enough silent frames it calls
//  `endAudio()` on the active request, which makes SFSpeechRecognizer emit a
//  per-utterance final so the session can rotate to the next segment (audit-3 #1).

import AVFoundation
import Speech

/// The sink the tap feeds. SFSpeechAudioBufferRecognitionRequest conforms; tests
/// inject a recording mock so the append→VAD→endAudio→rollover flow is testable.
protocol AudioBufferSink: AnyObject {
    func append(_ buffer: AVAudioPCMBuffer)
    func endAudio()
}

extension SFSpeechAudioBufferRecognitionRequest: AudioBufferSink {}

/// `@unchecked Sendable`: all mutable state is guarded by `lock`, so the render
/// thread and the main actor can both touch it safely.
final class AudioTapBridge: @unchecked Sendable {
    private let lock = NSLock()
    private var request: (any AudioBufferSink)?
    private var hadSpeech = false
    private var silentSeconds: Double = 0

    /// RMS below this counts as silence; tuned for close-mic speech.
    private let silenceRMS: Float = 0.012
    /// Silence DURATION after speech that closes an utterance. Measured in real
    /// seconds (frameLength / sampleRate) so it's independent of buffer size and
    /// sample rate — a fixed callback count would be ~0.2s at 48 kHz (audit-4 #4).
    private let silenceSecondsToClose: Double = 0.7

    /// Audio captured during the gap between endAudio() and the next request is
    /// retained here and replayed into that request, so the next utterance's
    /// start is not dropped (bug #3 / docs bug #1). ~0.5s at a 1024-frame /
    /// 48 kHz tap cadence.
    private let rollover = PCMRollover(cap: 24)

    /// Install/replace the active request (main actor). Replays any audio captured
    /// during the rotation gap THROUGH the VAD path, so a complete short utterance
    /// inside the gap still triggers endAudio() and segments correctly instead of
    /// merging into the next one (audit-G4 #1). Resets VAD state for the segment.
    func setRequest(_ newRequest: (any AudioBufferSink)?) {
        // Replay the rollover ATOMICALLY under the lock, before any live render
        // buffer is accepted, so replay + live audio can't interleave out of
        // chronological order (audit-G4r2 #1). endAudio() calls are deferred to
        // after unlock to avoid re-entrancy.
        lock.lock()
        request = newRequest
        hadSpeech = false
        silentSeconds = 0
        let replay = rollover.drain()        // always clear; only replay if installing
        var deferredEnds: [any AudioBufferSink] = []
        if newRequest != nil {
            for buffered in replay {
                if let toEnd = appendLocked(buffered) { deferredEnds.append(toEnd) }
            }
        }
        lock.unlock()
        for sink in deferredEnds { sink.endAudio() }
    }

    /// Called from the render thread for every captured buffer.
    func append(_ buffer: AVAudioPCMBuffer) {
        lock.lock()
        let toEnd = appendLocked(buffer)
        lock.unlock()
        // endAudio() outside the lock; it triggers the recognizer's final callback,
        // which rotates to a new segment on the main actor.
        toEnd?.endAudio()
    }

    /// Core append + VAD. **Caller must hold `lock`.** Returns the sink to call
    /// `endAudio()` on AFTER unlocking (utterance closed), else nil.
    private func appendLocked(_ buffer: AVAudioPCMBuffer) -> (any AudioBufferSink)? {
        let level = Self.rms(buffer)
        let duration = buffer.format.sampleRate > 0
            ? Double(buffer.frameLength) / buffer.format.sampleRate : 0

        guard let active = request else {
            // In the rotation gap: keep the audio so the next request can replay
            // it instead of truncating the next utterance (bug #3).
            rollover.add(buffer)
            return nil
        }
        active.append(buffer)

        if level > silenceRMS {
            hadSpeech = true
            silentSeconds = 0
        } else if hadSpeech {
            silentSeconds += duration
            if silentSeconds >= silenceSecondsToClose {
                // Atomic handoff: drop the request NOW so later render callbacks
                // never append to an ended request (audit-4 #5).
                request = nil
                hadSpeech = false
                silentSeconds = 0
                return active
            }
        }
        return nil
    }

    static func rms(_ buffer: AVAudioPCMBuffer) -> Float {
        guard let channel = buffer.floatChannelData?[0] else { return 0 }
        let count = Int(buffer.frameLength)
        guard count > 0 else { return 0 }
        var sum: Float = 0
        for i in 0..<count { let s = channel[i]; sum += s * s }
        return (sum / Float(count)).squareRoot()
    }
}
