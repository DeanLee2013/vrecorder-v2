//  AudioTapBridgeTests.swift
//  Purpose: VAD + rollover integration via a mock AudioBufferSink (bug #1/#3).
//  Verifies that audio captured during the rotation gap is replayed through the
//  VAD path, so a complete utterance inside the gap still triggers endAudio().

import AVFoundation
import Testing
@testable import vrecorder

private final class MockSink: AudioBufferSink, @unchecked Sendable {
    private let lock = NSLock()
    private(set) var endedCount = 0
    private(set) var tags: [Float] = []          // first sample of each appended buffer, in order
    var appended: Int { lock.withLock { tags.count } }
    func append(_ buffer: AVAudioPCMBuffer) {
        let tag = buffer.floatChannelData?[0][0] ?? .nan
        lock.withLock { tags.append(tag) }
    }
    func endAudio() { lock.withLock { endedCount += 1 } }
}

@Suite("AudioTapBridge VAD + rollover")
struct AudioTapBridgeTests {
    private let fmt = AVAudioFormat(standardFormatWithSampleRate: 48000, channels: 1)!

    /// One ~21ms buffer (1024 frames @ 48 kHz) at the given RMS level.
    private func buffer(level: Float) -> AVAudioPCMBuffer {
        let buf = AVAudioPCMBuffer(pcmFormat: fmt, frameCapacity: 1024)!
        buf.frameLength = 1024
        let ch = buf.floatChannelData![0]
        for i in 0..<1024 { ch[i] = level }   // constant signal → RMS == level
        return buf
    }

    @Test func liveSpeechThenSilenceTriggersEndAudio() {
        let bridge = AudioTapBridge()
        let sink = MockSink()
        bridge.setRequest(sink)
        // ~0.4s speech then ~0.8s silence (> 0.7s close threshold).
        for _ in 0..<20 { bridge.append(buffer(level: 0.2)) }
        for _ in 0..<40 { bridge.append(buffer(level: 0.0)) }
        #expect(sink.appended > 0)
        #expect(sink.endedCount >= 1)        // utterance closed
    }

    @Test func rolloverReplaysThroughVADSoNextUtteranceSegments() {
        let bridge = AudioTapBridge()
        // Rotation gap (request == nil): tail silence + the START of the next
        // utterance are captured in the bounded ring.
        for _ in 0..<3 { bridge.append(buffer(level: 0.0)) }    // tail silence
        for _ in 0..<8 { bridge.append(buffer(level: 0.2)) }    // next utterance start
        let sink = MockSink()
        bridge.setRequest(sink)                                 // replay THROUGH VAD
        #expect(sink.appended > 0)           // next-utterance start was NOT dropped
        // The replayed speech set hadSpeech, so subsequent LIVE silence closes the
        // utterance (it isn't merged into the following one — the audit's concern).
        for _ in 0..<40 { bridge.append(buffer(level: 0.0)) }
        #expect(sink.endedCount >= 1)
    }

    @Test func replayThenLivePreservesChronologicalOrder() {
        let bridge = AudioTapBridge()
        // Rotation gap: two distinct buffers captured (tags 0.10, 0.11).
        bridge.append(buffer(level: 0.10))
        bridge.append(buffer(level: 0.11))
        let sink = MockSink()
        bridge.setRequest(sink)                 // atomic replay under the lock...
        bridge.append(buffer(level: 0.12))      // ...then a live buffer
        // Order must be replay-then-live, never interleaved (audit-G4r2 #1).
        #expect(sink.tags == [0.10, 0.11, 0.12])
    }

    @Test func setRequestNilClearsRolloverNoReplay() {
        let bridge = AudioTapBridge()
        for _ in 0..<5 { bridge.append(buffer(level: 0.2)) }    // into rollover
        bridge.setRequest(nil)                                  // teardown clears ring
        let sink = MockSink()
        bridge.setRequest(sink)
        #expect(sink.appended == 0)          // nothing replayed after a clear
    }
}
