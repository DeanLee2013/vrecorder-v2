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
    private var silentFrames = 0

    /// RMS below this counts as silence; tuned for close-mic speech.
    private let silenceRMS: Float = 0.012
    /// Consecutive silent tap callbacks after speech that close an utterance
    /// (~0.6–0.8s at the default tap cadence).
    private let silentFramesToClose = 9

    /// Install/replace the active request (main actor). Resets VAD state so the
    /// new segment starts fresh.
    func setRequest(_ newRequest: SFSpeechAudioBufferRecognitionRequest?) {
        lock.lock()
        request = newRequest
        hadSpeech = false
        silentFrames = 0
        lock.unlock()
    }

    /// Called from the render thread for every captured buffer.
    func append(_ buffer: AVAudioPCMBuffer) {
        lock.lock()
        let active = request
        lock.unlock()
        guard let active else { return }
        active.append(buffer)

        let level = Self.rms(buffer)
        lock.lock()
        var shouldEnd = false
        if level > silenceRMS {
            hadSpeech = true
            silentFrames = 0
        } else if hadSpeech {
            silentFrames += 1
            if silentFrames >= silentFramesToClose {
                hadSpeech = false
                silentFrames = 0
                shouldEnd = true
            }
        }
        lock.unlock()

        // endAudio() outside the lock; it triggers the recognizer's final
        // callback, which rotates to a new segment on the main actor.
        if shouldEnd { active.endAudio() }
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
