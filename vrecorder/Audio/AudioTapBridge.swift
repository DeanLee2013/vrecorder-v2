//  AudioTapBridge.swift
//  Purpose: Thread-safe boundary between the AVAudioEngine render-thread tap and
//  the main-actor recognizer. The tap appends buffers HERE (never to main-actor
//  state — audit-3 #2), and this bridge runs lightweight RMS voice-activity
//  detection: after speech is followed by enough silent frames it calls
//  `endAudio()` on the active request, which makes SFSpeechRecognizer emit a
//  per-utterance final so the session can rotate to the next segment (audit-3 #1).

import AVFoundation
import Speech

/// `@unchecked Sendable`: all mutable state is guarded by `lock`, so the render
/// thread and the main actor can both touch it safely.
final class AudioTapBridge: @unchecked Sendable {
    private let lock = NSLock()
    private var request: SFSpeechAudioBufferRecognitionRequest?
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
    /// during the rotation gap, then resets VAD state for the new segment.
    func setRequest(_ newRequest: SFSpeechAudioBufferRecognitionRequest?) {
        lock.lock()
        request = newRequest
        if let newRequest {
            for buffered in rollover.drain() { newRequest.append(buffered) }
        } else {
            _ = rollover.drain()   // dropping the request also clears the ring
        }
        hadSpeech = false
        silentSeconds = 0
        lock.unlock()
    }

    /// Called from the render thread for every captured buffer.
    func append(_ buffer: AVAudioPCMBuffer) {
        let level = Self.rms(buffer)
        let duration = buffer.format.sampleRate > 0
            ? Double(buffer.frameLength) / buffer.format.sampleRate : 0

        lock.lock()
        guard let active = request else {
            // In the rotation gap: keep the audio so the next request can replay
            // it instead of truncating the next utterance (bug #3).
            rollover.add(buffer)
            lock.unlock()
            return
        }
        active.append(buffer)

        var closing = false
        if level > silenceRMS {
            hadSpeech = true
            silentSeconds = 0
        } else if hadSpeech {
            silentSeconds += duration
            if silentSeconds >= silenceSecondsToClose {
                closing = true
                // Atomic handoff: drop the request NOW so later render callbacks
                // never append to an ended request (audit-4 #5). The next start()
                // installs a fresh one.
                request = nil
                hadSpeech = false
                silentSeconds = 0
            }
        }
        lock.unlock()

        // endAudio() outside the lock; it triggers the recognizer's final
        // callback, which rotates to a new segment on the main actor.
        if closing { active.endAudio() }
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
